import 'package:app_ingles/models/experience_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> attemptJson({
  String status = 'in_progress',
  String? completedAt,
  List<Map<String, dynamic>>? evidenceStates,
  List<String>? submittedComprehensionExerciseIds,
}) {
  return {
    'attempt_id': 'experience-attempt-1',
    'user_id': 'user-1',
    'level_id': 'A1',
    'unit_id': 'a1-u1',
    'lesson_id': 'a1-u1-l1',
    'experience_contract_version': '2.0',
    'status': status,
    'started_at': '2026-08-31T10:00:00Z',
    'completed_at': completedAt,
    'evidence_states':
        evidenceStates ??
        [
          {
            'evidence_definition_id': 'evidence-1',
            'evidence_type': 'comprehension_result',
            'status': 'pending',
          },
          {
            'evidence_definition_id': 'evidence-2',
            'evidence_type': 'contextual_response',
            'status': 'needs_review',
          },
          {
            'evidence_definition_id': 'evidence-3',
            'evidence_type': 'guided_production',
            'status': 'satisfied',
          },
        ],
    'submitted_comprehension_exercise_ids': ?submittedComprehensionExerciseIds,
  };
}

void main() {
  test('parses authoritative attempt and ordered evidence states', () {
    final record = ExperienceAttemptRecord.fromJson(attemptJson());

    expect(record.attemptId, 'experience-attempt-1');
    expect(record.userId, 'user-1');
    expect(record.experienceContractVersion, '2.0');
    expect(record.status, 'in_progress');
    expect(record.completedAt, isNull);
    expect(record.evidenceStates.map((item) => item.status), [
      'pending',
      'needs_review',
      'satisfied',
    ]);
    expect(record.isCompleted, isFalse);
  });

  test('parses backend completion without deriving it from evidence count', () {
    final record = ExperienceAttemptRecord.fromJson(
      attemptJson(
        status: 'completed',
        completedAt: '2026-08-31T10:05:00Z',
        evidenceStates: const [],
      ),
    );

    expect(record.isCompleted, isTrue);
    expect(record.completedAt, DateTime.utc(2026, 8, 31, 10, 5));
  });

  test('parses submitted comprehension exercise ids as timing facts', () {
    final record = ExperienceAttemptRecord.fromJson(
      attemptJson(
        submittedComprehensionExerciseIds: ['exercise-1', 'exercise-2'],
      ),
    );

    expect(record.submittedComprehensionExerciseIds, {
      'exercise-1',
      'exercise-2',
    });
    expect(
      ExperienceAttemptRecord.fromJson(
        attemptJson(),
      ).submittedComprehensionExerciseIds,
      isEmpty,
    );
  });

  test('parses comprehension source facts including backend correctness', () {
    final record = ExperienceComprehensionResponseRecord.fromJson({
      'response_id': 'response-1',
      'experience_attempt_id': 'experience-attempt-1',
      'evidence_definition_id': 'evidence-1',
      'activity_id': 'conversation-1',
      'comprehension_exercise_id': 'exercise-1',
      'selected_index': 2,
      'is_correct': true,
      'submitted_at': '2026-08-31T10:01:00Z',
    });

    expect(record.selectedIndex, 2);
    expect(record.isCorrect, isTrue);
    expect(record.activityId, 'conversation-1');
  });

  test('parses narrow Direct English public source response', () {
    final record = DirectEnglishPublicSourceRecord.fromJson({
      'direct_english_attempt_id': 'direct-1',
      'experience_attempt_id': 'experience-attempt-1',
      'status': 'started',
      'transfer_variant_id': 'variant-1',
      'transfer_prompt': 'What do you enjoy?',
    });

    expect(record.directEnglishAttemptId, 'direct-1');
    expect(record.status, 'started');
    expect(record.transferPrompt, 'What do you enjoy?');
  });

  test('rejects unknown authoritative lifecycle and evidence statuses', () {
    expect(
      () => ExperienceAttemptRecord.fromJson(attemptJson(status: 'mastered')),
      throwsFormatException,
    );
    expect(
      () => ExperienceAttemptRecord.fromJson(
        attemptJson(
          evidenceStates: const [
            {
              'evidence_definition_id': 'evidence-1',
              'evidence_type': 'guided_production',
              'status': 'passed',
            },
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => DirectEnglishPublicSourceRecord.fromJson({
        'direct_english_attempt_id': 'direct-1',
        'experience_attempt_id': 'experience-attempt-1',
        'status': 'completed',
        'transfer_variant_id': 'variant-1',
        'transfer_prompt': 'What do you enjoy?',
      }),
      throwsFormatException,
    );
  });

  test('rejects malformed required runtime values', () {
    final malformed = attemptJson()..['started_at'] = 'not-a-date';
    expect(
      () => ExperienceAttemptRecord.fromJson(malformed),
      throwsFormatException,
    );
  });
}
