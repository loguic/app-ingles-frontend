import 'package:app_ingles/models/conversation_attempt_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a persisted branching conversation attempt', () {
    final record = ConversationAttemptRecord.fromJson({
      'user_id': 'demo-user',
      'level_id': 'A1',
      'unit_id': 'a1-u1',
      'lesson_id': 'a1-u1-l1',
      'conversation_id': 'a1-u1-l1-c2',
      'mode': 'branching',
      'visited_turn_ids': [
        'a1-u1-l1-c2-t1',
        'a1-u1-l1-c2-t2',
        'a1-u1-l1-c2-t3',
      ],
      'selected_choice_ids': ['a1-u1-l1-c2-choice-fine'],
      'completed_at': '2026-07-21T23:53:34.997436+02:00',
    });

    expect(record.userId, 'demo-user');
    expect(record.levelId, 'A1');
    expect(record.unitId, 'a1-u1');
    expect(record.lessonId, 'a1-u1-l1');
    expect(record.conversationId, 'a1-u1-l1-c2');
    expect(record.mode, 'branching');
    expect(record.visitedTurnIds, [
      'a1-u1-l1-c2-t1',
      'a1-u1-l1-c2-t2',
      'a1-u1-l1-c2-t3',
    ]);
    expect(record.selectedChoiceIds, ['a1-u1-l1-c2-choice-fine']);
    expect(
      record.completedAt,
      DateTime.parse('2026-07-21T23:53:34.997436+02:00'),
    );
  });
}
