/// Represents an English learning level.
/// Representa un nivel de aprendizaje de inglés.
class Level {
  const Level({
    required this.code,
  });

  /// Level code, for example A1, A2, B1, B2, C1 or C2.
  /// Código del nivel, por ejemplo A1, A2, B1, B2, C1 o C2.
  final String code;

  /// Creates a Level from a backend string value.
  /// Crea un Level desde un valor de texto recibido del backend.
  factory Level.fromString(String code) {
    return Level(code: code);
  }
}