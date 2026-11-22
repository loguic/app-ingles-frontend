import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

/// Defines the audio operations required by pronunciation controls.
/// Define las operaciones de audio requeridas por los controles.
abstract interface class PronunciationAudioController {
  String? get activePlaybackId;

  String? get activeRecordingId;

  Stream<String?> get onPlaybackChanged;

  Stream<String> get onPlaybackCompleted => const Stream.empty();

  Stream<Duration> get onPlaybackPosition => const Stream.empty();

  Stream<Duration> get onPlaybackDuration => const Stream.empty();

  Stream<String?> get onRecordingChanged;

  Future<bool> hasMicrophonePermission();

  Future<void> playReference(String audioAsset, {String? playbackId});

  Future<void> playRecording(String path, {String? playbackId});

  Future<void> stopPlayback();

  Future<void> startRecording(String recordingId);

  Future<String?> stopRecording();

  Future<void> cancelRecording();

  Future<void> deleteRecording(String path);

  Future<void> dispose();
}

/// One playback owns one player and its completion subscriptions.
/// Una reproducción posee su reproductor y suscripciones.
class _PlaybackSession {
  _PlaybackSession(this.token, this.id, this.player);

  final int token;
  final String id;
  final AudioPlayer player;
  // Completes only after any late start has been stopped.
  // Se completa solo cuando un arranque tardío ya no puede sonar.
  final Completer<void> quiesced = Completer<void>();
  final Completer<void> initialStopSettled = Completer<void>();
  StreamSubscription<void>? completionSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration>? durationSubscription;
  Future<void>? releaseFuture;
  bool valid = true;
  bool completionEmitted = false;
}

/// Coordinates reference playback and temporary learner recordings.
/// Coordina la reproducción de referencia y las grabaciones temporales.
class PronunciationAudioService implements PronunciationAudioController {
  PronunciationAudioService({
    AudioPlayer Function()? audioPlayerFactory,
    AudioRecorder? audioRecorder,
  }) : _audioPlayerFactory = audioPlayerFactory ?? AudioPlayer.new,
       _audioRecorder = audioRecorder ?? AudioRecorder();

  // A factory, rather than a shared AudioPlayer, allows independent events.
  // La fábrica, no una instancia compartida, aísla los eventos.
  final AudioPlayer Function() _audioPlayerFactory;
  final AudioRecorder _audioRecorder;

  final StreamController<String?> _playbackIdController =
      StreamController<String?>.broadcast();
  final StreamController<String?> _recordingIdController =
      StreamController<String?>.broadcast();
  final StreamController<String> _playbackCompletedController =
      StreamController<String>.broadcast();
  final StreamController<Duration> _playbackPositionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _playbackDurationController =
      StreamController<Duration>.broadcast();

  final Set<String> _temporaryRecordingPaths = {};
  final Set<_PlaybackSession> _sessions = {};
  // Keep only detached completion fences for starts not yet settled.
  // Conserva solo barreras sin referencias al reproductor antiguo.
  final Set<Completer<void>> _pendingStartFences = {};
  // Once hardware shutdown cannot be verified, do not start another player.
  // Si no puede garantizarse la detención física, bloquear nuevos audios.
  bool _unsafeHardwareRelease = false;
  _PlaybackSession? _activeSession;
  bool _disposed = false;
  int _nextSessionToken = 0;
  int _nextRequestToken = 0;
  // Never overlap with an unresolved former start: fail closed instead.
  // Nunca solapar un arranque anterior incierto: bloquear con error.
  static const _replacementTimeout = Duration(seconds: 5);
  Future<void>? _disposeFuture;

  // Read-only, test-focused diagnostics; never expose player instances.
  // Diagnóstico de pruebas sin exponer instancias de reproducción.
  int get debugTrackedPlaybackSessionCount => _sessions.length;
  int get debugPendingPlaybackFenceCount => _pendingStartFences.length;

  /// Returns the private temporary directory used by this lesson.
  /// Devuelve el directorio temporal privado utilizado por esta lección.
  Future<Directory> _getRecordingDirectory() async {
    final existingDirectory = _recordingDirectory;

    if (existingDirectory != null && await existingDirectory.exists()) {
      return existingDirectory;
    }

    final directory = await Directory.systemTemp.createTemp(
      'app_ingles_pronunciation_',
    );

    try {
      await _restrictUnixPermissions(directory.path, '700');
    } catch (_) {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }

      rethrow;
    }

    _recordingDirectory = directory;

    return directory;
  }

  /// Restricts temporary audio permissions on Unix-like systems.
  /// Restringe los permisos del audio temporal en sistemas Unix.
  Future<void> _restrictUnixPermissions(String path, String mode) async {
    if (!Platform.isLinux && !Platform.isMacOS) {
      return;
    }

    final result = await Process.run('chmod', [mode, path]);

    if (result.exitCode != 0) {
      throw FileSystemException(
        'No se pudieron restringir los permisos temporales.',
        path,
      );
    }
  }

  String? _activePlaybackId;
  String? _activeRecordingId;
  String? _activeRecordingPath;
  Directory? _recordingDirectory;

  /// Identifier of the reference or learner audio currently playing.
  /// Identificador del audio de referencia o del estudiante que está activo.
  @override
  String? get activePlaybackId => _activePlaybackId;

  /// Identifier of the example currently using the microphone.
  /// Identificador del ejemplo que está utilizando el micrófono.
  @override
  String? get activeRecordingId => _activeRecordingId;

  @override
  Stream<String?> get onPlaybackChanged => _playbackIdController.stream;
  @override
  Stream<String> get onPlaybackCompleted => _playbackCompletedController.stream;
  @override
  Stream<Duration> get onPlaybackPosition => _playbackPositionController.stream;
  @override
  Stream<Duration> get onPlaybackDuration => _playbackDurationController.stream;
  @override
  Stream<String?> get onRecordingChanged => _recordingIdController.stream;

  @override
  Future<bool> hasMicrophonePermission() => _audioRecorder.hasPermission();

  bool _isActive(_PlaybackSession session) =>
      !_disposed &&
      session.valid &&
      identical(_activeSession, session) &&
      session.token == _activeSession?.token;

  void _bindSession(_PlaybackSession session) {
    session.completionSubscription = session.player.onPlayerComplete.listen((
      _,
    ) {
      if (!_isActive(session) || session.completionEmitted) return;
      session.completionEmitted = true;
      // Publish the completing session's own ID before its deactivation.
      // Publica el ID de la sesión emisora antes de desactivarla.
      if (!_playbackCompletedController.isClosed) {
        _playbackCompletedController.add(session.id);
      }
      _retire(session);
    });
    session.positionSubscription = session.player.onPositionChanged.listen((v) {
      if (_isActive(session) && !_playbackPositionController.isClosed) {
        _playbackPositionController.add(v);
      }
    });
    session.durationSubscription = session.player.onDurationChanged.listen((v) {
      if (_isActive(session) && !_playbackDurationController.isClosed) {
        _playbackDurationController.add(v);
      }
    });
  }

  /// Invalidates synchronously; async stop/disposal cannot restore validity.
  /// Invalida sin await; stop/dispose nunca restauran la validez.
  void _retire(_PlaybackSession session) {
    if (!session.valid) return;
    session.valid = false;
    if (identical(_activeSession, session)) {
      _activeSession = null;
      _setActivePlayback(null);
    }
    unawaited(_releaseSession(session));
  }

  Future<void> _releaseSession(_PlaybackSession session) {
    if (session.releaseFuture != null) return session.releaseFuture!;
    final future = _finishRelease(session);
    session.releaseFuture = future;
    // A completion callback must not create an unhandled async exception.
    // Una devolución de evento no debe producir excepciones asíncronas sin manejar.
    unawaited(future.catchError((Object _) {}));
    return future;
  }

  Future<void> _finishRelease(_PlaybackSession session) async {
    var stopped = false;
    var subscriptionsCancelled = false;
    var disposed = false;
    try {
      try {
        await session.player.stop();
        stopped = true;
      } catch (_) {
        // A failed stop is not proof of physical silence.
        // Un stop fallido no demuestra que el audio esté detenido.
      } finally {
        if (!session.initialStopSettled.isCompleted) {
          session.initialStopSettled.complete();
        }
      }

      try {
        await session.completionSubscription?.cancel();
        await session.positionSubscription?.cancel();
        await session.durationSubscription?.cancel();
        subscriptionsCancelled = true;
      } catch (_) {
        // Still attempt native disposal, even after cancellation errors.
        // Liberar igualmente aunque falle cancelar una suscripción.
      }

      try {
        await session.player.dispose();
        disposed = true;
      } catch (_) {
        // Fail closed: never assume a failed disposal stopped audio.
        // Bloquear nuevas reproducciones si falla la liberación.
      }
    } finally {
      if (!stopped || !subscriptionsCancelled || !disposed) {
        _unsafeHardwareRelease = true;
      }
      // The service must not retain a dead session while play() hangs.
      // The detached start fence still blocks replacements until play settles.
      // El servicio no retiene la sesión; su barrera impide solapamientos.
      _sessions.remove(session);
    }
  }

  Future<void> _play(Source source, String playbackId) async {
    if (_disposed) throw StateError('El servicio de audio está liberado.');
    final request = ++_nextRequestToken;
    final previous = _activeSession;
    if (previous != null) _retire(previous);

    // Await old native cleanups AND detached start fences, never a player
    // retained solely because play() remains unresolved.
    // Esperar limpieza y arranques pendientes sin retener reproductores.
    final barriers = <Future<void>>[
      ..._sessions.map(_releaseSession),
      ..._pendingStartFences.map((fence) => fence.future),
    ];
    if (barriers.isNotEmpty) {
      try {
        await Future.wait(barriers).timeout(_replacementTimeout);
      } on TimeoutException {
        if (_disposed || request != _nextRequestToken) return;
        throw StateError(
          'Reproducción bloqueada: el audio anterior no terminó de arrancar.',
        );
      }
    }

    if (_unsafeHardwareRelease) {
      if (_disposed || request != _nextRequestToken) return;
      throw StateError(
        'Reproducción bloqueada: no se confirmó la detención del audio anterior.',
      );
    }

    // An obsolete queued request cannot start after a newer one or stop().
    // Una solicitud en espera no puede reactivarse tras stop() u otra solicitud.
    if (_disposed || request != _nextRequestToken) return;
    final session = _PlaybackSession(
      ++_nextSessionToken,
      playbackId,
      _audioPlayerFactory(),
    );
    _sessions.add(session);
    _pendingStartFences.add(session.quiesced);
    _activeSession = session;
    _bindSession(session);
    _setActivePlayback(playbackId);

    try {
      if (!_isActive(session)) return;
      await session.player.play(source);
    } catch (_) {
      if (!_isActive(session)) return;
      _retire(session);
      rethrow;
    } finally {
      try {
        if (!session.valid) {
          // Guard against late playback from any mock/platform implementation.
          // Garantía adicional ante reproducciones que arrancan tarde.
          try {
            await session.player.stop();
          } catch (_) {
            // A late start might still be audible; forbid new playback.
            // Un arranque tardío podría sonar: bloquear otro audio.
            _unsafeHardwareRelease = true;
          }
          await _releaseSession(session);
        }
      } finally {
        session.quiesced.complete();
        _pendingStartFences.remove(session.quiesced);
      }
    }
  }

  @override
  Future<void> playReference(String audioAsset, {String? playbackId}) =>
      _play(AssetSource(audioAsset), playbackId ?? 'reference:$audioAsset');

  @override
  Future<void> playRecording(String path, {String? playbackId}) =>
      _play(DeviceFileSource(path), playbackId ?? 'recording:$path');

  @override
  Future<void> stopPlayback() {
    // Also cancels a replacement waiting behind an older pending play().
    ++_nextRequestToken;
    final session = _activeSession;
    if (session == null) return Future<void>.value();
    _retire(session);
    // Do not wait for an uncompleted play(): it was invalidated already.
    // No bloquearse por play() pendiente: ya quedó invalidado.
    return session.initialStopSettled.future;
  }

  /// Starts a mono WAV recording for one lesson example.
  /// Inicia una grabación WAV mono para un ejemplo de la lección.
  @override
  Future<void> startRecording(String recordingId) async {
    await stopPlayback();

    if (_activeRecordingId != null || await _audioRecorder.isRecording()) {
      throw StateError('Ya existe una grabación activa.');
    }

    const config = RecordConfig(encoder: AudioEncoder.wav, numChannels: 1);

    final isSupported = await _audioRecorder.isEncoderSupported(
      AudioEncoder.wav,
    );

    if (!isSupported) {
      throw StateError('La grabación WAV no está disponible.');
    }

    final recordingDirectory = await _getRecordingDirectory();
    final path =
        '${recordingDirectory.path}/pronunciation_'
        '${DateTime.now().microsecondsSinceEpoch}.wav';

    // Blocks the other examples while the recorder is starting.
    // Bloquea los demás ejemplos mientras se inicia el grabador.
    _setActiveRecording(recordingId);

    try {
      await _audioRecorder.start(config, path: path);
      _activeRecordingPath = path;
      _temporaryRecordingPaths.add(path);
    } catch (_) {
      _activeRecordingPath = null;
      _setActiveRecording(null);

      final incompleteFile = File(path);

      if (await incompleteFile.exists()) {
        await incompleteFile.delete();
      }

      rethrow;
    }
  }

  /// Stops recording and returns the generated temporary file path.
  /// Detiene la grabación y devuelve la ruta del archivo temporal.
  @override
  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (path != null) {
        try {
          await _restrictUnixPermissions(path, '600');
        } catch (_) {
          final insecureFile = File(path);

          if (await insecureFile.exists()) {
            await insecureFile.delete();
          }

          rethrow;
        }

        _temporaryRecordingPaths.add(path);
      }

      return path;
    } finally {
      _activeRecordingPath = null;
      _setActiveRecording(null);
    }
  }

  /// Cancels the active recording and discards its incomplete file.
  /// Cancela la grabación activa y descarta su archivo incompleto.
  @override
  Future<void> cancelRecording() async {
    final path = _activeRecordingPath;

    try {
      await _audioRecorder.cancel();
    } finally {
      _activeRecordingPath = null;
      _setActiveRecording(null);

      if (path != null) {
        await deleteRecording(path);
      }
    }
  }

  /// Deletes one completed temporary learner recording.
  /// Elimina una grabación temporal completada del estudiante.
  @override
  Future<void> deleteRecording(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }

    _temporaryRecordingPaths.remove(path);
  }

  /// Updates and broadcasts the identifier of the active playback.
  /// Actualiza y publica el identificador de la reproducción activa.
  void _setActivePlayback(String? playbackId) {
    if (_activePlaybackId == playbackId) {
      return;
    }

    _activePlaybackId = playbackId;

    if (!_playbackIdController.isClosed) {
      _playbackIdController.add(playbackId);
    }
  }

  /// Updates and broadcasts the identifier of the active recording.
  /// Actualiza y publica el identificador de la grabación activa.
  void _setActiveRecording(String? recordingId) {
    if (_activeRecordingId == recordingId) {
      return;
    }

    _activeRecordingId = recordingId;

    if (!_recordingIdController.isClosed) {
      _recordingIdController.add(recordingId);
    }
  }

  /// Releases audio resources and removes all temporary learner audio.
  /// Libera los recursos y elimina todo el audio temporal del estudiante.
  @override
  Future<void> dispose() {
    if (_disposeFuture != null) return _disposeFuture!;
    _disposed = true;
    ++_nextRequestToken;
    for (final session in _sessions.toList()) {
      _retire(session);
    }
    _disposeFuture = _disposeResources();
    return _disposeFuture!;
  }

  Future<void> _disposeResources() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await cancelRecording();
      }
      for (final path in List<String>.from(_temporaryRecordingPaths)) {
        await deleteRecording(path);
      }
      final directory = _recordingDirectory;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
      _recordingDirectory = null;
    } finally {
      try {
        await Future.wait(
          _sessions.toList().map(_releaseSession),
          eagerError: false,
        );
      } finally {
        // This service is terminal; retained fences are unnecessary even
        // when a third-party play() future never completes.
        // Servicio cerrado: descartar barreras sin guardar sesiones.
        _pendingStartFences.clear();
        await _audioRecorder.dispose();
        await _playbackIdController.close();
        await _recordingIdController.close();
        await _playbackCompletedController.close();
        await _playbackPositionController.close();
        await _playbackDurationController.close();
      }
    }
  }
}
