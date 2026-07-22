/// Represents one completed and persisted conversation attempt.
/// Representa un intento conversacional completado y persistido.
class ConversationAttemptRecord {
  const ConversationAttemptRecord({
    required this.userId,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.conversationId,
    required this.mode,
    required this.visitedTurnIds,
    required this.selectedChoiceIds,
    required this.completedAt,
  });

  final String userId;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String conversationId;
  final String mode;
  final List<String> visitedTurnIds;
  final List<String> selectedChoiceIds;
  final DateTime completedAt;

  factory ConversationAttemptRecord.fromJson(Map<String, dynamic> json) {
    return ConversationAttemptRecord(
      userId: json["user_id"] as String,
      levelId: json["level_id"] as String,
      unitId: json["unit_id"] as String,
      lessonId: json["lesson_id"] as String,
      conversationId: json["conversation_id"] as String,
      mode: json["mode"] as String,
      visitedTurnIds: List<String>.unmodifiable(
        (json["visited_turn_ids"] as List<dynamic>).cast<String>(),
      ),
      selectedChoiceIds: List<String>.unmodifiable(
        (json["selected_choice_ids"] as List<dynamic>).cast<String>(),
      ),
      completedAt: DateTime.parse(json["completed_at"] as String),
    );
  }
}
