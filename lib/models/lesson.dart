/// Represents an example sentence inside a lesson.
/// Representa una frase de ejemplo dentro de una lección.
class LessonExample {
  const LessonExample({
    required this.en,
    required this.es,
  });

  final String en;
  final String es;

  factory LessonExample.fromJson(Map<String, dynamic> json) {
    return LessonExample(
      en: json['en'] as String,
      es: json['es'] as String,
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
    required this.exercises,
  });

  final String id;
  final String title;
  final String? objective;
  final List<String> vocabulary;
  final List<String> grammar;
  final List<LessonExample> examples;
  final List<LessonExercise> exercises;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final examples = json['examples'] as List<dynamic>? ?? [];
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
      exercises: exercises
          .cast<Map<String, dynamic>>()
          .map(LessonExercise.fromJson)
          .toList(),
    );
  }
}