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
    required this.en,
    required this.es,
    this.pronunciations = const [],
  });

  final String en;
  final String es;

  /// Available regional pronunciations for this example sentence.
  /// Pronunciaciones regionales disponibles para esta frase de ejemplo.
  final List<LessonPronunciation> pronunciations;

  factory LessonExample.fromJson(Map<String, dynamic> json) {
    final pronunciations = json['pronunciations'] as List<dynamic>? ?? [];

    return LessonExample(
      en: json['en'] as String,
      es: json['es'] as String,
      pronunciations: pronunciations
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
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
  });

  final String id;
  final String speaker;
  final String en;
  final String? es;
  final List<LessonPronunciation> pronunciations;

  bool get isPartner => speaker == "partner";
  bool get isLearner => speaker == "learner";

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    final pronunciations = json["pronunciations"] as List<dynamic>? ?? [];

    return ConversationTurn(
      id: json["id"] as String,
      speaker: json["speaker"] as String,
      en: json["en"] as String,
      es: json["es"] as String?,
      pronunciations: pronunciations
          .cast<Map<String, dynamic>>()
          .map(LessonPronunciation.fromJson)
          .toList(),
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
    this.turns = const [],
  });

  final String id;
  final String title;
  final String? context;
  final String mode;
  final List<ConversationTurn> turns;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final turns = json["turns"] as List<dynamic>? ?? [];

    return Conversation(
      id: json["id"] as String,
      title: json["title"] as String,
      context: json["context"] as String?,
      mode: json["mode"] as String? ?? "guided",
      turns: turns
          .cast<Map<String, dynamic>>()
          .map(ConversationTurn.fromJson)
          .toList(),
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
  });

  final String id;
  final String title;
  final String? objective;
  final List<String> vocabulary;
  final List<String> grammar;
  final List<LessonExample> examples;
  final List<Conversation> conversations;
  final List<LessonExercise> exercises;

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
    );
  }
}
