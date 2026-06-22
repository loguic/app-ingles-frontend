/// Represents a saved user progress record.
/// Representa un registro de progreso guardado del usuario.
class ProgressRecord {
  const ProgressRecord({
    required this.userId,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.exerciseId,
    required this.selectedIndex,
    required this.correct,
  });

  final String userId;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String exerciseId;
  final int selectedIndex;
  final bool correct;

  factory ProgressRecord.fromJson(Map<String, dynamic> json) {
    return ProgressRecord(
      userId: json['user_id'] as String,
      levelId: json['level_id'] as String,
      unitId: json['unit_id'] as String,
      lessonId: json['lesson_id'] as String,
      exerciseId: json['exercise_id'] as String,
      selectedIndex: json['selected_index'] as int,
      correct: json['correct'] as bool,
    );
  }
}