import 'dart:convert';

import 'package:app_ingles/models/experience_attempt.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const attemptPayload = {
  'attempt_id': 'experience-attempt-1',
  'user_id': 'user-1',
  'level_id': 'A1',
  'unit_id': 'a1-u1',
  'lesson_id': 'a1-u1-l1',
  'experience_contract_version': '2.0',
  'status': 'in_progress',
  'started_at': '2026-08-31T10:00:00Z',
  'completed_at': null,
  'evidence_states': <Map<String, dynamic>>[],
};

Map<String, dynamic> decodeBody(http.Request request) {
  return jsonDecode(request.body) as Map<String, dynamic>;
}

void main() {
  test('start and GET use only the authoritative attempt contract', () async {
    final requests = <http.Request>[];
    final service = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(jsonEncode(attemptPayload), 200);
      }),
    );

    final started = await service.startOrResumeExperienceAttempt(
      userId: 'user-1',
      levelId: 'A1',
      unitId: 'a1-u1',
      lessonId: 'a1-u1-l1',
    );
    final refreshed = await service.getExperienceAttempt(
      'experience-attempt-1',
    );

    expect(started?.attemptId, 'experience-attempt-1');
    expect(refreshed?.status, 'in_progress');
    expect(requests[0].method, 'POST');
    expect(requests[0].url.path, '/api/v1/experience-attempts');
    expect(decodeBody(requests[0]), {
      'user_id': 'user-1',
      'level_id': 'A1',
      'unit_id': 'a1-u1',
      'lesson_id': 'a1-u1-l1',
    });
    expect(requests[1].method, 'GET');
    expect(
      requests[1].url.path,
      '/api/v1/experience-attempts/experience-attempt-1',
    );
  });

  test('comprehension sends selected_index and no pedagogical truth', () async {
    late http.Request captured;
    final service = ApiService(
      client: MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'response_id': 'response-1',
            'experience_attempt_id': 'experience-attempt-1',
            'evidence_definition_id': 'backend-evidence',
            'activity_id': 'conversation-1',
            'comprehension_exercise_id': 'exercise-1',
            'selected_index': 1,
            'is_correct': true,
            'submitted_at': '2026-08-31T10:01:00Z',
          }),
          200,
        );
      }),
    );

    final response = await service.submitExperienceComprehensionResponse(
      attemptId: 'experience-attempt-1',
      comprehensionExerciseId: 'exercise-1',
      selectedIndex: 1,
    );

    expect(response?.isCorrect, isTrue);
    expect(
      captured.url.path,
      '/api/v1/experience-attempts/experience-attempt-1/'
      'comprehension-responses/exercise-1',
    );
    expect(decodeBody(captured), {'selected_index': 1});
  });

  test('Direct English start and finalize expose only source facts', () async {
    final requests = <http.Request>[];
    final service = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        final isFinalize = request.url.path.endsWith('/finalize');
        return http.Response(
          jsonEncode({
            'direct_english_attempt_id': 'direct-1',
            'experience_attempt_id': 'experience-attempt-1',
            'status': isFinalize ? 'finalized' : 'started',
            'transfer_variant_id': 'variant-1',
            'transfer_prompt': 'What do you enjoy?',
          }),
          200,
        );
      }),
    );

    await service.startDirectEnglishConstructionAttempt(
      experienceAttemptId: 'experience-attempt-1',
      directEnglishAttemptId: 'direct-1',
    );
    await service.finalizeDirectEnglishConstructionAttempt(
      experienceAttemptId: 'experience-attempt-1',
      directEnglishAttemptId: 'direct-1',
      captures: [
        DirectEnglishCapture.text(
          productionFunction: 'guided',
          responseText: 'I am Alex.',
        ),
        DirectEnglishCapture.voice(
          productionFunction: 'expanded',
          audioReference: 'production-audio://expanded',
        ),
        DirectEnglishCapture.voice(
          productionFunction: 'transfer',
          audioReference: 'production-audio://transfer',
        ),
      ],
    );

    expect(decodeBody(requests[0]), {'attempt_id': 'direct-1'});
    expect(decodeBody(requests[1]), {
      'captures': [
        {
          'production_function': 'guided',
          'modality': 'text',
          'response_text': 'I am Alex.',
        },
        {
          'production_function': 'expanded',
          'modality': 'voice',
          'audio_reference': 'production-audio://expanded',
        },
        {
          'production_function': 'transfer',
          'modality': 'voice',
          'audio_reference': 'production-audio://transfer',
        },
      ],
    });
    final encoded = requests.map((request) => request.body).join();
    for (final forbidden in const [
      'evidence_definition_id',
      'evidence_type',
      'status',
      'completed',
      'mastery',
      'score',
      'prompt_id',
      'support_used',
    ]) {
      expect(encoded, isNot(contains(forbidden)));
    }
  });

  test(
    'conversation bindings are optional and omitted for legacy calls',
    () async {
      final requests = <http.Request>[];
      final service = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
      );

      await service.saveConversationAttempt(
        userId: 'user-1',
        levelId: 'A1',
        unitId: 'a1-u1',
        lessonId: 'a1-u1-l1',
        conversationId: 'conversation-1',
        mode: 'guided',
        visitedTurnIds: const ['turn-1'],
        selectedChoiceIds: const [],
      );
      await service.saveConversationAttempt(
        userId: 'user-1',
        levelId: 'A1',
        unitId: 'a1-u1',
        lessonId: 'a1-u1-l1',
        conversationId: 'conversation-1',
        mode: 'guided',
        visitedTurnIds: const ['turn-1'],
        selectedChoiceIds: const [],
        experienceAttemptId: 'experience-attempt-1',
      );
      await service.saveConversationProductions(
        userId: 'user-1',
        levelId: 'A1',
        unitId: 'a1-u1',
        lessonId: 'a1-u1-l1',
        conversationId: 'conversation-1',
        productions: const [
          {
            'prompt_id': 'prompt-1',
            'turn_id': 'turn-1',
            'modality': 'text',
            'response_text': 'Hello',
          },
        ],
      );
      await service.saveConversationProductions(
        userId: 'user-1',
        levelId: 'A1',
        unitId: 'a1-u1',
        lessonId: 'a1-u1-l1',
        conversationId: 'conversation-1',
        productions: const [
          {
            'prompt_id': 'prompt-1',
            'turn_id': 'turn-1',
            'modality': 'text',
            'response_text': 'Hello',
          },
        ],
        experienceAttemptId: 'experience-attempt-1',
      );

      expect(decodeBody(requests[0]), isNot(contains('experience_attempt_id')));
      expect(
        decodeBody(requests[1])['experience_attempt_id'],
        'experience-attempt-1',
      );
      expect(decodeBody(requests[2]), isNot(contains('experience_attempt_id')));
      expect(
        decodeBody(requests[3])['experience_attempt_id'],
        'experience-attempt-1',
      );
    },
  );
}
