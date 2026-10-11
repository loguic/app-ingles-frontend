import 'dart:async';

import 'package:flutter/material.dart';

import '../models/spoken_turn_evaluation.dart';
import '../services/api_service.dart';
import '../services/pronunciation_audio_service.dart';
import '../services/speech_recognition_factory.dart';
import '../services/speech_recognition_service.dart';
import '../theme/loguic_theme.dart';

/// A1 speaking journey built from the approved water and food contexts.
class A1V4VisibleDemoScreen extends StatefulWidget {
  const A1V4VisibleDemoScreen({
    this.audioController,
    this.apiService,
    this.speechRecognitionController,
    this.enableSpeechRecognition = true,
    this.enableRemoteAudioUpload = true,
    this.userId = 'demo-user',
    this.isDarkTheme = true,
    this.onThemeChanged,
    super.key,
  });

  static const visualAsset = 'assets/a1_v4/visual/scene-water.png';
  static const transferVisualAsset = 'assets/a1_v4/visual/scene-food.png';
  static const audioAsset = 'a1_v4/audio/i-need-water.en-gb.wav';
  static const visualResourceId = 'visual.a1-u1-l1.scene.water.v1';
  static const audioResourceId = 'audio.a1-u1-l1.i-need-water.en-gb.v1';
  static const visualSha256 =
      '7f923e4d276863ad60dbf8d7ffbb476e3c4921e3b32da4c9991e8779f419e7db';
  static const audioSha256 =
      'eaaddfc611105e138586fff8634d4eda18e12a522d204b5d62e0bbbbc363fa0c';

  final PronunciationAudioController? audioController;
  final ApiService? apiService;
  final SpeechRecognitionController? speechRecognitionController;
  final bool enableSpeechRecognition;
  final bool enableRemoteAudioUpload;
  final String userId;
  final bool isDarkTheme;
  final ValueChanged<ThemeMode>? onThemeChanged;

  @override
  State<A1V4VisibleDemoScreen> createState() => _A1V4VisibleDemoScreenState();
}

class _A1V4VisibleDemoScreenState extends State<A1V4VisibleDemoScreen> {
  static const _referencePlaybackId =
      'reference:demo-visual-a1-v4-i-need-water:en-GB';

  late final PronunciationAudioController _audioController;
  late final ApiService _apiService;
  late final SpeechRecognitionController? _speechRecognitionController;
  late final bool _ownsAudioController;
  late final StreamSubscription<String> _referenceCompletionSubscription;
  bool _referenceListened = false;
  bool _lowerSupportProductionUnlocked = false;
  bool _nearbyTransferUnlocked = false;
  String _lowerSupportLevel = 'none';
  String _transferSupportLevel = 'none';
  final Map<String, _A1V4ProductionCapture> _captures = {};
  bool _isSavingSession = false;
  bool _sessionSaved = false;
  String? _sessionSaveError;

  @override
  void initState() {
    super.initState();
    _ownsAudioController = widget.audioController == null;
    _audioController = widget.audioController ?? PronunciationAudioService();
    _apiService = widget.apiService ?? ApiService();
    _speechRecognitionController = widget.enableSpeechRecognition
        ? widget.speechRecognitionController ??
              createConfiguredSpeechRecognitionController()
        : null;
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

  Future<void> _playReference() async {
    await _audioController.playReference(
      A1V4VisibleDemoScreen.audioAsset,
      playbackId: _referencePlaybackId,
    );
  }

  void _captureChanged(_A1V4ProductionCapture capture) {
    if (!mounted) return;
    setState(() {
      _captures[capture.controlId] = capture;
      _sessionSaved = false;
      _sessionSaveError = null;
    });
  }

  void _captureRemoved(String controlId) {
    if (!mounted) return;
    setState(() {
      _captures.remove(controlId);
      _sessionSaved = false;
      _sessionSaveError = null;
    });
  }

  void _applyAdaptiveDecision(
    String controlId,
    SpokenTurnEvaluation evaluation,
  ) {
    if (!mounted) return;
    setState(() {
      // The backend alone selects the next support level and whether this
      // learner should advance. A retry remains on the current turn.
      if (controlId == 'own-production' &&
          evaluation.nextAction == 'reduce_support') {
        _lowerSupportLevel = evaluation.nextSupportLevel;
        _lowerSupportProductionUnlocked = true;
      }
      if (controlId == 'lower-support-own-production' &&
          (evaluation.nextAction == 'continue' ||
              evaluation.nextAction == 'reduce_support')) {
        _transferSupportLevel = evaluation.nextSupportLevel;
        _nearbyTransferUnlocked = true;
      }
    });
  }

  List<Map<String, dynamic>> get _priorEvidence => _captures.values
      .where((capture) => capture.evaluation != null)
      .map(
        (capture) => {
          'turn_id': capture.turnId,
          'semantic_status': capture.evaluation!.semanticStatus,
          // The runtime response has no term-level result. Preserve only
          // what it actually returned rather than infer terms locally.
          'matched_meaning_terms': <String>[],
          'missing_meaning_terms': <String>[],
        },
      )
      .toList();

  Future<void> _saveSession() async {
    if (_isSavingSession || _sessionSaved || _captures.length != 3) return;
    final ordered = [
      _captures['own-production'],
      _captures['lower-support-own-production'],
      _captures['nearby-transfer-food'],
    ];
    if (ordered.any((capture) => capture?.audioReference == null)) return;

    setState(() {
      _isSavingSession = true;
      _sessionSaveError = null;
    });
    try {
      final saved = await _apiService.saveConversationProductions(
        userId: widget.userId,
        levelId: 'A1',
        unitId: 'a1-u1',
        lessonId: 'a1-u1-l1',
        conversationId: 'a1-u1-l1-c2',
        productions: ordered
            .whereType<_A1V4ProductionCapture>()
            .map(
              (capture) => {
                'prompt_id': capture.promptId,
                'turn_id': capture.turnId,
                'modality': 'voice',
                'audio_reference': capture.audioReference,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _sessionSaved = saved;
        if (!saved) {
          _sessionSaveError =
              'Your answers are still here. Please try saving again.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _sessionSaveError =
              'Your answers are still here. Please try saving again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSavingSession = false);
    }
  }

  @override
  void dispose() {
    unawaited(_referenceCompletionSubscription.cancel());
    if (_ownsAudioController) unawaited(_audioController.dispose());
    super.dispose();
  }

  int get _activeStep {
    if (_captures['nearby-transfer-food']?.evaluation != null) return 4;
    if (_nearbyTransferUnlocked) return 3;
    if (_lowerSupportProductionUnlocked) return 2;
    if (_referenceListened) return 1;
    return 0;
  }

  _A1V4ProductionCapture? get _latestCapture =>
      _captures['nearby-transfer-food'] ??
      _captures['lower-support-own-production'] ??
      _captures['own-production'];

  Widget _buildLearningWorkspace(ColorScheme colors) {
    final center = _buildActiveExperience(colors);
    final feedback = _A1V4FeedbackPanel(capture: _latestCapture);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _A1V4ProgressRail(activeStep: _activeStep, compact: true),
              const SizedBox(height: 18),
              center,
              const SizedBox(height: 18),
              feedback,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 196,
              child: _A1V4ProgressRail(activeStep: _activeStep),
            ),
            const SizedBox(width: 24),
            Expanded(child: center),
            const SizedBox(width: 24),
            SizedBox(width: 292, child: feedback),
          ],
        );
      },
    );
  }

  Widget _buildActiveExperience(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _A1V4IsolationNotice(),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Container(
                key: const Key('a1-v4-water-scene-frame'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    LoguicTheme.cardRadius + 4,
                  ),
                  color: colors.surfaceContainerLow,
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: .7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .16),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LoguicTheme.cardRadius),
                  child: Image.asset(
                    A1V4VisibleDemoScreen.visualAsset,
                    key: const Key('a1-v4-water-scene'),
                    fit: BoxFit.cover,
                    semanticLabel:
                        'A person holds an empty bottle beside a refill tap.',
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Listen to the situation',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text('What does the person need?'),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            key: const Key('a1-v4-play-reference'),
            onPressed: _playReference,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Listen to the British English'),
          ),
        ),
        if (_referenceListened) ...[
          const SizedBox(height: 22),
          _buildOwnProduction(),
        ],
        if (_lowerSupportProductionUnlocked) ...[
          const SizedBox(height: 20),
          _buildLowerSupportProduction(),
        ],
        if (_nearbyTransferUnlocked) ...[
          const SizedBox(height: 20),
          _buildTransferProduction(),
        ],
        if (_captures['nearby-transfer-food']?.recordingPath != null) ...[
          const SizedBox(height: 20),
          _A1V4SessionSummary(
            captures: _captures,
            audioController: _audioController,
            remoteAudioEnabled: widget.enableRemoteAudioUpload,
            isSaving: _isSavingSession,
            saved: _sessionSaved,
            saveError: _sessionSaveError,
            onSave: _saveSession,
          ),
        ],
      ],
    );
  }

  Widget _buildOwnProduction() => _A1V4OwnProduction(
    key: const Key('a1-v4-anchored-own-production'),
    audioController: _audioController,
    recordingId: 'demo-visual-a1-v4-own-production',
    controlId: 'own-production',
    promptId: 'a1-u1-l1-c2-p1',
    turnId: 'a1-u1-l1-c2-t1',
    title: 'Say it yourself',
    productionPrompt: 'Look at the scene and say what you need.',
    supportLevel: 'anchors',
    requiredMeaningTerms: const ['need', 'water'],
    context: 'A learner is thirsty beside a refill tap and needs water.',
    apiService: _apiService,
    speechRecognitionController: _speechRecognitionController,
    enableRemoteAudioUpload: widget.enableRemoteAudioUpload,
    userId: widget.userId,
    onCaptureChanged: _captureChanged,
    onCaptureRemoved: _captureRemoved,
    priorTurnEvidence: _priorEvidence,
    onAdaptiveDecision: _applyAdaptiveDecision,
  );

  Widget _buildLowerSupportProduction() => _A1V4OwnProduction(
    key: const Key('a1-v4-lower-support-own-production'),
    audioController: _audioController,
    recordingId: 'demo-visual-a1-v4-lower-support-own-production',
    controlId: 'lower-support-own-production',
    promptId: 'a1-u1-l1-c2-p2',
    turnId: 'a1-u1-l1-c2-t2',
    title: 'Your own way',
    productionPrompt: 'Look at the scene. Speak in your own words.',
    supportLevel: _lowerSupportLevel,
    requiredMeaningTerms: const ['need', 'water'],
    context: 'The learner still needs water at the refill tap.',
    apiService: _apiService,
    speechRecognitionController: _speechRecognitionController,
    enableRemoteAudioUpload: widget.enableRemoteAudioUpload,
    userId: widget.userId,
    onCaptureChanged: _captureChanged,
    onCaptureRemoved: _captureRemoved,
    priorTurnEvidence: _priorEvidence,
    onAdaptiveDecision: _applyAdaptiveDecision,
  );

  Widget _buildTransferProduction() => _A1V4OwnProduction(
    key: const Key('a1-v4-nearby-transfer-production'),
    audioController: _audioController,
    recordingId: 'demo-visual-a1-v4-nearby-transfer-food',
    controlId: 'nearby-transfer-food',
    promptId: 'a1-u1-l1-c2-p3',
    turnId: 'a1-u1-l1-c2-t3',
    title: 'A new situation',
    productionPrompt: 'Look at the scene. Speak in your own words.',
    supportLevel: _transferSupportLevel,
    requiredMeaningTerms: const ['need', 'food'],
    context: 'A nearby new situation: the learner needs food.',
    apiService: _apiService,
    speechRecognitionController: _speechRecognitionController,
    enableRemoteAudioUpload: widget.enableRemoteAudioUpload,
    userId: widget.userId,
    onCaptureChanged: _captureChanged,
    onCaptureRemoved: _captureRemoved,
    contextAsset: A1V4VisibleDemoScreen.transferVisualAsset,
    contextSemanticLabel: 'A person needs food. No written English appears.',
    priorTurnEvidence: _priorEvidence,
    onAdaptiveDecision: _applyAdaptiveDecision,
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOGUIC English',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('A1 · Everyday speaking', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          _ThemeSelector(
            isDarkTheme: widget.isDarkTheme,
            onThemeChanged: widget.onThemeChanged,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.surfaceContainerLowest, colors.surface],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1440),
                child: _buildLearningWorkspace(colors),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.isDarkTheme, this.onThemeChanged});

  final bool isDarkTheme;
  final ValueChanged<ThemeMode>? onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? colors.surfaceContainer : const Color(0xFFEAF0F9);
    final border = isDark ? const Color(0xFF394869) : const Color(0xFFD3DCEB);
    final selected = isDark ? const Color(0xFF3E5FB4) : const Color(0xFFDDE7FF);
    final selectedText = isDark ? const Color(0xFFF3F6FF) : colors.primary;
    final unselectedText = isDark
        ? const Color(0xFFD6DDF0)
        : const Color(0xFF52627D);

    return Semantics(
      label: 'Theme selector',
      child: Container(
        key: const Key('a1-theme-toggle'),
        width: 176,
        height: 38,
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x33000000) : const Color(0x12183153),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _ThemeSegment(
              key: const Key('a1-theme-light'),
              icon: Icons.light_mode_outlined,
              label: 'Light',
              selected: !isDarkTheme,
              selectedColor: selected,
              selectedTextColor: selectedText,
              unselectedTextColor: unselectedText,
              onPressed: () => onThemeChanged?.call(ThemeMode.light),
            ),
            _ThemeSegment(
              key: const Key('a1-theme-dark'),
              icon: Icons.dark_mode_outlined,
              label: 'Dark',
              selected: isDarkTheme,
              selectedColor: selected,
              selectedTextColor: selectedText,
              unselectedTextColor: unselectedText,
              onPressed: () => onThemeChanged?.call(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.selectedTextColor,
    required this.unselectedTextColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color selectedColor;
  final Color selectedTextColor;
  final Color unselectedTextColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? selectedTextColor : unselectedTextColor;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label theme',
        child: Material(
          color: selected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(15),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: textColor),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

// Retained for the separate legacy visual-demo route; it is intentionally not
// mounted by the primary A1 conversation route.
// ignore: unused_element
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
              color: Theme.of(context).colorScheme.onSurface,
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
    required this.apiService,
    required this.recordingId,
    required this.controlId,
    required this.promptId,
    required this.turnId,
    required this.title,
    required this.productionPrompt,
    required this.supportLevel,
    required this.requiredMeaningTerms,
    required this.context,
    required this.enableRemoteAudioUpload,
    required this.userId,
    this.speechRecognitionController,
    this.contextAsset,
    this.contextSemanticLabel,
    this.onCaptureChanged,
    this.onCaptureRemoved,
    this.priorTurnEvidence = const [],
    this.onAdaptiveDecision,
    super.key,
  });

  final PronunciationAudioController audioController;
  final ApiService apiService;
  final SpeechRecognitionController? speechRecognitionController;
  final String recordingId;
  final String controlId;
  final String promptId;
  final String turnId;
  final String title;
  final String productionPrompt;
  final String supportLevel;
  final List<String> requiredMeaningTerms;
  final String context;
  final bool enableRemoteAudioUpload;
  final String userId;
  final String? contextAsset;
  final String? contextSemanticLabel;
  final ValueChanged<_A1V4ProductionCapture>? onCaptureChanged;
  final ValueChanged<String>? onCaptureRemoved;
  final List<Map<String, dynamic>> priorTurnEvidence;
  final void Function(String controlId, SpokenTurnEvaluation evaluation)?
  onAdaptiveDecision;

  @override
  State<_A1V4OwnProduction> createState() => _A1V4OwnProductionState();
}

class _A1V4OwnProductionState extends State<_A1V4OwnProduction> {
  late final StreamSubscription<String?> _recordingSubscription;
  late final StreamSubscription<String?> _playbackSubscription;
  late final StreamSubscription<String> _playbackCompletionSubscription;
  late final StreamSubscription<Duration> _playbackPositionSubscription;
  late final StreamSubscription<Duration> _playbackDurationSubscription;
  String? _activeRecordingId;
  String? _activePlaybackId;
  String? _recordingPath;
  SpeechRecognitionResult? _recognitionResult;
  String? _audioReference;
  SpokenTurnEvaluation? _evaluation;
  String? _processingError;
  bool _isProcessing = false;
  bool _isStartingRecording = false;
  bool _isStartingPlayback = false;
  String? _recordingStartError;
  Duration _playbackPosition = Duration.zero;
  Duration _playbackDuration = Duration.zero;

  bool get _isRecording => _activeRecordingId == widget.recordingId;
  bool get _anotherRecordingIsActive =>
      _activeRecordingId != null && !_isRecording;
  bool get _processingComplete => _evaluation != null;
  String get _recordingPlaybackId => 'recording:${widget.recordingId}';
  bool get _isPlayingRecording =>
      _isStartingPlayback || _activePlaybackId == _recordingPlaybackId;
  double get _playbackProgress {
    if (_playbackDuration <= Duration.zero) return 0;
    return (_playbackPosition.inMilliseconds / _playbackDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  List<String> get _visibleSupport => switch (widget.supportLevel) {
    'model' => ['I need ${widget.requiredMeaningTerms.last}.'],
    'anchors' => ['I', 'need', widget.requiredMeaningTerms.last],
    'initial_word' => ['I'],
    _ => const [],
  };

  @override
  void initState() {
    super.initState();
    _recordingSubscription = widget.audioController.onRecordingChanged.listen((
      recordingId,
    ) {
      if (mounted) setState(() => _activeRecordingId = recordingId);
    });
    _playbackSubscription = widget.audioController.onPlaybackChanged.listen((
      playbackId,
    ) {
      if (!mounted) return;
      setState(() {
        _activePlaybackId = playbackId;
        _isStartingPlayback = false;
        if (playbackId != _recordingPlaybackId) {
          _playbackPosition = Duration.zero;
          _playbackDuration = Duration.zero;
        }
      });
    });
    _playbackCompletionSubscription = widget.audioController.onPlaybackCompleted
        .listen((playbackId) {
          if (mounted && playbackId == _recordingPlaybackId) {
            setState(() {
              _isStartingPlayback = false;
              _playbackPosition = Duration.zero;
              _playbackDuration = Duration.zero;
            });
          }
        });
    _playbackPositionSubscription = widget.audioController.onPlaybackPosition
        .listen((position) {
          if (mounted && _activePlaybackId == _recordingPlaybackId) {
            setState(() => _playbackPosition = position);
          }
        });
    _playbackDurationSubscription = widget.audioController.onPlaybackDuration
        .listen((duration) {
          if (mounted && _activePlaybackId == _recordingPlaybackId) {
            setState(() => _playbackDuration = duration);
          }
        });
  }

  @override
  void dispose() {
    unawaited(_recordingSubscription.cancel());
    unawaited(_playbackSubscription.cancel());
    unawaited(_playbackCompletionSubscription.cancel());
    unawaited(_playbackPositionSubscription.cancel());
    unawaited(_playbackDurationSubscription.cancel());
    final path = _recordingPath;
    if (path != null) unawaited(widget.audioController.deleteRecording(path));
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_activeRecordingId != null || _isProcessing || _isStartingRecording) {
      return;
    }
    setState(() {
      _isStartingRecording = true;
      _recordingStartError = null;
    });

    try {
      // Keep this route on the same permission-gated controller path as the
      // established pronunciation and conversation recording controls.
      final hasPermission = await widget.audioController
          .hasMicrophonePermission();
      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _recordingStartError =
                'Please allow microphone access to record your answer.';
          });
        }
        return;
      }

      final previousPath = _recordingPath;
      if (previousPath != null) {
        await widget.audioController.deleteRecording(previousPath);
        widget.onCaptureRemoved?.call(widget.controlId);
      }
      if (mounted) {
        setState(() {
          _recordingPath = null;
          _recognitionResult = null;
          _audioReference = null;
          _evaluation = null;
          _processingError = null;
        });
      }
      await widget.audioController.startRecording(widget.recordingId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _recordingStartError =
              'We could not start recording. Please check your microphone and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isStartingRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    final path = await widget.audioController.stopRecording();
    if (mounted) {
      setState(() {
        _recordingPath = path;
        _recognitionResult = null;
        _audioReference = null;
        _evaluation = null;
        _processingError = null;
      });
      if (path != null) {
        _notifyCapture();
      }
    }
  }

  void _notifyCapture() {
    final path = _recordingPath;
    if (path == null) return;
    widget.onCaptureChanged?.call(
      _A1V4ProductionCapture(
        controlId: widget.controlId,
        recordingId: widget.recordingId,
        promptId: widget.promptId,
        turnId: widget.turnId,
        recordingPath: path,
        transcript: _recognitionResult?.transcript,
        audioReference: _audioReference,
        evaluation: _evaluation,
        requiredMeaningTerms: widget.requiredMeaningTerms,
      ),
    );
  }

  Future<void> _processRecording() async {
    final path = _recordingPath;
    if (path == null || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _processingError = null;
    });

    final errors = <String>[];
    final recognizer = widget.speechRecognitionController;
    if (recognizer != null) {
      try {
        _recognitionResult = await recognizer.recognize(
          SpeechRecognitionRequest(
            audioPath: path,
            languageCode: 'en',
            locale: 'en-GB',
            userId: widget.userId,
            levelId: 'A1',
            unitId: 'a1-u1',
            lessonId: 'a1-u1-l1',
            conversationId: 'a1-u1-l1-c2',
            turnId: widget.turnId,
            promptId: widget.promptId,
          ),
        );
      } catch (_) {
        errors.add(
          'We could not understand that answer yet. Listen and try again.',
        );
      }
    }

    if (widget.enableRemoteAudioUpload) {
      try {
        _audioReference = await widget.apiService
            .uploadConversationProductionAudio(path);
        if (_audioReference == null) {
          final detail =
              widget.apiService.lastConversationProductionAudioUploadError;
          errors.add(
            detail == null
                ? 'We could not save that answer. You can still get feedback.'
                : 'We could not save that answer. You can still get feedback.',
          );
        }
      } catch (_) {
        errors.add(
          'We could not save that answer. You can still get feedback.',
        );
      }
    }

    final transcript = _recognitionResult?.transcript?.trim();
    if (transcript == null || transcript.isEmpty) {
      errors.add(
        'We could not understand that answer yet. Listen and try again.',
      );
    } else {
      try {
        _evaluation = await widget.apiService.evaluateSpokenTurn(
          transcript: transcript,
          audioReference: _audioReference,
          target: {
            'communicative_goal':
                'Express an immediate need for ${widget.requiredMeaningTerms.last}.',
            'required_meaning_terms': widget.requiredMeaningTerms,
          },
          context: widget.context,
          currentTurn: {
            'turn_id': widget.turnId,
            'support_level': widget.supportLevel,
            'visible_support': _visibleSupport,
          },
          priorTurnEvidence: widget.priorTurnEvidence,
        );
        widget.onAdaptiveDecision?.call(widget.controlId, _evaluation!);
      } on SpokenTurnEvaluationException {
        errors.add('Feedback is not available right now. Please try again.');
      } catch (_) {
        errors.add('Feedback is not available right now. Please try again.');
      }
    }

    if (mounted) {
      setState(() {
        _processingError = errors.isEmpty ? null : errors.join(' ');
        _isProcessing = false;
      });
      _notifyCapture();
    }
  }

  Future<void> _playRecording() async {
    final path = _recordingPath;
    if (path == null || _activeRecordingId != null || _isProcessing) return;
    if (_isPlayingRecording) {
      return;
    }
    setState(() {
      _isStartingPlayback = true;
      _activePlaybackId = _recordingPlaybackId;
      _playbackPosition = Duration.zero;
      _playbackDuration = Duration.zero;
    });
    try {
      await widget.audioController.playRecording(
        path,
        playbackId: _recordingPlaybackId,
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isStartingPlayback = false;
          if (_activePlaybackId == _recordingPlaybackId) {
            _activePlaybackId = null;
          }
          _playbackPosition = Duration.zero;
          _playbackDuration = Duration.zero;
        });
      }
    }
  }

  Future<void> _deleteRecording() async {
    final path = _recordingPath;
    if (path == null || _isRecording) return;
    await widget.audioController.deleteRecording(path);
    widget.onCaptureRemoved?.call(widget.controlId);
    if (mounted) {
      setState(() {
        _recordingPath = null;
        _recognitionResult = null;
        _audioReference = null;
        _evaluation = null;
        _processingError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: widget.title,
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.contextAsset != null) ...[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: AspectRatio(
                      aspectRatio: 3 / 2,
                      child: Container(
                        key: const Key(
                          'a1-v4-nearby-transfer-food-scene-frame',
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            LoguicTheme.cardRadius,
                          ),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: .7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .14),
                              blurRadius: 18,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            LoguicTheme.cardRadius,
                          ),
                          child: Image.asset(
                            widget.contextAsset!,
                            key: const Key('a1-v4-nearby-transfer-food-scene'),
                            fit: BoxFit.cover,
                            semanticLabel: widget.contextSemanticLabel,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.productionPrompt),
              const SizedBox(height: 12),
              if (_visibleSupport.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _visibleSupport
                      .map((support) => Chip(label: Text(support)))
                      .toList(),
                ),
                const SizedBox(height: 8),
                const Text('Use these words if they help you begin.'),
              ],
              const SizedBox(height: 12),
              Center(
                child: _VoiceRecordControl(
                  key: Key('a1-v4-voice-control-${widget.controlId}'),
                  state: _isRecording
                      ? _VoiceControlState.recording
                      : _recordingPath != null
                      ? _VoiceControlState.recorded
                      : _VoiceControlState.ready,
                  enabled:
                      !_anotherRecordingIsActive &&
                      !_isProcessing &&
                      !_isStartingRecording,
                  onPressed: _isRecording
                      ? _stopRecording
                      : _recordingPath == null
                      ? _startRecording
                      : null,
                  actionKey: _isRecording
                      ? Key('a1-v4-stop-${widget.controlId}')
                      : Key('a1-v4-record-${widget.controlId}'),
                ),
              ),
              if (_recordingStartError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _recordingStartError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_recordingPath != null && !_isRecording) ...[
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _LearnerPlaybackControl(
                        controlId: widget.controlId,
                        isPlaying: _isPlayingRecording,
                        progress: _playbackProgress,
                        enabled: !_isProcessing,
                        onPressed: _playRecording,
                      ),
                      TextButton.icon(
                        onPressed: _isProcessing ? null : _deleteRecording,
                        icon: const Icon(Icons.mic_none_outlined),
                        label: const Text('Record again'),
                      ),
                      FilledButton.icon(
                        key: Key('a1-v4-process-${widget.controlId}'),
                        onPressed: _isProcessing || _processingComplete
                            ? null
                            : _processRecording,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _processingComplete
                                    ? Icons.check_circle_outline
                                    : Icons.auto_awesome_outlined,
                              ),
                        label: Text(
                          _isProcessing
                              ? 'Processing…'
                              : _processingComplete
                              ? 'Feedback received'
                              : 'Get feedback',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _A1V4ProcessingResult(
                  recognitionResult: _recognitionResult,
                  speechRecognitionAvailable:
                      widget.speechRecognitionController != null,
                  remoteAudioEnabled: widget.enableRemoteAudioUpload,
                  audioUploaded: _audioReference != null,
                  processingError: _processingError,
                  evaluation: _evaluation,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnerPlaybackControl extends StatelessWidget {
  const _LearnerPlaybackControl({
    required this.controlId,
    required this.isPlaying,
    required this.progress,
    required this.enabled,
    required this.onPressed,
  });

  final String controlId;
  final bool isPlaying;
  final double progress;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final clampedProgress = progress.clamp(0.0, 1.0);
    return Semantics(
      label: isPlaying
          ? 'Playing your answer ${(clampedProgress * 100).round()} percent'
          : 'Listen to my answer',
      button: true,
      child: OutlinedButton(
        key: Key('a1-v4-listen-$controlId'),
        onPressed: enabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(
            color: isPlaying ? colors.primary : colors.outlineVariant,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isPlaying ? Icons.stop_circle_outlined : Icons.play_arrow),
            const SizedBox(width: 7),
            Text(isPlaying ? 'Playing your answer' : 'Listen to my answer'),
            if (isPlaying) ...[
              const SizedBox(width: 10),
              SizedBox(
                key: Key('a1-v4-playback-waveform-$controlId'),
                width: 54,
                height: 20,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(8, (index) {
                    final threshold = (index + 1) / 8;
                    final active = clampedProgress >= threshold;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Align(
                          alignment: Alignment.center,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            height: 5.0 + (index % 4) * 3.0,
                            decoration: BoxDecoration(
                              color: active
                                  ? colors.primary
                                  : colors.outlineVariant,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _VoiceControlState { ready, recording, recorded }

class _VoiceRecordControl extends StatelessWidget {
  const _VoiceRecordControl({
    required this.state,
    required this.enabled,
    required this.onPressed,
    required this.actionKey,
    super.key,
  });

  final _VoiceControlState state;
  final bool enabled;
  final VoidCallback? onPressed;
  final Key actionKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEnabled = enabled && onPressed != null;
    final isRecording = state == _VoiceControlState.recording;
    final isRecorded = state == _VoiceControlState.recorded;
    final accent = isRecording ? colors.secondary : colors.primary;
    final label = switch (state) {
      _VoiceControlState.ready => 'Tap to record',
      _VoiceControlState.recording => 'Recording · tap to stop',
      _VoiceControlState.recorded => 'Answer recorded',
    };
    final detail = switch (state) {
      _VoiceControlState.ready => 'Use your own words',
      _VoiceControlState.recording => 'Listening to your voice',
      _VoiceControlState.recorded => 'Ready for feedback',
    };
    final icon = isRecorded
        ? Icons.check_rounded
        : isRecording
        ? Icons.stop_rounded
        : Icons.mic_rounded;

    return Semantics(
      button: isEnabled,
      enabled: isEnabled,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 122,
            height: 122,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isRecording)
                  Container(
                    width: 122,
                    height: 122,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: .28),
                        width: 2,
                      ),
                    ),
                  ),
                Container(
                  width: isRecording ? 104 : 96,
                  height: isRecording ? 104 : 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isRecorded
                        ? colors.tertiary.withValues(alpha: .16)
                        : accent.withValues(alpha: .14),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    key: actionKey,
                    onTap: isEnabled ? onPressed : null,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isRecorded
                            ? null
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [colors.primary, colors.secondary],
                              ),
                        color: isRecorded ? colors.tertiary : null,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: .30),
                            blurRadius: isRecording ? 24 : 18,
                            spreadRadius: isRecording ? 3 : 0,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        size: isRecorded ? 37 : 42,
                        color: isRecorded
                            ? colors.onTertiary
                            : colors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isRecorded ? colors.tertiary : colors.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _A1V4ProductionCapture {
  const _A1V4ProductionCapture({
    required this.controlId,
    required this.recordingId,
    required this.promptId,
    required this.turnId,
    required this.recordingPath,
    this.transcript,
    this.audioReference,
    this.evaluation,
    required this.requiredMeaningTerms,
  });

  final String controlId;
  final String recordingId;
  final String promptId;
  final String turnId;
  final String recordingPath;
  final String? transcript;
  final String? audioReference;
  final SpokenTurnEvaluation? evaluation;
  final List<String> requiredMeaningTerms;
}

class _A1V4ProcessingResult extends StatelessWidget {
  const _A1V4ProcessingResult({
    required this.recognitionResult,
    required this.speechRecognitionAvailable,
    required this.remoteAudioEnabled,
    required this.audioUploaded,
    required this.processingError,
    required this.evaluation,
  });

  final SpeechRecognitionResult? recognitionResult;
  final bool speechRecognitionAvailable;
  final bool remoteAudioEnabled;
  final bool audioUploaded;
  final String? processingError;
  final SpokenTurnEvaluation? evaluation;

  @override
  Widget build(BuildContext context) {
    final transcript = recognitionResult?.transcript?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transcript != null && transcript.isNotEmpty) ...[
            Text(
              'Your words',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: LoguicTheme.indigo),
            ),
            const SizedBox(height: 4),
            Text('“$transcript”'),
          ] else if (!speechRecognitionAvailable)
            const Text(
              'We could not understand that answer yet. Listen and try again.',
            )
          else if (recognitionResult?.status ==
              SpeechRecognitionStatus.noSpeech)
            const Text('No speech was detected. You can listen and try again.')
          else if (recognitionResult?.status == SpeechRecognitionStatus.failed)
            const Text('We could not understand that answer. Try again.')
          else
            const Text('Record your answer to receive feedback.'),
          if (processingError != null) ...[
            const SizedBox(height: 8),
            Text(
              processingError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (evaluation != null) ...[
            const SizedBox(height: 12),
            Text(
              'Feedback ready',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: LoguicTheme.indigo),
            ),
            const SizedBox(height: 4),
            const Text('See your learner feedback alongside this activity.'),
          ] else ...[
            const SizedBox(height: 10),
            const Text('Your feedback will appear here.'),
          ],
        ],
      ),
    );
  }
}

class _A1V4SessionSummary extends StatelessWidget {
  const _A1V4SessionSummary({
    required this.captures,
    required this.audioController,
    required this.remoteAudioEnabled,
    required this.isSaving,
    required this.saved,
    required this.saveError,
    required this.onSave,
  });

  final Map<String, _A1V4ProductionCapture> captures;
  final PronunciationAudioController audioController;
  final bool remoteAudioEnabled;
  final bool isSaving;
  final bool saved;
  final String? saveError;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final items = <(String, String, int)>[
      ('own-production', 'With a little help', 1),
      ('lower-support-own-production', 'Your own way', 2),
      ('nearby-transfer-food', 'A new situation', 3),
    ];
    final allUploaded = items.every(
      (item) => captures[item.$1]?.audioReference != null,
    );

    return Card(
      key: const Key('a1-v4-session-summary'),
      elevation: 0,
      color: colors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.tertiary.withValues(alpha: .32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.tertiary.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: colors.tertiary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your speaking session',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You built confidence, then used your English in a new moment.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            _A1V4SessionProgression(
              labels: items.map((item) => item.$2).toList(),
            ),
            const SizedBox(height: 18),
            for (final item in items)
              if (captures[item.$1] case final capture?) ...[
                _A1V4SummaryRecording(
                  title: item.$2,
                  step: item.$3,
                  capture: capture,
                  audioController: audioController,
                ),
                const SizedBox(height: 12),
              ],
            Divider(color: colors.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'What you practised',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'You moved from helpful words to your own voice, then tried the idea somewhere new.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Text(
              'Keep growing',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _improvementText,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (remoteAudioEnabled) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('a1-v4-save-session'),
                onPressed: allUploaded && !isSaving && !saved ? onSave : null,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        saved
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_upload_outlined,
                      ),
                label: Text(
                  saved ? 'Session saved' : 'Save my speaking session',
                ),
              ),
              if (!allUploaded && !saved) ...[
                const SizedBox(height: 8),
                const Text('Finish each answer to save your full session.'),
              ],
            ],
            if (saveError != null) ...[
              const SizedBox(height: 8),
              Text(
                saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _improvementText {
    final latest =
        captures['nearby-transfer-food']?.evaluation ??
        captures['lower-support-own-production']?.evaluation ??
        captures['own-production']?.evaluation;
    if (latest == null) {
      return 'Your next bit of coaching will appear after feedback on your answers.';
    }
    return latest.comparisonAvailable
        ? latest.improvementEvidence
        : 'Each answer helps you speak with more ease.';
  }
}

class _A1V4SessionProgression extends StatelessWidget {
  const _A1V4SessionProgression({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: colors.tertiary.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              labels[index],
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (index < labels.length - 1)
            Icon(Icons.arrow_forward_rounded, size: 16, color: colors.tertiary),
        ],
      ],
    );
  }
}

class _A1V4SummaryRecording extends StatelessWidget {
  const _A1V4SummaryRecording({
    required this.title,
    required this.step,
    required this.capture,
    required this.audioController,
  });

  final String title;
  final int step;
  final _A1V4ProductionCapture capture;
  final PronunciationAudioController audioController;

  @override
  Widget build(BuildContext context) {
    final transcript = capture.transcript?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.tertiary.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            transcript == null || transcript.isEmpty
                ? 'Your words are not available yet.'
                : 'You said: “$transcript”',
          ),
          if (capture.evaluation != null) ...[
            const SizedBox(height: 6),
            Text('Coach’s note: ${capture.evaluation!.conversationalFeedback}'),
          ] else ...[
            const SizedBox(height: 6),
            const Text('Your coach’s note is not available yet.'),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: Key('a1-v4-summary-play-${capture.controlId}'),
            onPressed: () => audioController.playRecording(
              capture.recordingPath,
              playbackId: 'summary:${capture.recordingId}',
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play my answer'),
          ),
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

class _A1V4ProgressRail extends StatelessWidget {
  const _A1V4ProgressRail({required this.activeStep, this.compact = false});

  final int activeStep;
  final bool compact;

  static const _steps = [
    'Listen',
    'Say it yourself',
    'Your own way',
    'New situation',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A1 · UNIT 1',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.primary,
            letterSpacing: 1.15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '“I need…”',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: compact ? 14 : 24),
        if (compact)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _steps.length,
              (index) => _ProgressPill(
                title: _steps[index],
                completed: index < activeStep,
                active: index == activeStep && activeStep < _steps.length,
              ),
            ),
          )
        else
          ...List.generate(
            _steps.length,
            (index) => _ProgressRailStep(
              title: _steps[index],
              number: index + 1,
              completed: index < activeStep,
              active: index == activeStep && activeStep < _steps.length,
              last: index == _steps.length - 1,
            ),
          ),
      ],
    );
    return Container(
      key: const Key('a1-v4-progress-rail'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _ProgressRailStep extends StatelessWidget {
  const _ProgressRailStep({
    required this.title,
    required this.number,
    required this.completed,
    required this.active,
    required this.last,
  });

  final String title;
  final int number;
  final bool completed;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = completed || active ? colors.primary : colors.outlineVariant;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: completed || active ? color : colors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  completed ? Icons.check : Icons.circle,
                  size: completed ? 17 : 8,
                  color: completed || active ? colors.onPrimary : color,
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2, color: colors.outlineVariant),
                ),
            ],
          ),
          const SizedBox(width: 11),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 5),
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: active ? colors.primary : null,
                fontWeight: active || completed
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({
    required this.title,
    required this.completed,
    required this.active,
  });
  final String title;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completed) Icon(Icons.check, size: 15, color: colors.primary),
          if (completed) const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: active ? colors.onPrimary : null,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _A1V4FeedbackPanel extends StatelessWidget {
  const _A1V4FeedbackPanel({this.capture});

  final _A1V4ProductionCapture? capture;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final evaluation = capture?.evaluation;
    final transcript = capture?.transcript?.trim();
    final received = evaluation != null;
    return Container(
      key: const Key('a1-v4-feedback-panel'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: received
            ? colors.tertiary.withValues(alpha: .10)
            : colors.surfaceContainerLow.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: received
              ? colors.tertiary.withValues(alpha: .42)
              : colors.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            received ? Icons.auto_awesome : Icons.flag_outlined,
            color: received ? colors.tertiary : colors.primary,
          ),
          const SizedBox(height: 14),
          Text(
            received ? 'Great job!' : 'Your goal',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (!received) ...[
            const Text(
              'Listen closely, then use your own voice to ask for what you need.',
            ),
            const SizedBox(height: 16),
            Text(
              'A short answer is perfect.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            const Text(
              'Your answer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              transcript == null || transcript.isEmpty
                  ? 'Your spoken answer'
                  : '“$transcript”',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            const Text(
              'A little feedback',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(evaluation.conversationalFeedback),
            const SizedBox(height: 16),
            const Text(
              'Next up',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(_nextText(capture!.controlId)),
          ],
        ],
      ),
    );
  }

  String _nextText(String controlId) => switch (controlId) {
    'own-production' => 'Now say it your own way.',
    'lower-support-own-production' => 'Try the same idea in a new situation.',
    _ => 'You completed your speaking session.',
  };
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RIGHT NOW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'You are thirsty. Ask for water.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
