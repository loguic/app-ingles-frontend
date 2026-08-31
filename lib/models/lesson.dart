/// Represents one regional pronunciation of an English sentence.
/// Representa una pronunciación regional de una frase en inglés.
class LessonPronunciation {
  const LessonPronunciation({
    required this.locale,
    required this.ipa,
    required this.audioAsset,
  });

  /// Regional English locale, such as en-US or en-GB.
  /// Variante regional de inglés, como en-US o en-GB.
  final String locale;

  /// International Phonetic Alphabet transcription.
  /// Transcripción en el Alfabeto Fonético Internacional.
  final String ipa;

  /// Local audio asset matching this pronunciation variant.
  /// Recurso de audio local correspondiente a esta variante.
  final String audioAsset;

  factory LessonPronunciation.fromJson(Map<String, dynamic> json) {
    return LessonPronunciation(
      locale: json['locale'] as String,
      ipa: json['ipa'] as String,
      audioAsset: json['audio_asset'] as String,
    );
  }
}

/// Represents an example sentence inside a lesson.
/// Representa una frase de ejemplo dentro de una lección.
class LessonExample {
  const LessonExample({
    required this.id,
    required this.en,
    required this.es,
    this.pronunciations = const [],
  });

  final String id;
  final String en;
  final String es;

  /// Available regional pronunciations for this example sentence.
  /// Pronunciaciones regionales disponibles para esta frase de ejemplo.
  final List<LessonPronunciation> pronunciations;

  factory LessonExample.fromJson(Map<String, dynamic> json) {
    final pronunciations = json['pronunciations'] as List<dynamic>? ?? [];

    return LessonExample(
      id: json['id'] as String,
      en: json['en'] as String,
      es: json['es'] as String,
      pronunciations: pronunciations
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
    );
  }
}

/// Represents one selectable learner response inside a conversation.
/// Representa una respuesta seleccionable del estudiante dentro de una conversación.
class ConversationChoice {
  const ConversationChoice({
    required this.id,
    required this.en,
    this.es,
    this.pronunciations = const [],
    this.nextTurnId,
  });

  final String id;
  final String en;
  final String? es;
  final List<LessonPronunciation> pronunciations;
  final String? nextTurnId;

  factory ConversationChoice.fromJson(Map<String, dynamic> json) {
    final pronunciations = json["pronunciations"] as List<dynamic>? ?? [];

    return ConversationChoice(
      id: json["id"] as String,
      en: json["en"] as String,
      es: json["es"] as String?,
      pronunciations: pronunciations
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
      nextTurnId: json["next_turn_id"] as String?,
    );
  }
}

/// Defines how one learner turn accepts personal production.
/// Define cómo un turno del estudiante acepta producción personal.
class LearnerProductionPrompt {
  const LearnerProductionPrompt({
    required this.id,
    required this.acceptedModalities,
    this.required = true,
    this.productionFunction,
    this.primaryModality,
    this.fallbackModalities = const [],
    this.supportLevel,
    this.visibleSupport = const [],
    this.allowFullAnswerModel,
  });

  final String id;
  final List<String> acceptedModalities;
  final bool required;
  final String? productionFunction;
  final String? primaryModality;
  final List<String> fallbackModalities;
  final String? supportLevel;
  final List<String> visibleSupport;
  final bool? allowFullAnswerModel;

  factory LearnerProductionPrompt.fromJson(Map<String, dynamic> json) {
    final modalities = json["accepted_modalities"] as List<dynamic>? ?? [];

    return LearnerProductionPrompt(
      id: json["id"] as String,
      acceptedModalities: modalities.cast<String>(),
      required: json["required"] as bool? ?? true,
      productionFunction: json["production_function"] as String?,
      primaryModality: json["primary_modality"] as String?,
      fallbackModalities: (json["fallback_modalities"] as List<dynamic>? ?? [])
          .cast<String>(),
      supportLevel: json["support_level"] as String?,
      visibleSupport: (json["visible_support"] as List<dynamic>? ?? [])
          .cast<String>(),
      allowFullAnswerModel: json["allow_full_answer_model"] as bool?,
    );
  }
}

/// Represents one turn inside a conversational activity.
/// Representa un turno dentro de una actividad conversacional.
class ConversationTurn {
  const ConversationTurn({
    required this.id,
    required this.speaker,
    required this.en,
    this.es,
    this.pronunciations = const [],
    this.productionPrompt,
    this.nextTurnId,
    this.choices = const [],
    this.interactionFunction,
  });

  final String id;
  final String speaker;
  final String en;
  final String? es;
  final List<LessonPronunciation> pronunciations;
  final LearnerProductionPrompt? productionPrompt;
  final String? nextTurnId;
  final List<ConversationChoice> choices;
  final String? interactionFunction;

  bool get isPartner => speaker == "partner";
  bool get isLearner => speaker == "learner";
  bool get hasChoices => choices.isNotEmpty;

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    final pronunciations = json["pronunciations"] as List<dynamic>? ?? [];
    final choices = json["choices"] as List<dynamic>? ?? [];

    return ConversationTurn(
      id: json["id"] as String,
      speaker: json["speaker"] as String,
      en: json["en"] as String,
      es: json["es"] as String?,
      pronunciations: pronunciations
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
      productionPrompt: json["production_prompt"] == null
          ? null
          : LearnerProductionPrompt.fromJson(
              json["production_prompt"] as Map<String, dynamic>,
            ),
      nextTurnId: json["next_turn_id"] as String?,
      choices: choices
          .cast<Map<String, dynamic>>()
          .map(ConversationChoice.fromJson)
          .toList(),
      interactionFunction: json["interaction_function"] as String?,
    );
  }
}

/// Controls audio-first delivery while keeping transcript use exceptional.
class AudioFirstPresentationPolicy {
  const AudioFirstPresentationPolicy({
    required this.primaryPresentation,
    required this.audioReplayAllowed,
    required this.transcriptInitiallyHidden,
    required this.transcriptAccess,
    required this.transcriptUseInterpretation,
    required this.transcriptIsAnswerModel,
  });

  final String primaryPresentation;
  final bool audioReplayAllowed;
  final bool transcriptInitiallyHidden;
  final String transcriptAccess;
  final String transcriptUseInterpretation;
  final bool transcriptIsAnswerModel;

  factory AudioFirstPresentationPolicy.fromJson(Map<String, dynamic> json) {
    return AudioFirstPresentationPolicy(
      primaryPresentation: json["primary_presentation"] as String,
      audioReplayAllowed: json["audio_replay_allowed"] as bool,
      transcriptInitiallyHidden: json["transcript_initially_hidden"] as bool,
      transcriptAccess: json["transcript_access"] as String,
      transcriptUseInterpretation:
          json["transcript_use_interpretation"] as String,
      transcriptIsAnswerModel: json["transcript_is_answer_model"] as bool,
    );
  }
}

/// Represents one complete conversational activity.
/// Representa una actividad conversacional completa.
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    this.context,
    this.mode = "guided",
    this.startTurnId,
    this.turns = const [],
    this.audioFirstPolicy,
  });

  final String id;
  final String title;
  final String? context;
  final String mode;
  final String? startTurnId;
  final List<ConversationTurn> turns;
  final AudioFirstPresentationPolicy? audioFirstPolicy;

  /// Finds a turn by its stable identifier.
  /// Busca un turno mediante su identificador estable.
  ConversationTurn? turnById(String? turnId) {
    if (turnId == null) {
      return null;
    }

    for (final turn in turns) {
      if (turn.id == turnId) {
        return turn;
      }
    }

    return null;
  }

  /// Resolves the declared start turn while preserving guided compatibility.
  /// Resuelve el turno inicial declarado conservando compatibilidad guiada.
  ConversationTurn? get initialTurn {
    if (turns.isEmpty) {
      return null;
    }

    return startTurnId == null ? turns.first : turnById(startTurnId);
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final turns = json["turns"] as List<dynamic>? ?? [];

    return Conversation(
      id: json["id"] as String,
      title: json["title"] as String,
      context: json["context"] as String?,
      mode: json["mode"] as String? ?? "guided",
      startTurnId: json["start_turn_id"] as String?,
      turns: turns
          .cast<Map<String, dynamic>>()
          .map(ConversationTurn.fromJson)
          .toList(),
      audioFirstPolicy: json["audio_first_policy"] == null
          ? null
          : AudioFirstPresentationPolicy.fromJson(
              json["audio_first_policy"] as Map<String, dynamic>,
            ),
    );
  }
}

/// Represents an exercise inside a lesson.
/// Representa un ejercicio dentro de una lección.
class LessonExercise {
  const LessonExercise({
    required this.id,
    required this.type,
    required this.prompt,
    required this.options,
    required this.answerIndex,
    required this.skillIds,
  });

  final String id;
  final String type;
  final String prompt;
  final List<String> options;
  final int answerIndex;
  final List<String> skillIds;

  factory LessonExercise.fromJson(Map<String, dynamic> json) {
    return LessonExercise(
      id: json['id'] as String,
      type: json['type'] as String,
      prompt: json['prompt'] as String,
      options: (json['options'] as List<dynamic>).cast<String>(),
      answerIndex: json['answer_index'] as int,
      skillIds: (json['skill_ids'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Describes the communicative outcome presented by a v2 lesson experience.
class LessonExperienceMission {
  const LessonExperienceMission({
    required this.title,
    required this.situation,
    required this.observableOutcome,
    required this.successCriteria,
  });

  final String title;
  final String situation;
  final String observableOutcome;
  final List<String> successCriteria;

  factory LessonExperienceMission.fromJson(Map<String, dynamic> json) {
    return LessonExperienceMission(
      title: json['title'] as String,
      situation: json['situation'] as String,
      observableOutcome: json['observable_outcome'] as String,
      successCriteria: (json['success_criteria'] as List<dynamic>)
          .cast<String>(),
    );
  }
}

/// One backend-ordered stage of a v2 lesson experience.
class LessonExperienceStage {
  const LessonExperienceStage({
    required this.id,
    required this.type,
    required this.instruction,
    required this.activityIds,
    required this.mode,
    required this.completionCondition,
  });

  final String id;

  /// Kept verbatim so unknown backend values remain visible to the renderer.
  final String type;
  final String instruction;
  final List<String> activityIds;
  final String mode;
  final String completionCondition;

  factory LessonExperienceStage.fromJson(Map<String, dynamic> json) {
    return LessonExperienceStage(
      id: json['id'] as String,
      type: json['type'] as String,
      instruction: json['instruction'] as String,
      activityIds: (json['activity_ids'] as List<dynamic>? ?? [])
          .cast<String>(),
      mode: json['mode'] as String,
      completionCondition: json['completion_condition'] as String,
    );
  }
}

/// Language support associated with one or more experience stages.
class LessonExperienceLanguageSupport {
  const LessonExperienceLanguageSupport({
    required this.id,
    required this.type,
    required this.en,
    required this.stageIds,
    this.es,
    this.usageNote,
    this.pronunciations = const [],
  });

  final String id;
  final String type;
  final String en;
  final String? es;
  final String? usageNote;
  final List<LessonPronunciation> pronunciations;
  final List<String> stageIds;

  factory LessonExperienceLanguageSupport.fromJson(Map<String, dynamic> json) {
    final pronunciations = json['pronunciations'] as List<dynamic>? ?? [];

    return LessonExperienceLanguageSupport(
      id: json['id'] as String,
      type: json['type'] as String,
      en: json['en'] as String,
      es: json['es'] as String?,
      usageNote: json['usage_note'] as String?,
      pronunciations: pronunciations
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
      stageIds: (json['stage_ids'] as List<dynamic>).cast<String>(),
    );
  }
}

/// Defines the source mapping required by the v2 runtime UI.
class LessonExperienceEvidenceDefinition {
  const LessonExperienceEvidenceDefinition({
    required this.id,
    required this.stageId,
    required this.activityId,
    required this.evidenceType,
    this.productionPromptId,
    this.comprehensionExerciseId,
  });

  final String id;
  final String stageId;
  final String activityId;
  final String evidenceType;
  final String? productionPromptId;
  final String? comprehensionExerciseId;

  factory LessonExperienceEvidenceDefinition.fromJson(
    Map<String, dynamic> json,
  ) {
    return LessonExperienceEvidenceDefinition(
      id: json['id'] as String,
      stageId: json['stage_id'] as String,
      activityId: json['activity_id'] as String,
      evidenceType: json['evidence_type'] as String,
      productionPromptId: json['production_prompt_id'] as String?,
      comprehensionExerciseId: json['comprehension_exercise_id'] as String?,
    );
  }
}

/// Optional listen-and-shadow preparation attached to one stage.
class LessonPronunciationReinforcement {
  const LessonPronunciationReinforcement({
    required this.stageId,
    required this.referenceText,
    required this.listeningObjective,
    required this.shadowing,
    required this.pronunciations,
    required this.phoneticTargets,
  });

  final String stageId;
  final String referenceText;
  final String listeningObjective;
  final bool shadowing;
  final List<LessonPronunciation> pronunciations;
  final List<String> phoneticTargets;

  factory LessonPronunciationReinforcement.fromJson(Map<String, dynamic> json) {
    return LessonPronunciationReinforcement(
      stageId: json['stage_id'] as String,
      referenceText: json['reference_text'] as String,
      listeningObjective: json['listening_objective'] as String,
      shadowing: json['shadowing'] as bool? ?? true,
      pronunciations: (json['pronunciations'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
      phoneticTargets: (json['phonetic_targets'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }
}

/// Runtime content contract for a backend-authored lesson experience.
class LessonExperience {
  const LessonExperience({
    required this.contractVersion,
    required this.pedagogicalMethod,
    required this.mission,
    required this.stages,
    required this.languageSupport,
    required this.evidenceDefinitions,
    this.pronunciationReinforcement,
  });

  final String contractVersion;
  final String? pedagogicalMethod;
  final LessonExperienceMission mission;
  final List<LessonExperienceStage> stages;
  final List<LessonExperienceLanguageSupport> languageSupport;
  final List<LessonExperienceEvidenceDefinition> evidenceDefinitions;
  final LessonPronunciationReinforcement? pronunciationReinforcement;

  factory LessonExperience.fromJson(Map<String, dynamic> json) {
    final stages = json['stages'] as List<dynamic>;
    final languageSupport = json['language_support'] as List<dynamic>? ?? [];
    final evidenceDefinitions = json['evidence_definitions'] as List<dynamic>;
    final reinforcement = json['pronunciation_reinforcement'];

    return LessonExperience(
      contractVersion: json['contract_version'] as String,
      pedagogicalMethod: json['pedagogical_method'] as String?,
      mission: LessonExperienceMission.fromJson(
        json['mission'] as Map<String, dynamic>,
      ),
      stages: stages
          .cast<Map<String, dynamic>>()
          .map(LessonExperienceStage.fromJson)
          .toList(),
      languageSupport: languageSupport
          .cast<Map<String, dynamic>>()
          .map(LessonExperienceLanguageSupport.fromJson)
          .toList(),
      evidenceDefinitions: evidenceDefinitions
          .cast<Map<String, dynamic>>()
          .map(LessonExperienceEvidenceDefinition.fromJson)
          .toList(),
      pronunciationReinforcement: reinforcement == null
          ? null
          : LessonPronunciationReinforcement.fromJson(
              reinforcement as Map<String, dynamic>,
            ),
    );
  }
}

/// Represents a lesson inside a learning unit.
/// Representa una lección dentro de una unidad de aprendizaje.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    this.objective,
    required this.vocabulary,
    required this.grammar,
    required this.examples,
    this.conversations = const [],
    required this.exercises,
    this.experience,
  });

  final String id;
  final String title;
  final String? objective;
  final List<String> vocabulary;
  final List<String> grammar;
  final List<LessonExample> examples;
  final List<Conversation> conversations;
  final List<LessonExercise> exercises;
  final LessonExperience? experience;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final examples = json['examples'] as List<dynamic>? ?? [];
    final conversations = json['conversations'] as List<dynamic>? ?? [];
    final exercises = json['exercises'] as List<dynamic>? ?? [];

    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      objective: json['objective'] as String?,
      vocabulary: (json['vocabulary'] as List<dynamic>? ?? []).cast<String>(),
      grammar: (json['grammar'] as List<dynamic>? ?? []).cast<String>(),
      examples: examples
          .cast<Map<String, dynamic>>()
          .map(LessonExample.fromJson)
          .toList(),
      conversations: conversations
          .cast<Map<String, dynamic>>()
          .map(Conversation.fromJson)
          .toList(),
      exercises: exercises
          .cast<Map<String, dynamic>>()
          .map(LessonExercise.fromJson)
          .toList(),
      experience: json['experience'] == null
          ? null
          : LessonExperience.fromJson(
              json['experience'] as Map<String, dynamic>,
            ),
    );
  }
}
