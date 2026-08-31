import 'dart:async';

import 'package:flutter/material.dart';

import '../models/experience_attempt.dart';
import '../models/lesson.dart';
import '../services/api_service.dart';
import '../services/pronunciation_audio_service.dart';
import '../services/speech_recognition_service.dart';
import 'info_card.dart';
import 'lesson_conversation_card.dart';
import 'lesson_pronunciation_controls.dart';

/// Renders one backend-authored LessonExperience in its declared stage order.
class LessonExperienceCard extends StatefulWidget {
  const LessonExperienceCard({
    required this.lesson,
    required this.levelId,
    required this.unitId,
    required this.userId,
    required this.audioService,
    this.apiService,
    this.speechRecognitionController,
    super.key,
  });

  final Lesson lesson;
  final String levelId;
  final String unitId;
  final String userId;
  final PronunciationAudioController audioService;
  final ApiService? apiService;
  final SpeechRecognitionController? speechRecognitionController;

  @override
  State<LessonExperienceCard> createState() => _LessonExperienceCardState();
}

class _LessonExperienceCardState extends State<LessonExperienceCard> {
  static final ApiService _defaultApiService = ApiService();
  static const _supportedStageTypes = <String>{
    'encounter',
    'comprehension',
    'language_support',
    'guided_production',
    'applied_conversation',
    'evidence',
    'closure',
  };
  static const _directFunctions = <String>{'guided', 'expanded', 'transfer'};

  ApiService get _apiService => widget.apiService ?? _defaultApiService;
  LessonExperience get _experience => widget.lesson.experience!;

  ExperienceAttemptRecord? _attempt;
  DirectEnglishPublicSourceRecord? _directSource;
  final Map<String, DirectEnglishCapture> _directCaptures = {};
  final Map<String, String> _directText = {};
  final Map<String, String> _directRecordingPaths = {};
  final Map<String, bool> _comprehensionFeedback = {};
  final Set<String> _submittingComprehension = {};
  final Set<String> _revealedSpanishSupport = {};
  bool _starting = true;
  bool _refreshing = false;
  bool _refreshPending = false;
  bool _startingDirect = false;
  bool _finalizingDirect = false;
  String? _recordingDirectFunction;
  String? _errorMessage;
  bool _snapshotStale = false;
  int _identityGeneration = 0;

  String get _identity =>
      '${widget.userId}|${widget.levelId}|${widget.unitId}|${widget.lesson.id}';

  String? get _stableDirectAttemptId =>
      _attempt == null ? null : 'direct-english:${_attempt!.attemptId}';

  @override
  void initState() {
    super.initState();
    unawaited(_startOrResume(_identityGeneration));
  }

  @override
  void didUpdateWidget(covariant LessonExperienceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIdentity =
        '${oldWidget.userId}|${oldWidget.levelId}|${oldWidget.unitId}|'
        '${oldWidget.lesson.id}';
    if (oldIdentity == _identity) {
      return;
    }

    _identityGeneration += 1;
    _discardAttemptLocalState();
    setState(() {
      _attempt = null;
      _starting = true;
      _refreshing = false;
      _refreshPending = false;
      _errorMessage = null;
      _snapshotStale = false;
    });
    unawaited(_startOrResume(_identityGeneration));
  }

  @override
  void dispose() {
    _discardAttemptLocalState();
    super.dispose();
  }

  void _discardAttemptLocalState() {
    if (_recordingDirectFunction != null) {
      unawaited(widget.audioService.cancelRecording());
    }
    for (final path in _directRecordingPaths.values) {
      unawaited(widget.audioService.deleteRecording(path));
    }
    _directSource = null;
    _directCaptures.clear();
    _directText.clear();
    _directRecordingPaths.clear();
    _comprehensionFeedback.clear();
    _submittingComprehension.clear();
    _revealedSpanishSupport.clear();
    _recordingDirectFunction = null;
    _startingDirect = false;
    _finalizingDirect = false;
  }

  Future<void> _startOrResume(int generation) async {
    try {
      final record = await _apiService.startOrResumeExperienceAttempt(
        userId: widget.userId,
        levelId: widget.levelId,
        unitId: widget.unitId,
        lessonId: widget.lesson.id,
      );
      if (!mounted || generation != _identityGeneration) {
        return;
      }
      setState(() {
        _attempt = record;
        _starting = false;
        _snapshotStale = false;
        _errorMessage = record == null
            ? 'No se pudo iniciar la experiencia.'
            : null;
      });
    } catch (_) {
      if (!mounted || generation != _identityGeneration) {
        return;
      }
      setState(() {
        _starting = false;
        _errorMessage = 'No se pudo iniciar la experiencia.';
      });
    }
  }

  Future<void> _retryStart() async {
    if (_starting) {
      return;
    }
    setState(() {
      _starting = true;
      _errorMessage = null;
    });
    await _startOrResume(_identityGeneration);
  }

  bool _isCurrentAttemptOperation(int generation, String attemptId) {
    return mounted &&
        generation == _identityGeneration &&
        _attempt?.attemptId == attemptId;
  }

  Future<void> _refreshAttempt({
    String? expectedAttemptId,
    int? expectedGeneration,
  }) async {
    final current = _attempt;
    if (current == null) {
      return;
    }
    final attemptId = expectedAttemptId ?? current.attemptId;
    final generation = expectedGeneration ?? _identityGeneration;
    if (current.attemptId != attemptId ||
        !_isCurrentAttemptOperation(generation, attemptId)) {
      return;
    }
    if (_refreshing) {
      _refreshPending = true;
      return;
    }
    setState(() {
      _refreshing = true;
      _errorMessage = null;
    });
    try {
      final refreshed = await _apiService.getExperienceAttempt(
        current.attemptId,
      );
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        return;
      }
      setState(() {
        _refreshing = false;
        if (refreshed == null) {
          _snapshotStale = true;
          _errorMessage =
              'No se pudo actualizar el estado. Se muestra el último estado confirmado.';
        } else {
          _attempt = refreshed;
          _snapshotStale = false;
        }
      });
    } catch (_) {
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        return;
      }
      setState(() {
        _refreshing = false;
        _snapshotStale = true;
        _errorMessage =
            'No se pudo actualizar el estado. Se muestra el último estado confirmado.';
      });
    }
    if (_isCurrentAttemptOperation(generation, attemptId) &&
        _refreshPending) {
      _refreshPending = false;
      await _refreshAttempt(
        expectedAttemptId: attemptId,
        expectedGeneration: generation,
      );
    }
  }

  List<LessonExperienceLanguageSupport> _supportForStage(String stageId) {
    return _experience.languageSupport
        .where((support) => support.stageIds.contains(stageId))
        .toList();
  }

  List<LessonExperienceEvidenceDefinition> _evidenceForStage(String stageId) {
    return _experience.evidenceDefinitions
        .where((evidence) => evidence.stageId == stageId)
        .toList();
  }

  List<LessonExperienceEvidenceDefinition> _authoritativeEvidenceForStage(
    String stageId,
  ) {
    final authoritativeIds = _attempt?.evidenceStates
            .map((state) => state.evidenceDefinitionId)
            .toSet() ??
        const <String>{};
    return _evidenceForStage(stageId)
        .where((evidence) => authoritativeIds.contains(evidence.id))
        .toList();
  }

  List<Conversation> _conversationsForStage(LessonExperienceStage stage) {
    return widget.lesson.conversations
        .where((conversation) => stage.activityIds.contains(conversation.id))
        .toList();
  }

  LessonExercise? _exerciseById(String exerciseId) {
    for (final exercise in widget.lesson.exercises) {
      if (exercise.id == exerciseId) {
        return exercise;
      }
    }
    return null;
  }

  LearnerProductionPrompt? _directPromptForStage(LessonExperienceStage stage) {
    final evidence = _authoritativeEvidenceForStage(stage.id);
    for (final conversation in _conversationsForStage(stage)) {
      final mapped = evidence
          .where(
            (item) =>
                item.activityId == conversation.id &&
                (item.evidenceType == 'guided_production' ||
                    item.evidenceType == 'contextual_response'),
          )
          .toList();
      if (mapped.isEmpty) {
        continue;
      }
      for (final turn in conversation.turns) {
        final prompt = turn.productionPrompt;
        if (prompt != null &&
            mapped.any(
              (item) =>
                  item.productionPromptId == null ||
                  item.productionPromptId == prompt.id,
            ) &&
            prompt.productionFunction != null &&
            _directFunctions.contains(prompt.productionFunction)) {
          return prompt;
        }
      }
    }
    return null;
  }

  bool _hasExactConversationEvidence(
    LessonExperienceStage stage,
    Conversation conversation,
  ) {
    final evidence = _authoritativeEvidenceForStage(stage.id)
        .where((item) => item.activityId == conversation.id)
        .toList();
    final usesProductionSubmission =
        conversation.mode == 'free' &&
        conversation.audioFirstPolicy != null &&
        conversation.turns.any(
          (turn) => turn.productionPrompt?.required ?? false,
        );

    if (!usesProductionSubmission) {
      return evidence
              .where(
                (item) => item.evidenceType == 'conversation_completion',
              )
              .length ==
          1;
    }

    final requiredPromptIds = conversation.turns
        .map((turn) => turn.productionPrompt)
        .whereType<LearnerProductionPrompt>()
        .where((prompt) => prompt.required)
        .map((prompt) => prompt.id)
        .toSet();
    final contextual = evidence
        .where(
          (item) =>
              item.evidenceType == 'contextual_response' &&
              item.productionPromptId != null,
        )
        .toList();
    final mappedPromptIds = contextual
        .map((item) => item.productionPromptId!)
        .toSet();

    return requiredPromptIds.isNotEmpty &&
        contextual.length == requiredPromptIds.length &&
        mappedPromptIds.length == contextual.length &&
        mappedPromptIds.containsAll(requiredPromptIds);
  }

  Future<void> _submitComprehension(
    LessonExercise exercise,
    int selectedIndex,
  ) async {
    final current = _attempt;
    if (current == null || current.isCompleted) {
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    setState(() {
      _submittingComprehension.add(exercise.id);
      _errorMessage = null;
    });
    try {
      final response = await _apiService.submitExperienceComprehensionResponse(
        attemptId: current.attemptId,
        comprehensionExerciseId: exercise.id,
        selectedIndex: selectedIndex,
      );
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        return;
      }
      if (response == null ||
          response.experienceAttemptId != attemptId ||
          response.comprehensionExerciseId != exercise.id) {
        setState(() {
          _errorMessage = 'No se pudo guardar la respuesta de comprensión.';
        });
        return;
      }
      setState(() {
        _comprehensionFeedback[exercise.id] = response.isCorrect;
      });
      await _refreshAttempt(
        expectedAttemptId: attemptId,
        expectedGeneration: generation,
      );
    } catch (_) {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _errorMessage = 'No se pudo guardar la respuesta de comprensión.';
        });
      }
    } finally {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _submittingComprehension.remove(exercise.id);
        });
      }
    }
  }

  Future<bool> _ensureDirectSource() async {
    final current = _attempt;
    final stableId = _stableDirectAttemptId;
    if (current == null || stableId == null || current.isCompleted) {
      return false;
    }
    if (_directSource != null) {
      return _directSource!.experienceAttemptId == current.attemptId;
    }
    if (_startingDirect) {
      return false;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    setState(() {
      _startingDirect = true;
      _errorMessage = null;
    });
    try {
      final source = await _apiService.startDirectEnglishConstructionAttempt(
        experienceAttemptId: current.attemptId,
        directEnglishAttemptId: stableId,
      );
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        return false;
      }
      if (source == null ||
          source.experienceAttemptId != attemptId ||
          source.directEnglishAttemptId != stableId) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la producción en inglés.';
        });
        return false;
      }
      setState(() {
        _directSource = source;
      });
      return true;
    } catch (_) {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la producción en inglés.';
        });
      }
      return false;
    } finally {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _startingDirect = false;
        });
      }
    }
  }

  Future<void> _saveDirectText(String productionFunction) async {
    final response = _directText[productionFunction]?.trim();
    if (response == null || response.isEmpty) {
      setState(() {
        _errorMessage = 'Escribe una respuesta antes de guardarla.';
      });
      return;
    }
    final current = _attempt;
    if (current == null) {
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    if (!await _ensureDirectSource() ||
        !_isCurrentAttemptOperation(generation, attemptId)) {
      return;
    }
    setState(() {
      _directCaptures[productionFunction] = DirectEnglishCapture.text(
        productionFunction: productionFunction,
        responseText: response,
      );
      _errorMessage = null;
    });
  }

  Future<void> _startDirectRecording(String productionFunction) async {
    final current = _attempt;
    if (current == null || _recordingDirectFunction != null) {
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    if (!await _ensureDirectSource() ||
        !_isCurrentAttemptOperation(generation, attemptId)) {
      return;
    }
    try {
      final allowed = await widget.audioService.hasMicrophonePermission();
      if (!allowed) {
        if (_isCurrentAttemptOperation(generation, attemptId)) {
          setState(() {
            _errorMessage = 'No se concedió permiso para usar el micrófono.';
          });
        }
        return;
      }
      await widget.audioService.startRecording(
        'direct:$attemptId:$productionFunction',
      );
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        unawaited(widget.audioService.cancelRecording());
        return;
      }
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _recordingDirectFunction = productionFunction;
          _errorMessage = null;
        });
      }
    } catch (_) {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la grabación.';
        });
      }
    }
  }

  Future<void> _stopDirectRecording(String productionFunction) async {
    if (_recordingDirectFunction != productionFunction) {
      return;
    }
    final current = _attempt;
    if (current == null) {
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    try {
      final path = await widget.audioService.stopRecording();
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        if (path != null) {
          unawaited(widget.audioService.deleteRecording(path));
        }
        return;
      }
      setState(() {
        _recordingDirectFunction = null;
        if (path != null) {
          _directRecordingPaths[productionFunction] = path;
        }
      });
      if (path == null) {
        setState(() {
          _errorMessage = 'No se pudo crear una grabación utilizable.';
        });
        return;
      }
      await _uploadDirectRecording(
        productionFunction,
        path,
        expectedAttemptId: attemptId,
        expectedGeneration: generation,
      );
    } catch (_) {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _recordingDirectFunction = null;
          _errorMessage = 'No se pudo detener correctamente la grabación.';
        });
      }
    }
  }

  Future<void> _uploadDirectRecording(
    String productionFunction,
    String path, {
    String? expectedAttemptId,
    int? expectedGeneration,
  }) async {
    final current = _attempt;
    if (current == null) {
      return;
    }
    final attemptId = expectedAttemptId ?? current.attemptId;
    final generation = expectedGeneration ?? _identityGeneration;
    if (current.attemptId != attemptId ||
        !_isCurrentAttemptOperation(generation, attemptId)) {
      return;
    }
    try {
      final reference = await _apiService.uploadConversationProductionAudio(
        path,
      );
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        return;
      }
      if (reference == null) {
        setState(() {
          _errorMessage = 'No se pudo subir el audio. Puedes reintentarlo.';
        });
        return;
      }
      setState(() {
        _directCaptures[productionFunction] = DirectEnglishCapture.voice(
          productionFunction: productionFunction,
          audioReference: reference,
        );
        _directRecordingPaths.remove(productionFunction);
        _errorMessage = null;
      });
      await widget.audioService.deleteRecording(path);
    } catch (_) {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _errorMessage = 'No se pudo subir el audio. Puedes reintentarlo.';
        });
      }
    }
  }

  Future<void> _finalizeDirectSource() async {
    final current = _attempt;
    if (current == null || current.isCompleted || _finalizingDirect) {
      return;
    }
    if (!_directFunctions.every(_directCaptures.containsKey)) {
      setState(() {
        _errorMessage = 'Completa las tres producciones antes de enviarlas.';
      });
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    if (!await _ensureDirectSource() ||
        !_isCurrentAttemptOperation(generation, attemptId)) {
      return;
    }
    setState(() {
      _finalizingDirect = true;
      _errorMessage = null;
    });
    try {
      final source = await _apiService.finalizeDirectEnglishConstructionAttempt(
        experienceAttemptId: attemptId,
        directEnglishAttemptId: _directSource!.directEnglishAttemptId,
        captures: const [
          'guided',
          'expanded',
          'transfer',
        ].map((item) => _directCaptures[item]!).toList(),
      );
      if (!_isCurrentAttemptOperation(generation, attemptId)) {
        return;
      }
      if (source == null || source.experienceAttemptId != attemptId) {
        setState(() {
          _errorMessage =
              'No se pudieron enviar las producciones. Puedes reintentarlo.';
        });
        return;
      }
      setState(() {
        _directSource = source;
      });
      await _refreshAttempt(
        expectedAttemptId: attemptId,
        expectedGeneration: generation,
      );
    } catch (_) {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _errorMessage =
              'No se pudieron enviar las producciones. Puedes reintentarlo.';
        });
      }
    } finally {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          _finalizingDirect = false;
        });
      }
    }
  }

  String _stageTitle(String type) {
    return switch (type) {
      'encounter' => 'Contexto y escucha',
      'comprehension' => 'Comprensión',
      'language_support' => 'Apoyo de idioma',
      'guided_production' => 'Producción guiada',
      'applied_conversation' => 'Interacción',
      'evidence' => 'Misión final',
      'closure' => 'Cierre',
      _ => 'Contenido no compatible',
    };
  }

  String _evidenceTypeLabel(String type) {
    return switch (type) {
      'comprehension_result' => 'Comprensión',
      'contextual_response' => 'Respuesta contextual',
      'guided_production' => 'Producción guiada',
      'conversation_completion' => 'Conversación',
      _ => 'Evidencia',
    };
  }

  String _evidenceStatusLabel(String status) {
    return switch (status) {
      'pending' => 'Por practicar',
      'needs_review' => 'En revisión',
      'satisfied' => 'Conseguido',
      _ => 'Estado no disponible',
    };
  }

  Widget _buildLanguageSupport(LessonExperienceStage stage) {
    final supportItems = _supportForStage(stage.id);
    if (supportItems.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        ...supportItems.map(
          (support) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  support.en,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (support.usageNote != null) Text(support.usageNote!),
                if (support.es != null &&
                    !_revealedSpanishSupport.contains(support.id))
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _revealedSpanishSupport.add(support.id);
                      });
                    },
                    icon: const Icon(Icons.translate),
                    label: const Text('Necesito apoyo en español'),
                  ),
                if (support.es != null &&
                    _revealedSpanishSupport.contains(support.id))
                  Text(support.es!),
                if (support.pronunciations.isNotEmpty)
                  LessonPronunciationControls(
                    exampleId: 'experience-support:${support.id}',
                    pronunciations: support.pronunciations,
                    audioService: widget.audioService,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEncounter(LessonExperienceStage stage) {
    final conversations = _conversationsForStage(stage);
    final reinforcement = _experience.pronunciationReinforcement;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...conversations.map(
          (conversation) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LessonConversationCard(
              conversation: conversation,
              levelId: widget.levelId,
              unitId: widget.unitId,
              lessonId: widget.lesson.id,
              userId: widget.userId,
              audioService: widget.audioService,
              apiService: _apiService,
              speechRecognitionController: widget.speechRecognitionController,
              persistencePolicy: ConversationPersistencePolicy.disabled,
            ),
          ),
        ),
        if (reinforcement != null &&
            reinforcement.stageId == stage.id &&
            reinforcement.pronunciations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(reinforcement.listeningObjective),
          const SizedBox(height: 8),
          Text(
            reinforcement.referenceText,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          LessonPronunciationControls(
            exampleId: 'experience-reinforcement:${stage.id}',
            pronunciations: reinforcement.pronunciations,
            audioService: widget.audioService,
          ),
        ],
      ],
    );
  }

  Widget _buildComprehension(LessonExperienceStage stage) {
    final definitions = _authoritativeEvidenceForStage(
      stage.id,
    ).where((item) => item.evidenceType == 'comprehension_result').toList();
    if (definitions.isEmpty) {
      return const Text(
        'No hay una evaluación de comprensión vinculada a esta etapa.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: definitions.map((definition) {
        final exerciseId = definition.comprehensionExerciseId;
        final exercise = exerciseId == null ? null : _exerciseById(exerciseId);
        if (exercise == null) {
          return const Text(
            'No se pudo cargar la actividad de comprensión vinculada.',
          );
        }
        final submitting = _submittingComprehension.contains(exercise.id);
        final feedback = _comprehensionFeedback[exercise.id];
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            key: Key('experience-comprehension-${exercise.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.prompt,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...exercise.options.indexed.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: OutlinedButton(
                    key: Key(
                      'experience-comprehension-${exercise.id}-option-${entry.$1}',
                    ),
                    onPressed: submitting || (_attempt?.isCompleted ?? true)
                        ? null
                        : () => _submitComprehension(exercise, entry.$1),
                    child: Text(entry.$2),
                  ),
                ),
              ),
              if (submitting) const LinearProgressIndicator(),
              if (feedback != null)
                Text(
                  feedback
                      ? 'Respuesta correcta.'
                      : 'Respuesta guardada. Puedes volver a intentarlo.',
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConversationStage(LessonExperienceStage stage) {
    final conversations = _conversationsForStage(stage);
    if (conversations.isEmpty) {
      return const Text('No hay una conversación vinculada a esta etapa.');
    }
    return Column(
      children: conversations.map((conversation) {
        final canBind = _hasExactConversationEvidence(stage, conversation);
        final attemptId = canBind && !(_attempt?.isCompleted ?? true)
            ? _attempt?.attemptId
            : null;
        final bindingGeneration = _identityGeneration;
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: LessonConversationCard(
            conversation: conversation,
            levelId: widget.levelId,
            unitId: widget.unitId,
            lessonId: widget.lesson.id,
            userId: widget.userId,
            audioService: widget.audioService,
            apiService: _apiService,
            speechRecognitionController: widget.speechRecognitionController,
            persistencePolicy: attemptId == null
                ? ConversationPersistencePolicy.disabled
                : ConversationPersistencePolicy.inherited,
            experienceAttemptId: attemptId,
            onAuthoritativeSourcePersisted: attemptId == null
                ? null
                : () => _refreshAttempt(
                    expectedAttemptId: attemptId,
                    expectedGeneration: bindingGeneration,
                  ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDirectProduction(LessonExperienceStage stage) {
    final prompt = _directPromptForStage(stage);
    final productionFunction = prompt?.productionFunction;
    if (prompt == null || productionFunction == null) {
      return const Text(
        'No se encontró una producción autoritativa compatible para esta etapa.',
      );
    }
    final capture = _directCaptures[productionFunction];
    final recording = _recordingDirectFunction == productionFunction;
    final pendingPath = _directRecordingPaths[productionFunction];
    final transferPrompt = productionFunction == 'transfer'
        ? _directSource?.transferPrompt
        : null;
    final allowActions =
        !(_attempt?.isCompleted ?? true) &&
        _directSource?.status != 'finalized';

    return Column(
      key: Key('direct-english-$productionFunction'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (transferPrompt != null) Text(transferPrompt),
        if (prompt.acceptedModalities.contains('text')) ...[
          TextField(
            key: Key('direct-english-$productionFunction-text'),
            enabled: allowActions,
            decoration: const InputDecoration(
              labelText: 'Escribe tu respuesta',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => _directText[productionFunction] = value,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: Key('direct-english-$productionFunction-save-text'),
            onPressed: allowActions
                ? () => _saveDirectText(productionFunction)
                : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar respuesta de texto'),
          ),
        ],
        if (prompt.acceptedModalities.contains('voice')) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            key: Key('direct-english-$productionFunction-record'),
            onPressed: !allowActions
                ? null
                : recording
                ? () => _stopDirectRecording(productionFunction)
                : _recordingDirectFunction == null
                ? () => _startDirectRecording(productionFunction)
                : null,
            icon: Icon(recording ? Icons.stop_circle_outlined : Icons.mic_none),
            label: Text(recording ? 'Detener grabación' : 'Grabar respuesta'),
          ),
        ],
        if (pendingPath != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                _uploadDirectRecording(productionFunction, pendingPath),
            child: const Text('Reintentar subida de audio'),
          ),
        ],
        if (capture != null) ...[
          const SizedBox(height: 8),
          Text(
            'Producción preparada (${capture.modality == 'voice' ? 'voz' : 'texto'}).',
          ),
        ],
      ],
    );
  }

  Widget _buildStageBody(LessonExperienceStage stage) {
    if (!_supportedStageTypes.contains(stage.type)) {
      return Text(
        'Esta etapa (${stage.type}) todavía no es compatible. '
        'No se enviará ninguna evidencia.',
        key: Key('unsupported-experience-stage-${stage.id}'),
      );
    }

    return switch (stage.type) {
      'encounter' => _buildEncounter(stage),
      'comprehension' => _buildComprehension(stage),
      'language_support' => _buildLanguageSupport(stage),
      'guided_production' || 'applied_conversation' || 'evidence'
          when _experience.pedagogicalMethod == 'direct_english_construction' =>
        _buildDirectProduction(stage),
      'guided_production' ||
      'applied_conversation' ||
      'evidence' => _buildConversationStage(stage),
      'closure' => Text(
        _attempt?.isCompleted == true
            ? 'La experiencia está completada según el backend.'
            : 'El cierre no completa la experiencia por sí solo.',
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildStage(LessonExperienceStage stage, int index) {
    return Card(
      key: Key('experience-stage-${stage.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${_stageTitle(stage.type)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(stage.instruction),
            _buildStageBody(stage),
            if (stage.type != 'language_support') _buildLanguageSupport(stage),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceState() {
    final evidenceStates = _attempt?.evidenceStates ?? const [];
    if (evidenceStates.isEmpty) {
      return const SizedBox.shrink();
    }
    return InfoCard(
      title: 'Tu recorrido',
      child: Column(
        children: evidenceStates
            .map(
              (evidence) => ListTile(
                key: Key(
                  'experience-evidence-${evidence.evidenceDefinitionId}',
                ),
                contentPadding: EdgeInsets.zero,
                title: Text(_evidenceTypeLabel(evidence.evidenceType)),
                trailing: Text(_evidenceStatusLabel(evidence.status)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildDirectFinalizePanel() {
    if (_experience.pedagogicalMethod != 'direct_english_construction') {
      return const SizedBox.shrink();
    }
    final allCaptured = _directFunctions.every(_directCaptures.containsKey);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enviar producciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Envía las respuestas guiada, ampliada y de transferencia juntas.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('direct-english-finalize'),
              onPressed:
                  allCaptured &&
                      !_finalizingDirect &&
                      !(_attempt?.isCompleted ?? true) &&
                      _directSource?.status != 'finalized'
                  ? _finalizeDirectSource
                  : null,
              child: Text(
                _finalizingDirect ? 'Enviando...' : 'Enviar producciones',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_starting) {
      return const InfoCard(
        title: 'Experiencia',
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_attempt == null) {
      return InfoCard(
        title: 'Experiencia',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_errorMessage ?? 'No se pudo iniciar la experiencia.'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _retryStart,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return Column(
      key: const Key('lesson-experience-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InfoCard(
          title: _experience.mission.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_experience.mission.situation),
              const SizedBox(height: 8),
              Text(_experience.mission.observableOutcome),
              if (_attempt!.isCompleted) ...[
                const SizedBox(height: 12),
                const Text(
                  '¡Experiencia completada!',
                  key: Key('experience-completed'),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        _buildEvidenceState(),
        if (_refreshing) const LinearProgressIndicator(),
        if (_snapshotStale)
          const Text(
            'El estado mostrado puede estar desactualizado.',
            key: Key('experience-stale-state'),
          ),
        if (_errorMessage != null) ...[
          Text(_errorMessage!, key: const Key('experience-error')),
          if (_snapshotStale)
            TextButton(
              onPressed: _refreshAttempt,
              child: const Text('Reintentar actualización'),
            ),
        ],
        KeyedSubtree(
          key: ValueKey('experience-identity:$_identity'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ..._experience.stages.indexed.map(
                (entry) => _buildStage(entry.$2, entry.$1),
              ),
              _buildDirectFinalizePanel(),
            ],
          ),
        ),
      ],
    );
  }
}
