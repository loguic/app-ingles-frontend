/// Technical outcome of one speech recognition attempt.
/// Resultado técnico de un intento de reconocimiento de voz.
enum SpeechRecognitionStatus {
  recognized,
  noSpeech,
  failed,
}

/// Describes one temporary audio recognition request.
/// Describe una solicitud de reconocimiento sobre audio temporal.
class SpeechRecognitionRequest {
  const SpeechRecognitionRequest({
    required this.audioPath,
    required this.languageCode,
    required this.userId,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.conversationId,
    required this.turnId,
    this.promptId,
    this.locale,
  });

  final String audioPath;
  final String languageCode;
  final String? locale;

  final String userId;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String conversationId;
  final String turnId;
  final String? promptId;
}

/// Represents recognition output without pedagogical evaluation.
/// Representa el reconocimiento sin realizar evaluación pedagógica.
class SpeechRecognitionResult {
  const SpeechRecognitionResult({
    required this.status,
    required this.languageCode,
    required this.userId,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.conversationId,
    required this.turnId,
    this.transcript,
    this.words = const [],
    this.promptId,
    this.locale,
  });

  final SpeechRecognitionStatus status;
  final String? transcript;
  final List<String> words;

  final String languageCode;
  final String? locale;

  final String userId;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String conversationId;
  final String turnId;
  final String? promptId;
}

/// Defines speech recognition independently from the concrete engine.
/// Define el reconocimiento de voz independientemente del motor concreto.
abstract interface class SpeechRecognitionController {
  Future<SpeechRecognitionResult> recognize(
    SpeechRecognitionRequest request,
  );
}
