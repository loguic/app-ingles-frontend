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

class _DirectSourceContext {
  const _DirectSourceContext({
    required this.sourceId,
    required this.activityId,
    required this.stageId,
    required this.prompts,
    required this.isV3,
  });

  final String sourceId;
  final String activityId;
  final String stageId;
  final List<LearnerProductionPrompt> prompts;
  final bool isV3;
}

class _DirectSourceState {
  DirectEnglishPublicSourceRecord? source;
  final Map<String, DirectEnglishCapture> captures = {};
  final Map<String, String> text = {};
  final Map<String, String> recordingPaths = {};
  bool starting = false;
  bool finalizing = false;
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
  static const _orderedDirectFunctions = <String>[
    'guided',
    'expanded',
    'transfer',
  ];
  static const _directFunctions = <String>{'guided', 'expanded', 'transfer'};

  ApiService get _apiService => widget.apiService ?? _defaultApiService;
  LessonExperience get _experience => widget.lesson.experience!;

  ExperienceAttemptRecord? _attempt;
  final Map<String, _DirectSourceState> _directStateBySource = {};
  final Map<String, bool> _comprehensionFeedback = {};
  final Set<String> _submittingComprehension = {};
  final Set<String> _revealedSpanishSupport = {};
  bool _starting = true;
  bool _refreshing = false;
  bool _refreshPending = false;
  String? _recordingDirectSourceId;
  String? _recordingDirectFunction;
  String? _errorMessage;
  bool _snapshotStale = false;
  int _identityGeneration = 0;

  String get _identity =>
      '${widget.userId}|${widget.levelId}|${widget.unitId}|${widget.lesson.id}';

  bool get _usesV3DirectEnglish =>
      _experience.contractVersion == '3.0' &&
      _experience.pedagogicalMethod == 'direct_english_construction';

  String? get _legacyDirectAttemptId =>
      _attempt == null ? null : 'direct-english:${_attempt!.attemptId}';

  bool get _usesStrictV3SupportTiming => _experience.contractVersion == '3.0';

  bool _isTimingSatisfied(String? requiredExerciseId) {
    return !_usesStrictV3SupportTiming ||
        requiredExerciseId == null ||
        (_attempt?.submittedComprehensionExerciseIds.contains(
              requiredExerciseId,
            ) ??
            false);
  }

  bool _isTranscriptTimingSatisfied(Conversation conversation) {
    return _isTimingSatisfied(
      conversation
          .audioFirstPolicy
          ?.transcriptRevealAfterFirstResponseToExerciseId,
    );
  }

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
    if (_recordingDirectSourceId != null) {
      unawaited(widget.audioService.cancelRecording());
    }
    for (final state in _directStateBySource.values) {
      for (final path in state.recordingPaths.values) {
        unawaited(widget.audioService.deleteRecording(path));
      }
    }
    _directStateBySource.clear();
    _comprehensionFeedback.clear();
    _submittingComprehension.clear();
    _revealedSpanishSupport.clear();
    _recordingDirectSourceId = null;
    _recordingDirectFunction = null;
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
    if (_isCurrentAttemptOperation(generation, attemptId) && _refreshPending) {
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
    final authoritativeIds =
        _attempt?.evidenceStates
            .map((state) => state.evidenceDefinitionId)
            .toSet() ??
        const <String>{};
    return _evidenceForStage(
      stageId,
    ).where((evidence) => authoritativeIds.contains(evidence.id)).toList();
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

  _DirectSourceState _directStateFor(String sourceId) {
    return _directStateBySource.putIfAbsent(sourceId, _DirectSourceState.new);
  }

  bool _isDirectEvidence(LessonExperienceEvidenceDefinition evidence) {
    return evidence.evidenceType == 'guided_production' ||
        evidence.evidenceType == 'contextual_response';
  }

  _DirectSourceContext? _activeV3DirectSource() {
    final current = _attempt;
    if (current == null || current.isCompleted) {
      return null;
    }
    final definitionsById = {
      for (final definition in _experience.evidenceDefinitions)
        definition.id: definition,
    };
    for (final state in current.evidenceStates) {
      if (state.status == 'satisfied') {
        continue;
      }
      final definition = definitionsById[state.evidenceDefinitionId];
      if (definition == null || !_isDirectEvidence(definition)) {
        continue;
      }
      final stages = _experience.stages
          .where((stage) => stage.id == definition.stageId)
          .toList();
      if (stages.length != 1 ||
          !stages.single.activityIds.contains(definition.activityId)) {
        return null;
      }
      final conversations = widget.lesson.conversations
          .where((conversation) => conversation.id == definition.activityId)
          .toList();
      if (conversations.length != 1) {
        return null;
      }
      final promptsByFunction = <String, LearnerProductionPrompt>{};
      for (final turn in conversations.single.turns) {
        final prompt = turn.productionPrompt;
        final function = prompt?.productionFunction;
        if (prompt == null ||
            function == null ||
            !_directFunctions.contains(function)) {
          continue;
        }
        if (promptsByFunction.containsKey(function)) {
          return null;
        }
        promptsByFunction[function] = prompt;
      }
      if (promptsByFunction.length != _orderedDirectFunctions.length ||
          !promptsByFunction.keys.toSet().containsAll(_directFunctions)) {
        return null;
      }
      return _DirectSourceContext(
        sourceId:
            'direct-english:${current.attemptId}:${definition.activityId}',
        activityId: definition.activityId,
        stageId: definition.stageId,
        prompts: [
          for (final function in _orderedDirectFunctions)
            promptsByFunction[function]!,
        ],
        isV3: true,
      );
    }
    return null;
  }

  _DirectSourceContext? _directSourceForStage(LessonExperienceStage stage) {
    if (_usesV3DirectEnglish) {
      final source = _activeV3DirectSource();
      return source?.stageId == stage.id ? source : null;
    }
    final prompt = _directPromptForStage(stage);
    final sourceId = _legacyDirectAttemptId;
    if (prompt == null ||
        sourceId == null ||
        prompt.productionFunction == null) {
      return null;
    }
    return _DirectSourceContext(
      sourceId: sourceId,
      activityId: stage.id,
      stageId: stage.id,
      prompts: [prompt],
      isV3: false,
    );
  }

  bool _hasV3DirectEvidence(LessonExperienceStage stage) {
    return _authoritativeEvidenceForStage(
          stage.id,
        ).where(_isDirectEvidence).length ==
        1;
  }

  bool _hasV3ConversationCompletionEvidence(LessonExperienceStage stage) {
    return _authoritativeEvidenceForStage(stage.id)
            .where((item) => item.evidenceType == 'conversation_completion')
            .length ==
        1;
  }

  bool _v3DirectEvidenceSatisfied() {
    if (!_usesV3DirectEnglish) {
      return true;
    }
    final stateById = {
      for (final state in _attempt?.evidenceStates ?? const [])
        state.evidenceDefinitionId: state,
    };
    final directDefinitions = _experience.evidenceDefinitions
        .where(_isDirectEvidence)
        .toList();
    return directDefinitions.length == 2 &&
        directDefinitions.every(
          (definition) => stateById[definition.id]?.status == 'satisfied',
        );
  }

  bool _isCurrentDirectOperation(
    int generation,
    String attemptId,
    String sourceId,
  ) {
    if (!_isCurrentAttemptOperation(generation, attemptId)) {
      return false;
    }
    if (!_usesV3DirectEnglish) {
      return sourceId == _legacyDirectAttemptId;
    }
    return _activeV3DirectSource()?.sourceId == sourceId;
  }

  String _directWidgetKey(
    _DirectSourceContext source,
    String productionFunction,
    String suffix,
  ) {
    if (!source.isV3) {
      return 'direct-english-$productionFunction-$suffix';
    }
    return 'direct-english-${source.activityId}-$productionFunction-$suffix';
  }

  bool _hasExactConversationEvidence(
    LessonExperienceStage stage,
    Conversation conversation,
  ) {
    final evidence = _authoritativeEvidenceForStage(
      stage.id,
    ).where((item) => item.activityId == conversation.id).toList();
    final usesProductionSubmission =
        conversation.mode == 'free' &&
        conversation.audioFirstPolicy != null &&
        conversation.turns.any(
          (turn) => turn.productionPrompt?.required ?? false,
        );

    if (!usesProductionSubmission) {
      return evidence
              .where((item) => item.evidenceType == 'conversation_completion')
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

  Future<bool> _ensureDirectSource(_DirectSourceContext context) async {
    final current = _attempt;
    if (current == null || current.isCompleted) {
      return false;
    }
    final state = _directStateFor(context.sourceId);
    if (state.source != null) {
      return state.source!.experienceAttemptId == current.attemptId &&
          state.source!.directEnglishAttemptId == context.sourceId;
    }
    if (state.starting) {
      return false;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    setState(() {
      state.starting = true;
      _errorMessage = null;
    });
    try {
      final source = await _apiService.startDirectEnglishConstructionAttempt(
        experienceAttemptId: attemptId,
        directEnglishAttemptId: context.sourceId,
      );
      if (!_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        return false;
      }
      if (source == null ||
          source.experienceAttemptId != attemptId ||
          source.directEnglishAttemptId != context.sourceId) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la producción en inglés.';
        });
        return false;
      }
      setState(() {
        state.source = source;
      });
      return true;
    } catch (_) {
      if (_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la producción en inglés.';
        });
      }
      return false;
    } finally {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          state.starting = false;
        });
      }
    }
  }

  Future<void> _saveDirectText(
    _DirectSourceContext context,
    String productionFunction,
  ) async {
    final state = _directStateFor(context.sourceId);
    final response = state.text[productionFunction]?.trim();
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
    if (!await _ensureDirectSource(context) ||
        !_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
      return;
    }
    setState(() {
      state.captures[productionFunction] = DirectEnglishCapture.text(
        productionFunction: productionFunction,
        responseText: response,
      );
      _errorMessage = null;
    });
  }

  Future<void> _startDirectRecording(
    _DirectSourceContext context,
    String productionFunction,
  ) async {
    final current = _attempt;
    if (current == null || _recordingDirectSourceId != null) {
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    if (!await _ensureDirectSource(context) ||
        !_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
      return;
    }
    try {
      final allowed = await widget.audioService.hasMicrophonePermission();
      if (!allowed) {
        if (_isCurrentDirectOperation(
          generation,
          attemptId,
          context.sourceId,
        )) {
          setState(() {
            _errorMessage = 'No se concedió permiso para usar el micrófono.';
          });
        }
        return;
      }
      await widget.audioService.startRecording(
        'direct:${context.sourceId}:$productionFunction',
      );
      if (!_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        unawaited(widget.audioService.cancelRecording());
        return;
      }
      setState(() {
        _recordingDirectSourceId = context.sourceId;
        _recordingDirectFunction = productionFunction;
        _errorMessage = null;
      });
    } catch (_) {
      if (_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la grabación.';
        });
      }
    }
  }

  Future<void> _stopDirectRecording(
    _DirectSourceContext context,
    String productionFunction,
  ) async {
    if (_recordingDirectSourceId != context.sourceId ||
        _recordingDirectFunction != productionFunction) {
      return;
    }
    final current = _attempt;
    if (current == null) {
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    final state = _directStateFor(context.sourceId);
    try {
      final path = await widget.audioService.stopRecording();
      if (!_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        if (path != null) {
          unawaited(widget.audioService.deleteRecording(path));
        }
        return;
      }
      setState(() {
        _recordingDirectSourceId = null;
        _recordingDirectFunction = null;
        if (path != null) {
          state.recordingPaths[productionFunction] = path;
        }
      });
      if (path == null) {
        setState(() {
          _errorMessage = 'No se pudo crear una grabación utilizable.';
        });
        return;
      }
      await _uploadDirectRecording(
        context,
        productionFunction,
        path,
        expectedAttemptId: attemptId,
        expectedGeneration: generation,
      );
    } catch (_) {
      if (_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        setState(() {
          _recordingDirectSourceId = null;
          _recordingDirectFunction = null;
          _errorMessage = 'No se pudo detener correctamente la grabación.';
        });
      }
    }
  }

  Future<void> _uploadDirectRecording(
    _DirectSourceContext context,
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
        !_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
      return;
    }
    final state = _directStateFor(context.sourceId);
    try {
      final reference = await _apiService.uploadConversationProductionAudio(
        path,
      );
      if (!_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        return;
      }
      if (reference == null) {
        setState(() {
          _errorMessage = 'No se pudo subir el audio. Puedes reintentarlo.';
        });
        return;
      }
      setState(() {
        state.captures[productionFunction] = DirectEnglishCapture.voice(
          productionFunction: productionFunction,
          audioReference: reference,
        );
        state.recordingPaths.remove(productionFunction);
        _errorMessage = null;
      });
      await widget.audioService.deleteRecording(path);
    } catch (_) {
      if (_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        setState(() {
          _errorMessage = 'No se pudo subir el audio. Puedes reintentarlo.';
        });
      }
    }
  }

  Future<void> _finalizeDirectSource(_DirectSourceContext context) async {
    final current = _attempt;
    final state = _directStateFor(context.sourceId);
    if (current == null || current.isCompleted || state.finalizing) {
      return;
    }
    if (!_directFunctions.every(state.captures.containsKey)) {
      setState(() {
        _errorMessage = 'Completa las tres producciones antes de enviarlas.';
      });
      return;
    }
    final generation = _identityGeneration;
    final attemptId = current.attemptId;
    if (!await _ensureDirectSource(context) ||
        !_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
      return;
    }
    setState(() {
      state.finalizing = true;
      _errorMessage = null;
    });
    try {
      final source = await _apiService.finalizeDirectEnglishConstructionAttempt(
        experienceAttemptId: attemptId,
        directEnglishAttemptId: context.sourceId,
        captures: [
          for (final function in _orderedDirectFunctions)
            state.captures[function]!,
        ],
      );
      if (!_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        return;
      }
      if (source == null ||
          source.experienceAttemptId != attemptId ||
          source.directEnglishAttemptId != context.sourceId) {
        setState(() {
          _errorMessage =
              'No se pudieron enviar las producciones. Puedes reintentarlo.';
        });
        return;
      }
      setState(() {
        state.source = source;
      });
      await _refreshAttempt(
        expectedAttemptId: attemptId,
        expectedGeneration: generation,
      );
    } catch (_) {
      if (_isCurrentDirectOperation(generation, attemptId, context.sourceId)) {
        setState(() {
          _errorMessage =
              'No se pudieron enviar las producciones. Puedes reintentarlo.';
        });
      }
    } finally {
      if (_isCurrentAttemptOperation(generation, attemptId)) {
        setState(() {
          state.finalizing = false;
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
                    _isTimingSatisfied(
                      support.spanishRevealAfterFirstResponseToExerciseId,
                    ) &&
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
                    _isTimingSatisfied(
                      support.spanishRevealAfterFirstResponseToExerciseId,
                    ) &&
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
              transcriptTimingSatisfied: _isTranscriptTimingSatisfied(
                conversation,
              ),
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
        final canBind =
            _hasExactConversationEvidence(stage, conversation) &&
            _v3DirectEvidenceSatisfied();
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
            transcriptTimingSatisfied: _isTranscriptTimingSatisfied(
              conversation,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDirectProduction(
    _DirectSourceContext context,
    LearnerProductionPrompt prompt,
  ) {
    final productionFunction = prompt.productionFunction;
    if (productionFunction == null) {
      return const Text(
        'No se encontró una producción autoritativa compatible para esta etapa.',
      );
    }
    final state = _directStateFor(context.sourceId);
    final capture = state.captures[productionFunction];
    final recording =
        _recordingDirectSourceId == context.sourceId &&
        _recordingDirectFunction == productionFunction;
    final pendingPath = state.recordingPaths[productionFunction];
    final transferPrompt = productionFunction == 'transfer'
        ? state.source?.transferPrompt
        : null;
    final allowActions =
        !(_attempt?.isCompleted ?? true) && state.source?.status != 'finalized';

    return Column(
      key: Key(_directWidgetKey(context, productionFunction, 'capture')),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (transferPrompt != null) Text(transferPrompt),
        if (prompt.acceptedModalities.contains('text')) ...[
          TextField(
            key: Key(_directWidgetKey(context, productionFunction, 'text')),
            enabled: allowActions,
            decoration: const InputDecoration(
              labelText: 'Escribe tu respuesta',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => state.text[productionFunction] = value,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: Key(
              _directWidgetKey(context, productionFunction, 'save-text'),
            ),
            onPressed: allowActions
                ? () => _saveDirectText(context, productionFunction)
                : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar respuesta de texto'),
          ),
        ],
        if (prompt.acceptedModalities.contains('voice')) ...[
          const SizedBox(height: 8),
          FilledButton.icon(
            key: Key(_directWidgetKey(context, productionFunction, 'record')),
            onPressed: !allowActions
                ? null
                : recording
                ? () => _stopDirectRecording(context, productionFunction)
                : _recordingDirectSourceId == null
                ? () => _startDirectRecording(context, productionFunction)
                : null,
            icon: Icon(recording ? Icons.stop_circle_outlined : Icons.mic_none),
            label: Text(recording ? 'Detener grabación' : 'Grabar respuesta'),
          ),
        ],
        if (pendingPath != null) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _uploadDirectRecording(
              context,
              productionFunction,
              pendingPath,
            ),
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

  Widget _buildDirectProductionGroup(LessonExperienceStage stage) {
    final context = _directSourceForStage(stage);
    if (context == null) {
      if (_usesV3DirectEnglish && _hasV3DirectEvidence(stage)) {
        return const Text(
          'Completa la producción anterior antes de continuar.',
        );
      }
      return const Text(
        'No se encontró una producción autoritativa compatible para esta etapa.',
      );
    }
    return KeyedSubtree(
      key: ValueKey('direct-source:${context.sourceId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final prompt in context.prompts)
            _buildDirectProduction(context, prompt),
        ],
      ),
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

    if (_usesV3DirectEnglish) {
      if (_hasV3ConversationCompletionEvidence(stage)) {
        return _buildConversationStage(stage);
      }
      if (_hasV3DirectEvidence(stage)) {
        return _buildDirectProductionGroup(stage);
      }
    }

    return switch (stage.type) {
      'encounter' => _buildEncounter(stage),
      'comprehension' => _buildComprehension(stage),
      'language_support' => _buildLanguageSupport(stage),
      'guided_production' || 'applied_conversation' || 'evidence'
          when _experience.pedagogicalMethod == 'direct_english_construction' =>
        _buildDirectProductionGroup(stage),
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
    _DirectSourceContext? sourceContext;
    if (_usesV3DirectEnglish) {
      sourceContext = _activeV3DirectSource();
    } else {
      for (final stage in _experience.stages) {
        sourceContext = _directSourceForStage(stage);
        if (sourceContext != null) {
          break;
        }
      }
    }
    if (sourceContext == null) {
      return const SizedBox.shrink();
    }
    final state = _directStateFor(sourceContext.sourceId);
    final allCaptured = _directFunctions.every(state.captures.containsKey);
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
              key: Key(
                sourceContext.isV3
                    ? 'direct-english-${sourceContext.activityId}-finalize'
                    : 'direct-english-finalize',
              ),
              onPressed:
                  allCaptured &&
                      !state.finalizing &&
                      !(_attempt?.isCompleted ?? true) &&
                      state.source?.status != 'finalized'
                  ? () => _finalizeDirectSource(sourceContext!)
                  : null,
              child: Text(
                state.finalizing ? 'Enviando...' : 'Enviar producciones',
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
