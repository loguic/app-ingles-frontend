import 'dart:convert';

import 'package:app_ingles/models/experience_attempt.dart';
import 'package:app_ingles/models/a1_v4_practice_session.dart';
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

Map<String, dynamic> a1SaveConfirmation({
  String sessionId = 'c1f5d0f0-2117-4a85-8dc2-52da15c6eb18',
  bool saved = true,
  int productionCount = 3,
}) => {
  'session_id': sessionId,
  'practice_session': true,
  'curricular_accreditation': false,
  'practice_completed': true,
  'saved': saved,
  'declared_user_id': 'declared-user',
  'created_at': '2026-11-23T03:13:40Z',
  'saved_at': '2026-11-23T03:14:40Z',
  'productions': const [
    {
      'activity_id': 'own-production',
      'audio_reference': 'production-audio://one',
      'transcript': 'I need water.',
      'client_evaluation': {'semantic_status': 'adequate'},
      'backend_verified_evidence': {'audio_linked_to_session': true},
    },
    {
      'activity_id': 'lower-support-own-production',
      'audio_reference': 'production-audio://two',
      'transcript': 'I need water.',
      'client_evaluation': {'semantic_status': 'adequate'},
      'backend_verified_evidence': {'audio_linked_to_session': true},
    },
    {
      'activity_id': 'nearby-transfer-food',
      'audio_reference': 'production-audio://three',
      'transcript': 'I need food.',
      'client_evaluation': {'semantic_status': 'adequate'},
      'backend_verified_evidence': {'audio_linked_to_session': true},
    },
  ].take(productionCount).toList(),
};

List<Map<String, dynamic>> submittedA1Productions() =>
    (a1SaveConfirmation()["productions"] as List).map((row) {
      final item = Map<String, dynamic>.from(row as Map);
      item.remove("backend_verified_evidence");
      return item;
    }).toList();

void main() {
  test('A1 v4 practice uses the protected session contract', () async {
    final requests = <http.Request>[];
    final service = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/a1-v4-practice-sessions')) {
          return http.Response(
            jsonEncode({
              'session_id': 'c1f5d0f0-2117-4a85-8dc2-52da15c6eb18',
              'token': 'a' * 32,
              'practice_session': true,
              'curricular_accreditation': false,
            }),
            200,
          );
        }
        return http.Response(jsonEncode(a1SaveConfirmation()), 200);
      }),
    );

    final credentials = await service.createA1V4PracticeSession(
      declaredUserId: 'declared-user',
    );
    final confirmation = await service.saveA1V4PracticeSession(
      credentials: credentials,
      productions: submittedA1Productions(),
    );

    expect(decodeBody(requests[0]), {'user_id': 'declared-user'});
    expect(
      requests[1].url.path,
      '/api/v1/a1-v4-practice-sessions/c1f5d0f0-2117-4a85-8dc2-52da15c6eb18/save',
    );
    expect(requests[1].headers['x-a1-v4-practice-token'], 'a' * 32);
    expect(requests[1].body, isNot(contains('curricular_accreditation')));
    expect(confirmation.saved, isTrue);
    expect(confirmation.productionCount, 3);
  });

  test("A1 v4 rejects HTTP 200 with different saved content", () async {
    final credentials = A1V4PracticeSessionCredentials(
      sessionId: "c1f5d0f0-2117-4a85-8dc2-52da15c6eb18",
      token: "a" * 32,
    );

    for (final field in [
      "audio_reference",
      "transcript",
      "client_evaluation",
    ]) {
      final response = a1SaveConfirmation();
      final rows = response["productions"] as List;
      final altered = Map<String, dynamic>.from(rows[0] as Map);

      altered[field] = field == "client_evaluation"
          ? {"semantic_status": "needs_repair"}
          : "different-value";

      response["productions"] = [altered, ...rows.skip(1)];

      final service = ApiService(
        client: MockClient(
          (_) async => http.Response(jsonEncode(response), 200),
        ),
      );

      await expectLater(
        service.saveA1V4PracticeSession(
          credentials: credentials,
          productions: submittedA1Productions(),
        ),
        throwsA(
          isA<A1V4PracticeSessionException>().having(
            (error) => error.kind,
            "kind",
            A1V4PracticeErrorKind.unexpectedResponse,
          ),
        ),
      );
    }
  });

  test('A1 v4 save rejects incoherent HTTP 200 responses', () async {
    final credentials = A1V4PracticeSessionCredentials(
      sessionId: 'c1f5d0f0-2117-4a85-8dc2-52da15c6eb18',
      token: 'a' * 32,
    );
    final invalidResponses = <Object>[
      '',
      a1SaveConfirmation(saved: false),
      a1SaveConfirmation(sessionId: 'other-session'),
      a1SaveConfirmation(productionCount: 2),
    ];

    for (final payload in invalidResponses) {
      final service = ApiService(
        client: MockClient(
          (_) async => http.Response(
            payload is String ? payload : jsonEncode(payload),
            200,
          ),
        ),
      );

      await expectLater(
        service.saveA1V4PracticeSession(
          credentials: credentials,
          productions: const [],
        ),
        throwsA(
          isA<A1V4PracticeSessionException>().having(
            (error) => error.kind,
            'kind',
            A1V4PracticeErrorKind.unexpectedResponse,
          ),
        ),
      );
    }
  });

  test(
    'A1 v4 classifies authorization, contract, conflict, and service errors',
    () async {
      final credentials = A1V4PracticeSessionCredentials(
        sessionId: 'c1f5d0f0-2117-4a85-8dc2-52da15c6eb18',
        token: 'a' * 32,
      );
      const cases = {
        403: A1V4PracticeErrorKind.authorization,
        422: A1V4PracticeErrorKind.contract,
        409: A1V4PracticeErrorKind.conflict,
        503: A1V4PracticeErrorKind.serviceUnavailable,
      };

      for (final entry in cases.entries) {
        final service = ApiService(
          client: MockClient(
            (_) async =>
                http.Response('{"detail":"sensitive-placeholder"}', entry.key),
          ),
        );
        await expectLater(
          service.saveA1V4PracticeSession(
            credentials: credentials,
            productions: const [],
          ),
          throwsA(
            isA<A1V4PracticeSessionException>()
                .having((error) => error.kind, 'kind', entry.value)
                .having(
                  (error) => error.detail,
                  'safe detail',
                  isNot(contains('sensitive-placeholder')),
                ),
          ),
        );
      }
    },
  );

  test('A1 v4 classifies transport failures as network errors', () async {
    final service = ApiService(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      service.createA1V4PracticeSession(declaredUserId: 'declared-user'),
      throwsA(
        isA<A1V4PracticeSessionException>().having(
          (error) => error.kind,
          'kind',
          A1V4PracticeErrorKind.network,
        ),
      ),
    );
  });

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

  test(
    'spoken-turn evaluation sends STT, support, and prior evidence',
    () async {
      late http.Request captured;
      final service = ApiService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'semantic_evaluation': {
                'status': 'adequate',
                'context_relevant': true,
                'rationale': 'Clear request.',
              },
              'conversational_feedback': 'I understand.',
              'next_turn': {
                'action': 'reduce_support',
                'support_level': 'none',
                'reason': 'Try without anchors.',
              },
              'cross_turn_improvement': {
                'comparison_available': true,
                'trend': 'improved',
                'evidence': 'Less support was used.',
              },
              'provenance': {'provider': 'ollama', 'model': 'llama-test'},
              'mastery_awarded': false,
            }),
            200,
          );
        }),
      );

      final result = await service.evaluateSpokenTurn(
        transcript: 'I need water',
        audioReference: 'production-audio://water',
        target: {
          'communicative_goal': 'Request water.',
          'required_meaning_terms': ['need', 'water'],
        },
        context: 'At a refill tap.',
        currentTurn: {
          'turn_id': 'water-1',
          'support_level': 'anchors',
          'visible_support': ['I', 'need', 'water'],
        },
        priorTurnEvidence: [
          {
            'turn_id': 'earlier',
            'semantic_status': 'adequate',
            'matched_meaning_terms': ['need'],
            'missing_meaning_terms': <String>[],
          },
        ],
      );

      expect(captured.url.path, '/api/v1/spoken-turn-evaluations');
      expect(decodeBody(captured)['transcript_source'], 'stt');
      expect(decodeBody(captured)['prior_turn_evidence'], isNotEmpty);
      expect(result.conversationalFeedback, 'I understand.');
      expect(result.nextAction, 'reduce_support');
    },
  );
}
