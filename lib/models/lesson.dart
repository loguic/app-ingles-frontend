/// Represents a lesson inside a learning unit.
/// Representa una lección dentro de una unidad de aprendizaje.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    this.objective,
  });

  /// Unique lesson identifier, for example a1-u1-l1.
  /// Identificador único de la lección, por ejemplo a1-u1-l1.
  final String id;

  /// Lesson title shown in the user interface.
  /// Título de la lección mostrado en la interfaz.
  final String title;

  /// Learning objective of the lesson.
  /// Objetivo de aprendizaje de la lección.
  final String? objective;

  /// Creates a Lesson from backend JSON data.
  /// Crea una Lesson desde datos JSON del backend.
  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      title: json['title'] as String,
      objective: json['objective'] as String?,
    );
  }
}