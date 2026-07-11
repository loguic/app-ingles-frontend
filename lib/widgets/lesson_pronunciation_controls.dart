import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/pronunciation_audio_service.dart';

/// Displays reference pronunciations and learner recording controls.
/// Muestra pronunciaciones de referencia y controles de grabación.
class LessonPronunciationControls extends StatefulWidget {
  const LessonPronunciationControls({
    required this.exampleId,
    required this.pronunciations,
    this.audioService,
    super.key,
  });

  /// Local identifier used to coordinate this example inside the lesson.
  /// Identificador local usado para coordinar este ejemplo dentro de la lección.
  final String exampleId;

  /// Regional pronunciations provided by the lesson content.
  /// Pronunciaciones regionales proporcionadas por el contenido de la lección.
  final List<LessonPronunciation> pronunciations;

  /// Shared audio service owned by the lesson screen.
  /// Servicio de audio compartido y administrado por la pantalla de la lección.
  final PronunciationAudioController? audioService;

  @override
  State<LessonPronunciationControls> createState() =>
      _LessonPronunciationControlsState();
}

class _LessonPronunciationControlsState
    extends State<LessonPronunciationControls> {
  late final PronunciationAudioController _audioService;
  late final bool _ownsAudioService;

  StreamSubscription<String?>? _playbackSubscription;
  StreamSubscription<String?>? _recordingSubscription;

  String? _activePlaybackId;
  String? _activeRecordingId;
  String? _recordingPath;
  String? _errorMessage;

  bool _isBusy = false;

  bool get _isRecording => _activeRecordingId == widget.exampleId;

  bool get _anotherExampleIsRecording =>
      _activeRecordingId != null && !_isRecording;

  bool get _isLearnerRecordingPlaying =>
      _activePlaybackId == 'recording:${widget.exampleId}';

  @override
  void initState() {
    super.initState();

    // Keeps backward compatibility when the widget is used independently.
    // Mantiene compatibilidad cuando el widget se usa de forma independiente.
    _ownsAudioService = widget.audioService == null;
    _audioService = widget.audioService ?? PronunciationAudioService();

    _activePlaybackId = _audioService.activePlaybackId;
    _activeRecordingId = _audioService.activeRecordingId;

    // Synchronizes this control with shared lesson playback.
    // Sincroniza este control con la reproducción compartida de la lección.
    _playbackSubscription = _audioService.onPlaybackChanged.listen((
      playbackId,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activePlaybackId = playbackId;
      });
    });

    // Synchronizes this control with shared microphone usage.
    // Sincroniza este control con el uso compartido del micrófono.
    _recordingSubscription = _audioService.onRecordingChanged.listen((
      recordingId,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeRecordingId = recordingId;
      });
    });
  }

  /// Plays one regional pronunciation reference.
  /// Reproduce una pronunciación regional de referencia.
  Future<void> _playPronunciation(LessonPronunciation pronunciation) async {
    if (_isBusy || _activePlaybackId != null || _activeRecordingId != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _audioService.playReference(
        pronunciation.audioAsset,
        playbackId: 'reference:${widget.exampleId}:${pronunciation.locale}',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo reproducir el audio. Inténtalo nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  /// Starts a new learner recording after checking microphone permission.
  /// Inicia una grabación después de comprobar el permiso del micrófono.
  Future<void> _startRecording() async {
    if (_isBusy || _activeRecordingId != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await _audioService.hasMicrophonePermission();

      if (!hasPermission) {
        if (!mounted) {
          return;
        }

        setState(() {
          _errorMessage = 'No se concedió permiso para utilizar el micrófono.';
        });
        return;
      }

      final previousPath = _recordingPath;

      if (previousPath != null) {
        await _audioService.stopPlayback();
        await _audioService.deleteRecording(previousPath);

        if (mounted) {
          setState(() {
            _recordingPath = null;
          });
        }
      }

      await _audioService.startRecording(widget.exampleId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo iniciar la grabación. Revisa el micrófono.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  /// Stops the current recording and keeps its temporary WAV file.
  /// Detiene la grabación y conserva temporalmente su archivo WAV.
  Future<void> _stopRecording() async {
    if (_isBusy || !_isRecording) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final path = await _audioService.stopRecording();

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingPath = path;
        _errorMessage = path == null
            ? 'No se pudo crear una grabación utilizable.'
            : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo detener correctamente la grabación.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  /// Plays the learner recording for auditory comparison.
  /// Reproduce la grabación del estudiante para compararla.
  Future<void> _playLearnerRecording() async {
    final path = _recordingPath;

    if (path == null ||
        _isBusy ||
        _activePlaybackId != null ||
        _activeRecordingId != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await _audioService.playRecording(
        path,
        playbackId: 'recording:${widget.exampleId}',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'No se pudo reproducir tu grabación. Inténtalo nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  /// Deletes the learner recording from temporary storage.
  /// Elimina la grabación del estudiante del almacenamiento temporal.
  Future<void> _deleteLearnerRecording() async {
    final path = _recordingPath;

    if (path == null || _isBusy || _isRecording) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      if (_isLearnerRecordingPlaying) {
        await _audioService.stopPlayback();
      }

      await _audioService.deleteRecording(path);

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingPath = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'No se pudo eliminar la grabación temporal.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  /// Converts the technical locale into a learner-friendly label.
  /// Convierte la configuración regional en una etiqueta comprensible.
  String _localeLabel(String locale) {
    return switch (locale) {
      'en-US' => 'Inglés estadounidense',
      'en-GB' => 'Inglés británico',
      _ => locale,
    };
  }

  /// Returns the shared identifier for one reference pronunciation.
  /// Devuelve el identificador compartido de una pronunciación.
  String _referencePlaybackId(LessonPronunciation pronunciation) {
    return 'reference:${widget.exampleId}:${pronunciation.locale}';
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _recordingSubscription?.cancel();

    // Only disposes services created internally by this widget.
    // Solo libera servicios creados internamente por este widget.
    if (_ownsAudioService) {
      unawaited(_audioService.dispose());
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pronunciations.isEmpty) {
      return const SizedBox.shrink();
    }

    final canStartPlayback =
        !_isBusy && _activePlaybackId == null && _activeRecordingId == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...widget.pronunciations.map((pronunciation) {
          final isPlaying =
              _activePlaybackId == _referencePlaybackId(pronunciation);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localeLabel(pronunciation.locale),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(pronunciation.ipa),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isPlaying
                      ? 'Reproduciendo audio'
                      : 'Escuchar pronunciación',
                  onPressed: canStartPlayback
                      ? () => _playPronunciation(pronunciation)
                      : null,
                  icon: Icon(isPlaying ? Icons.volume_up : Icons.play_arrow),
                ),
              ],
            ),
          );
        }),
        const Divider(),
        const Text(
          'Practica tu pronunciación',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_isRecording) ...[
          const Row(
            children: [
              Icon(Icons.mic),
              SizedBox(width: 8),
              Text(
                'Grabando...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isBusy ? null : _stopRecording,
            icon: const Icon(Icons.stop),
            label: const Text('Detener grabación'),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed:
                !_isBusy &&
                    _activePlaybackId == null &&
                    _activeRecordingId == null
                ? _startRecording
                : null,
            icon: const Icon(Icons.mic),
            label: Text(
              _recordingPath == null ? 'Grabar mi voz' : 'Volver a grabar',
            ),
          ),
        ],
        if (_anotherExampleIsRecording) ...[
          const SizedBox(height: 8),
          const Text('Termina la grabación activa para continuar.'),
        ],
        if (_recordingPath != null && !_isRecording) ...[
          const SizedBox(height: 8),
          const Text('Grabación disponible'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: canStartPlayback ? _playLearnerRecording : null,
                icon: Icon(
                  _isLearnerRecordingPlaying
                      ? Icons.volume_up
                      : Icons.play_arrow,
                ),
                label: const Text('Reproducir mi voz'),
              ),
              TextButton.icon(
                onPressed: !_isBusy && _activeRecordingId == null
                    ? _deleteLearnerRecording
                    : null,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
            ],
          ),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
