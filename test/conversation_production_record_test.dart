import 'package:app_ingles/models/conversation_production_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses persisted conversation productions', () {
    final record = ConversationProductionSubmissionRecord.fromJson({
      'user_id': 'demo-user',
      'level_id': 'A1',
      'unit_id': 'a1-u1',
      'lesson_id': 'a1-u1-l1',
      'conversation_id': 'a1-u1-l1-c1',
      'submission_id': 7,
      'submitted_at': '2026-07-26T10:15:00+02:00',
      'productions': [
        {
          'prompt_id': 'prompt-text',
          'turn_id': 'turn-text',
          'modality': 'text',
          'response_text': 'My name is John.',
          'audio_reference': null,
          'production_id': 11,
        },
        {
          'prompt_id': 'prompt-voice',
          'turn_id': 'turn-voice',
          'modality': 'voice',
          'response_text': null,
          'audio_reference': 'stored-audio-reference',
          'production_id': 12,
        },
      ],
    });

    expect(record.submissionId, 7);
    expect(record.submittedAt, DateTime.parse('2026-07-26T10:15:00+02:00'));
    expect(record.productions, hasLength(2));

    expect(record.productions.first.responseText, 'My name is John.');
    expect(record.productions.first.audioReference, isNull);

    expect(record.productions.last.modality, 'voice');
    expect(record.productions.last.audioReference, 'stored-audio-reference');
    expect(record.productions.last.productionId, 12);
  });
}
