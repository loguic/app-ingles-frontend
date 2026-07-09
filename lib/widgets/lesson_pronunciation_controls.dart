import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../models/lesson.dart';

/// Displays and plays the available pronunciation variants for a sentence.
/// Muestra y reproduce las variantes de pronunciación disponibles para una frase.
class LessonPronunciationControls extends StatefulWidget {
  const LessonPronunciationControls({required this.pronunciations, super.key});

  /// Regional pronunciations provided by the lesson content.
  /// Pronunciaciones regionales proporcionadas por el contenido de la lección.
  final List<LessonPronunciation> pronunciations;

  @override
  State<LessonPronunciationControls> createState() =>
      _LessonPronunciationControlsState();
}

class _LessonPronunciationControlsState
    extends State<LessonPronunciationControls> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription<void>? _completionSubscription;
  String? _playingLocale;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Restores the controls when the current audio finishes.
    // Restaura los controles cuando termina el audio actual.
    _completionSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playingLocale = null;
      });
    });
  }

  /// Plays the local audio associated with one pronunciation variant.
  /// Reproduce el audio local asociado con una variante de pronunciación.
  Future<void> _playPronunciation(LessonPronunciation pronunciation) async {
    if (_playingLocale != null) {
      return;
    }

    setState(() {
      _playingLocale = pronunciation.locale;
      _errorMessage = null;
    });

    try {
      await _audioPlayer.play(AssetSource(pronunciation.audioAsset));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _playingLocale = null;
        _errorMessage = 'No se pudo reproducir el audio. Inténtalo nuevamente.';
      });
    }
  }

  /// Converts the technical locale into a short learner-friendly label.
  /// Convierte la configuración regional técnica en una etiqueta comprensible.
  String _localeLabel(String locale) {
    return switch (locale) {
      'en-US' => 'Inglés estadounidense',
      'en-GB' => 'Inglés británico',
      _ => locale,
    };
  }

  @override
  void dispose() {
    _completionSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pronunciations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...widget.pronunciations.map((pronunciation) {
          final isPlaying = _playingLocale == pronunciation.locale;

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
                  onPressed: _playingLocale == null
                      ? () => _playPronunciation(pronunciation)
                      : null,
                  icon: Icon(isPlaying ? Icons.volume_up : Icons.play_arrow),
                ),
              ],
            ),
          );
        }),
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
