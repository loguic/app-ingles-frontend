import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/pronunciation_audio_service.dart';
import '../theme/loguic_theme.dart';
import '../widgets/lesson_pronunciation_controls.dart';

/// Isolated visual bridge for the approved A1 v4 water reference.
/// It is deliberately not a runtime activation or a curriculum loader.
class A1V4VisibleDemoScreen extends StatefulWidget {
  const A1V4VisibleDemoScreen({this.audioController, super.key});

  static const visualAsset = 'assets/a1_v4/visual/scene-water.png';
  static const audioAsset = 'a1_v4/audio/i-need-water.en-gb.wav';
  static const visualResourceId = 'visual.a1-u1-l1.scene.water.v1';
  static const audioResourceId = 'audio.a1-u1-l1.i-need-water.en-gb.v1';
  static const visualSha256 =
      '7f923e4d276863ad60dbf8d7ffbb476e3c4921e3b32da4c9991e8779f419e7db';
  static const audioSha256 =
      'eaaddfc611105e138586fff8634d4eda18e12a522d204b5d62e0bbbbc363fa0c';

  final PronunciationAudioController? audioController;

  @override
  State<A1V4VisibleDemoScreen> createState() => _A1V4VisibleDemoScreenState();
}

class _A1V4VisibleDemoScreenState extends State<A1V4VisibleDemoScreen> {
  late final PronunciationAudioController _audioController;
  late final bool _ownsAudioController;

  @override
  void initState() {
    super.initState();
    _ownsAudioController = widget.audioController == null;
    _audioController = widget.audioController ?? PronunciationAudioService();
  }

  @override
  void dispose() {
    if (_ownsAudioController) unawaited(_audioController.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('A1 v4 · I need water')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _A1V4IsolationNotice(),
                  const SizedBox(height: 20),
                  SizedBox(
                    key: const Key('a1-v4-water-scene-frame'),
                    height: 280,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        LoguicTheme.cardRadius,
                      ),
                      child: Image.asset(
                        A1V4VisibleDemoScreen.visualAsset,
                        key: const Key('a1-v4-water-scene'),
                        fit: BoxFit.contain,
                        semanticLabel:
                            'A person holds an empty bottle beside a refill tap.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'I need water.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: LoguicTheme.deepNavy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Listen. Say it.'),
                  const SizedBox(height: 16),
                  LessonPronunciationControls(
                    exampleId: 'demo-visual-a1-v4-i-need-water',
                    pronunciations: const [
                      LessonPronunciation(
                        locale: 'en-GB',
                        ipa: '/aɪ niːd ˈwɔːtə/',
                        audioAsset: A1V4VisibleDemoScreen.audioAsset,
                      ),
                    ],
                    audioService: _audioController,
                    demoMode: true,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver a la demostración'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _A1V4IsolationNotice extends StatelessWidget {
  const _A1V4IsolationNotice();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LoguicTheme.indigo.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(LoguicTheme.cardRadius),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Demostración aislada A1 v4 · Recursos aprobados · '
          'No activa el currículo ni guarda resultados',
        ),
      ),
    );
  }
}
