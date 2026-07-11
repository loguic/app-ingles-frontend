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

/// Coordinates reference playback and temporary learner recordings.
/// Coordina la reproducción de referencia y las grabaciones temporales.
class PronunciationAudioService implements PronunciationAudioController {
  PronunciationAudioService({
    AudioPlayer? audioPlayer,
    AudioRecorder? audioRecorder,
  }) : _audioPlayer = audioPlayer ?? AudioPlayer(),
       _audioRecorder = audioRecorder ?? AudioRecorder() {
    // Clears the shared playback state when the audio reaches its end.
    // Limpia el estado compartido cuando el audio llega al final.
    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      _setActivePlayback(null);
    });
  }

  final AudioPlayer _audioPlayer;
  final AudioRecorder _audioRecorder;

  final StreamController<String?> _playbackIdController =
      StreamController<String?>.broadcast();

  final StreamController<String?> _recordingIdController =
      StreamController<String?>.broadcast();

  final Set<String> _temporaryRecordingPaths = {};

  late final StreamSubscription<void> _completionSubscription;

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

  /// Notifies all controls when the active playback changes.
  /// Notifica a todos los controles cuando cambia la reproducción activa.
  @override
  Stream<String?> get onPlaybackChanged => _playbackIdController.stream;

  /// Notifies all controls when the active recording changes.
  /// Notifica a todos los controles cuando cambia la grabación activa.
  @override
  Stream<String?> get onRecordingChanged => _recordingIdController.stream;

  /// Checks and requests microphone permission when required.
  /// Comprueba y solicita permiso de micrófono cuando sea necesario.
  @override
  Future<bool> hasMicrophonePermission() {
    return _audioRecorder.hasPermission();
  }

  /// Plays one pronunciation reference stored as a Flutter asset.
  /// Reproduce una pronunciación de referencia almacenada como recurso.
  @override
  Future<void> playReference(String audioAsset, {String? playbackId}) async {
    await stopPlayback();

    _setActivePlayback(playbackId ?? 'reference:$audioAsset');

    try {
      await _audioPlayer.play(AssetSource(audioAsset));
    } catch (_) {
      _setActivePlayback(null);
      rethrow;
    }
  }

  /// Plays the learner recording stored in the temporary directory.
  /// Reproduce la grabación del estudiante guardada temporalmente.
  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    await stopPlayback();

    _setActivePlayback(playbackId ?? 'recording:$path');

    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (_) {
      _setActivePlayback(null);
      rethrow;
    }
  }

  /// Stops any active reference or learner playback.
  /// Detiene cualquier reproducción de referencia o del estudiante.
  @override
  Future<void> stopPlayback() async {
    await _audioPlayer.stop();
    _setActivePlayback(null);
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
  Future<void> dispose() async {
    await stopPlayback();

    if (await _audioRecorder.isRecording()) {
      await cancelRecording();
    }

    for (final path in List<String>.from(_temporaryRecordingPaths)) {
      await deleteRecording(path);
    }

    final recordingDirectory = _recordingDirectory;

    if (recordingDirectory != null && await recordingDirectory.exists()) {
      await recordingDirectory.delete(recursive: true);
    }

    _recordingDirectory = null;

    await _completionSubscription.cancel();
    await _audioRecorder.dispose();
    await _audioPlayer.dispose();
    await _playbackIdController.close();
    await _recordingIdController.close();
  }
}
