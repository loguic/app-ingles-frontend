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
  static const _referencePlaybackId =
      'reference:demo-visual-a1-v4-i-need-water:en-GB';

  late final PronunciationAudioController _audioController;
  late final bool _ownsAudioController;
  late final StreamSubscription<String> _referenceCompletionSubscription;
  bool _referenceListened = false;
  bool? _comprehensionAnswerIsCorrect;
  bool _fullModelVisible = false;
  bool _ownProductionStarted = false;
  bool _lowerSupportProductionUnlocked = false;

  @override
  void initState() {
    super.initState();
    _ownsAudioController = widget.audioController == null;
    _audioController = widget.audioController ?? PronunciationAudioService();
    _referenceCompletionSubscription = _audioController.onPlaybackCompleted
        .listen((playbackId) {
          final accepted =
              playbackId == _referencePlaybackId &&
              mounted &&
              !_referenceListened;
          if (accepted) {
            setState(() => _referenceListened = true);
          }
        });
  }

  @override
  void dispose() {
    unawaited(_referenceCompletionSubscription.cancel());
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
                  if (_fullModelVisible && !_ownProductionStarted) ...[
                    Text(
                      'I need water.',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: LoguicTheme.deepNavy,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text('Listen. Say it.'),
                  const SizedBox(height: 16),
                  const Text(
                    'Listen and repeat for self-perception',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This is repetition practice for how you hear yourself; '
                    'it is not your own oral production.',
                  ),
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
                  if (_referenceListened) ...[
                    const SizedBox(height: 24),
                    _A1V4ComprehensionCheck(
                      answerIsCorrect: _comprehensionAnswerIsCorrect,
                      onAnswer: (answerIsCorrect) {
                        setState(
                          () {
                            _comprehensionAnswerIsCorrect = answerIsCorrect;
                            _fullModelVisible = true;
                          },
                        );
                      },
                    ),
                  ],
                  if (_comprehensionAnswerIsCorrect == true &&
                      !_ownProductionStarted) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Your own oral production',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'When you start, the full model is hidden before you '
                      'record your own words.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: const Key('a1-v4-start-own-production'),
                      onPressed: () {
                        setState(() => _ownProductionStarted = true);
                      },
                      child: const Text('Start my own oral production'),
                    ),
                  ],
                  if (_ownProductionStarted) ...[
                    const SizedBox(height: 24),
                    _A1V4OwnProduction(
                      key: const Key('a1-v4-anchored-own-production'),
                      audioController: _audioController,
                      recordingId: 'demo-visual-a1-v4-own-production',
                      controlId: 'own-production',
                      productionPrompt: 'Look at the scene. Say what you need.',
                      showWordAnchors: true,
                      onRecordingCompleted: () {
                        if (!_lowerSupportProductionUnlocked) {
                          setState(() => _lowerSupportProductionUnlocked = true);
                        }
                      },
                    ),
                  ],
                  if (_lowerSupportProductionUnlocked) ...[
                    const SizedBox(height: 24),
                    _A1V4OwnProduction(
                      key: const Key('a1-v4-lower-support-own-production'),
                      audioController: _audioController,
                      recordingId:
                          'demo-visual-a1-v4-lower-support-own-production',
                      controlId: 'lower-support-own-production',
                      productionPrompt: 'Look at the scene. Speak in your own words.',
                      showWordAnchors: false,
                    ),
                  ],
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

class _A1V4ComprehensionCheck extends StatelessWidget {
  const _A1V4ComprehensionCheck({
    required this.answerIsCorrect,
    required this.onAnswer,
  });

  final bool? answerIsCorrect;
  final ValueChanged<bool> onAnswer;

  static const _options = [
    _A1V4VisualOption(
      asset: 'assets/a1_v4/visual/option-need.png',
      accessibilityLabel:
          'A person reaches toward a service counter with an empty bottle. '
          'No written English appears.',
      isCorrect: true,
    ),
    _A1V4VisualOption(
      asset: 'assets/a1_v4/visual/option-greeting.png',
      accessibilityLabel:
          'Two people meet and wave to each other. '
          'No written English appears.',
      isCorrect: false,
    ),
    _A1V4VisualOption(
      asset: 'assets/a1_v4/visual/option-farewell.png',
      accessibilityLabel:
          'Two people wave as they leave in different '
          'directions. No written English appears.',
      isCorrect: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final answerLocked = answerIsCorrect == true;

    return Semantics(
      container: true,
      label: 'Comprehension check',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose the matching picture',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: LoguicTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Elige la imagen que representa lo que escuchaste.'),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth >= 600
                  ? (constraints.maxWidth - 24) / 3
                  : (constraints.maxWidth - 12) / 2;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _options.map((option) {
                  return SizedBox(
                    width: width,
                    child: Semantics(
                      button: true,
                      label: option.accessibilityLabel,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: Key(
                            'a1-v4-comprehension-${option.isCorrect ? 'need' : option.asset.split('-').last.split('.').first}',
                          ),
                          onTap: answerLocked
                              ? null
                              : () => onAnswer(option.isCorrect),
                          child: AspectRatio(
                            aspectRatio: 1.5,
                            child: Image.asset(
                              option.asset,
                              fit: BoxFit.cover,
                              semanticLabel: option.accessibilityLabel,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (answerIsCorrect != null) ...[
            const SizedBox(height: 12),
            if (answerIsCorrect!)
              const _A1V4SuccessFeedback()
            else
              const Text('Try again.'),
          ],
        ],
      ),
    );
  }
}

class _A1V4SuccessFeedback extends StatelessWidget {
  const _A1V4SuccessFeedback();

  @override
  Widget build(BuildContext context) {
    final successColor = Colors.green.shade800;

    return Semantics(
      liveRegion: true,
      label: 'Correct!',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: successColor, width: 1.5),
          borderRadius: BorderRadius.circular(LoguicTheme.cardRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: successColor, size: 32),
            const SizedBox(width: 12),
            Text(
              'Correct!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: successColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _A1V4OwnProduction extends StatefulWidget {
  const _A1V4OwnProduction({
    required this.audioController,
    required this.recordingId,
    required this.controlId,
    required this.productionPrompt,
    required this.showWordAnchors,
    this.onRecordingCompleted,
    super.key,
  });

  final PronunciationAudioController audioController;
  final String recordingId;
  final String controlId;
  final String productionPrompt;
  final bool showWordAnchors;
  final VoidCallback? onRecordingCompleted;

  @override
  State<_A1V4OwnProduction> createState() => _A1V4OwnProductionState();
}

class _A1V4OwnProductionState extends State<_A1V4OwnProduction> {
  late final StreamSubscription<String?> _recordingSubscription;
  String? _activeRecordingId;
  String? _recordingPath;

  bool get _isRecording => _activeRecordingId == widget.recordingId;
  bool get _anotherRecordingIsActive =>
      _activeRecordingId != null && !_isRecording;

  @override
  void initState() {
    super.initState();
    _recordingSubscription = widget.audioController.onRecordingChanged.listen((
      recordingId,
    ) {
      if (mounted) setState(() => _activeRecordingId = recordingId);
    });
  }

  @override
  void dispose() {
    unawaited(_recordingSubscription.cancel());
    final path = _recordingPath;
    if (path != null) unawaited(widget.audioController.deleteRecording(path));
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_activeRecordingId != null) return;
    await widget.audioController.startRecording(widget.recordingId);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final path = await widget.audioController.stopRecording();
    if (mounted) {
      setState(() => _recordingPath = path);
      if (path != null) widget.onRecordingCompleted?.call();
    }
  }

  Future<void> _playRecording() async {
    final path = _recordingPath;
    if (path == null || _activeRecordingId != null) return;
    await widget.audioController.playRecording(
      path,
      playbackId: 'recording:${widget.recordingId}',
    );
  }

  Future<void> _deleteRecording() async {
    final path = _recordingPath;
    if (path == null || _isRecording) return;
    await widget.audioController.deleteRecording(path);
    if (mounted) setState(() => _recordingPath = null);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.showWordAnchors
          ? 'Own oral production'
          : 'Own oral production with lower support',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.showWordAnchors
                ? 'Your own oral production'
                : 'Your own oral production — lower support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: LoguicTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.productionPrompt),
          const SizedBox(height: 12),
          if (widget.showWordAnchors) ...[
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('I')),
                Chip(label: Text('need')),
                Chip(label: Text('water')),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'These are word anchors, not a full sentence model. '
              'Your recording stays temporary in this demo.',
            ),
          ],
          const SizedBox(height: 12),
          if (_isRecording)
            FilledButton.icon(
              key: Key('a1-v4-stop-${widget.controlId}'),
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop),
              label: const Text('Stop my own production'),
            )
          else
            FilledButton.icon(
              key: Key('a1-v4-record-${widget.controlId}'),
              onPressed: _anotherRecordingIsActive ? null : _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text('Record my own production'),
            ),
          if (_recordingPath != null && !_isRecording) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _playRecording,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play my own production'),
                ),
                TextButton.icon(
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete temporary recording'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _A1V4VisualOption {
  const _A1V4VisualOption({
    required this.asset,
    required this.accessibilityLabel,
    required this.isCorrect,
  });

  final String asset;
  final String accessibilityLabel;
  final bool isCorrect;
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
