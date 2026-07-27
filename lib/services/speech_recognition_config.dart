/// Holds external configuration required by speech recognition.
/// Mantiene la configuración externa necesaria para el reconocimiento de voz.
class SpeechRecognitionConfig {
  const SpeechRecognitionConfig._();

  /// Directory containing the external Sherpa-ONNX model artifacts.
  /// Directorio que contiene los artefactos externos del modelo Sherpa-ONNX.
  static const String modelDirectory = String.fromEnvironment(
    "APP_INGLES_STT_MODEL_DIR",
  );

  /// Indicates whether a model directory was provided at launch time.
  /// Indica si se proporcionó un directorio de modelo al iniciar la app.
  static bool get isConfigured => modelDirectory.trim().isNotEmpty;
}
