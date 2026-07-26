/// Represents one persisted learner production without evaluating it.
/// Representa una producción persistida del estudiante sin evaluarla.
class LearnerProductionRecord {
  const LearnerProductionRecord({
    required this.promptId,
    required this.turnId,
    required this.modality,
    required this.productionId,
    this.responseText,
    this.audioReference,
  });

  final String promptId;
  final String turnId;
  final String modality;
  final String? responseText;
  final String? audioReference;
  final int productionId;

  factory LearnerProductionRecord.fromJson(Map<String, dynamic> json) {
    return LearnerProductionRecord(
      promptId: json["prompt_id"] as String,
      turnId: json["turn_id"] as String,
      modality: json["modality"] as String,
      responseText: json["response_text"] as String?,
      audioReference: json["audio_reference"] as String?,
      productionId: json["production_id"] as int,
    );
  }
}

/// Represents one persisted conversation production submission.
/// Representa una entrega persistida de producciones conversacionales.
class ConversationProductionSubmissionRecord {
  const ConversationProductionSubmissionRecord({
    required this.userId,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.conversationId,
    required this.submissionId,
    required this.submittedAt,
    required this.productions,
  });

  final String userId;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String conversationId;
  final int submissionId;
  final DateTime submittedAt;
  final List<LearnerProductionRecord> productions;

  factory ConversationProductionSubmissionRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return ConversationProductionSubmissionRecord(
      userId: json["user_id"] as String,
      levelId: json["level_id"] as String,
      unitId: json["unit_id"] as String,
      lessonId: json["lesson_id"] as String,
      conversationId: json["conversation_id"] as String,
      submissionId: json["submission_id"] as int,
      submittedAt: DateTime.parse(json["submitted_at"] as String),
      productions: List<LearnerProductionRecord>.unmodifiable(
        (json["productions"] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(LearnerProductionRecord.fromJson),
      ),
    );
  }
}
