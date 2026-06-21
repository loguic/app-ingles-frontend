/// Represents a learning unit inside an English level.
/// Representa una unidad de aprendizaje dentro de un nivel de inglés.
class Unit {
  const Unit({
    required this.id,
    required this.title,
  });

  /// Unique unit identifier, for example a1-u1.
  /// Identificador único de la unidad, por ejemplo a1-u1.
  final String id;

  /// Unit title shown in the user interface.
  /// Título de la unidad mostrado en la interfaz.
  final String title;

  /// Creates a Unit from backend JSON data.
  /// Crea una Unit desde datos JSON del backend.
  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'] as String,
      title: json['title'] as String,
    );
  }
}