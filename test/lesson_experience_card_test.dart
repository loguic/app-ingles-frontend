import 'dart:async';

import 'package:app_ingles/models/experience_attempt.dart';
import 'package:app_ingles/models/lesson.dart';
import 'package:app_ingles/screens/lesson_detail_screen.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/widgets/lesson_conversation_card.dart';
import 'package:app_ingles/widgets/lesson_detail_card.dart';
import 'package:app_ingles/widgets/lesson_experience_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeExperienceAudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _completed = StreamController<String>.broadcast();
  final _recording = StreamController<String?>.broadcast();
  int recordingSequence = 0;

  @override
  String? activePlaybackId;

  @override
  String? activeRecordingId;

  @override
  Stream<String?> get onPlaybackChanged => _playback.stream;

  @override
  Stream<String> get onPlaybackCompleted => _completed.stream;

  @override
  Stream<String?> get onRecordingChanged => _recording.stream;

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<void> playReference(String audioAsset, {String? playbackId}) async {
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  @override
  Future<void> stopPlayback() async {
    activePlaybackId = null;
    _playback.add(null);
  }

  @override
  Future<void> startRecording(String recordingId) async {
    activeRecordingId = recordingId;
    _recording.add(recordingId);
  }

  @override
  Future<String?> stopRecording() async {
    activeRecordingId = null;
    _recording.add(null);
    recordingSequence += 1;
    return '/tmp/experience-$recordingSequence.wav';
  }

  @override
  Future<void> cancelRecording() async {
    activeRecordingId = null;
    _recording.add(null);
  }

  @override
  Future<void> deleteRecording(String path) async {}

  @override
  Future<void> dispose() async {
    await _playback.close();
    await _completed.close();
    await _recording.close();
  }
}

class FakeExperienceApiService extends ApiService {
  FakeExperienceApiService({
    this.startResult,
    this.refreshResult,
    this.lessonResult,
    this.failFirstDirectStart = false,
    this.startResults = const [],
    this.refreshResults = const [],
  });

  ExperienceAttemptRecord? startResult;
  ExperienceAttemptRecord? refreshResult;
  Lesson? lessonResult;
  bool failFirstDirectStart;
  final List<ExperienceAttemptRecord?> startResults;
  final List<ExperienceAttemptRecord?> refreshResults;
  int _startResultIndex = 0;
  int _refreshResultIndex = 0;
  int startCalls = 0;
  int refreshCalls = 0;
  int comprehensionCalls = 0;
  int directStartCalls = 0;
  int directFinalizeCalls = 0;
  int saveProgressCalls = 0;
  final List<String> startedDirectIds = [];
  final List<DirectEnglishCapture> finalizedCaptures = [];
  final Map<String, List<DirectEnglishCapture>> finalizedCapturesBySource = {};
  int? lastSelectedIndex;
  String? lastComprehensionExerciseId;
  Completer<ExperienceComprehensionResponseRecord?>? delayedComprehension;
  Completer<DirectEnglishPublicSourceRecord?>? delayedDirectStart;
  Completer<DirectEnglishPublicSourceRecord?>? delayedDirectFinalize;
  Completer<String?>? delayedDirectUpload;
  Completer<ExperienceAttemptRecord?>? delayedRefresh;

  @override
  Future<Lesson?> getLesson(String lessonId) async => lessonResult;

  @override
  Future<ExperienceAttemptRecord?> startOrResumeExperienceAttempt({
    required String userId,
    required String levelId,
    required String unitId,
    required String lessonId,
  }) async {
    startCalls += 1;
    if (_startResultIndex < startResults.length) {
      return startResults[_startResultIndex++];
    }
    return startResult ?? attemptRecord(lessonId: lessonId);
  }

  @override
  Future<ExperienceAttemptRecord?> getExperienceAttempt(
    String attemptId,
  ) async {
    refreshCalls += 1;
    final delayed = delayedRefresh;
    if (delayed != null) {
      return delayed.future;
    }
    if (_refreshResultIndex < refreshResults.length) {
      return refreshResults[_refreshResultIndex++];
    }
    return refreshResult;
  }

  @override
  Future<ExperienceComprehensionResponseRecord?>
  submitExperienceComprehensionResponse({
    required String attemptId,
    required String comprehensionExerciseId,
    required int selectedIndex,
  }) async {
    comprehensionCalls += 1;
    lastSelectedIndex = selectedIndex;
    lastComprehensionExerciseId = comprehensionExerciseId;
    final response = ExperienceComprehensionResponseRecord(
      responseId: 'response-$comprehensionCalls',
      experienceAttemptId: attemptId,
      evidenceDefinitionId: 'evidence-comprehension',
      activityId: 'conversation-listening',
      comprehensionExerciseId: comprehensionExerciseId,
      selectedIndex: selectedIndex,
      isCorrect: selectedIndex == 1,
      submittedAt: DateTime.utc(2026, 8, 31, 10, 1),
    );
    final delayed = delayedComprehension;
    return delayed == null ? response : delayed.future;
  }

  @override
  Future<DirectEnglishPublicSourceRecord?>
  startDirectEnglishConstructionAttempt({
    required String experienceAttemptId,
    required String directEnglishAttemptId,
  }) async {
    directStartCalls += 1;
    startedDirectIds.add(directEnglishAttemptId);
    if (failFirstDirectStart && directStartCalls == 1) {
      return null;
    }
    final source = DirectEnglishPublicSourceRecord(
      directEnglishAttemptId: directEnglishAttemptId,
      experienceAttemptId: experienceAttemptId,
      status: 'started',
      transferVariantId: 'variant-1',
      transferPrompt: 'What do you enjoy?',
    );
    final delayed = delayedDirectStart;
    return delayed == null ? source : delayed.future;
  }

  @override
  Future<DirectEnglishPublicSourceRecord?>
  finalizeDirectEnglishConstructionAttempt({
    required String experienceAttemptId,
    required String directEnglishAttemptId,
    required List<DirectEnglishCapture> captures,
  }) async {
    directFinalizeCalls += 1;
    finalizedCaptures
      ..clear()
      ..addAll(captures);
    finalizedCapturesBySource[directEnglishAttemptId] = List.of(captures);
    final source = DirectEnglishPublicSourceRecord(
      directEnglishAttemptId: directEnglishAttemptId,
      experienceAttemptId: experienceAttemptId,
      status: 'finalized',
      transferVariantId: 'variant-1',
      transferPrompt: 'What do you enjoy?',
    );
    final delayed = delayedDirectFinalize;
    return delayed == null ? source : delayed.future;
  }

  @override
  Future<String?> uploadConversationProductionAudio(String audioPath) async {
    final delayed = delayedDirectUpload;
    return delayed == null ? 'production-audio://$audioPath' : delayed.future;
  }

  @override
  Future<bool> saveProgress({
    required String userId,
    required String levelId,
    required String unitId,
    required String lessonId,
    required String exerciseId,
    required int selectedIndex,
    required bool correct,
  }) async {
    saveProgressCalls += 1;
    return true;
  }
}

ExperienceAttemptRecord attemptRecord({
  String attemptId = 'experience-attempt-1',
  String lessonId = 'lesson-v2',
  String status = 'in_progress',
  String contractVersion = '2.0',
  List<ExperienceEvidenceStateRecord> evidenceStates = const [],
  Set<String> submittedComprehensionExerciseIds = const <String>{},
}) {
  return ExperienceAttemptRecord(
    attemptId: attemptId,
    userId: 'user-1',
    levelId: 'A1',
    unitId: 'a1-u1',
    lessonId: lessonId,
    experienceContractVersion: contractVersion,
    status: status,
    startedAt: DateTime.utc(2026, 8, 31, 10),
    completedAt: status == 'completed'
        ? DateTime.utc(2026, 8, 31, 10, 5)
        : null,
    evidenceStates: evidenceStates,
    submittedComprehensionExerciseIds: submittedComprehensionExerciseIds,
  );
}

const mission = LessonExperienceMission(
  title: 'Misión de prueba',
  situation: 'Una situación real.',
  observableOutcome: 'Responder con tus propias palabras.',
  successCriteria: ['Criterio dinámico'],
);

Lesson v2Lesson({
  String id = 'lesson-v2',
  String? method,
  List<LessonExperienceStage> stages = const [],
  List<LessonExperienceEvidenceDefinition> evidence = const [],
  List<Conversation> conversations = const [],
  List<LessonExercise> exercises = const [],
  List<LessonExperienceLanguageSupport> support = const [],
  LessonPronunciationReinforcement? reinforcement,
  String contractVersion = '2.0',
}) {
  return Lesson(
    id: id,
    title: 'Lección v2',
    vocabulary: const [],
    grammar: const [],
    examples: const [],
    conversations: conversations,
    exercises: exercises,
    experience: LessonExperience(
      contractVersion: contractVersion,
      pedagogicalMethod: method,
      mission: mission,
      stages: stages,
      languageSupport: support,
      evidenceDefinitions: evidence,
      pronunciationReinforcement: reinforcement,
    ),
  );
}

const directConversations = [
  Conversation(
    id: 'direct-guided',
    title: 'Guided',
    turns: [
      ConversationTurn(
        id: 'guided-turn',
        speaker: 'learner',
        en: 'Introduce yourself.',
        productionPrompt: LearnerProductionPrompt(
          id: 'prompt-guided',
          acceptedModalities: ['voice', 'text'],
          productionFunction: 'guided',
        ),
      ),
    ],
  ),
  Conversation(
    id: 'direct-expanded',
    title: 'Expanded',
    turns: [
      ConversationTurn(
        id: 'expanded-turn',
        speaker: 'learner',
        en: 'Add one detail.',
        productionPrompt: LearnerProductionPrompt(
          id: 'prompt-expanded',
          acceptedModalities: ['voice', 'text'],
          productionFunction: 'expanded',
        ),
      ),
    ],
  ),
  Conversation(
    id: 'direct-transfer',
    title: 'Transfer',
    turns: [
      ConversationTurn(
        id: 'transfer-turn',
        speaker: 'learner',
        en: 'Answer a new question.',
        productionPrompt: LearnerProductionPrompt(
          id: 'prompt-transfer',
          acceptedModalities: ['voice', 'text'],
          productionFunction: 'transfer',
        ),
      ),
    ],
  ),
];

const directStages = [
  LessonExperienceStage(
    id: 'stage-guided',
    type: 'guided_production',
    instruction: 'Primera etapa dinámica',
    activityIds: ['direct-guided'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
  LessonExperienceStage(
    id: 'stage-expanded',
    type: 'applied_conversation',
    instruction: 'Segunda etapa dinámica',
    activityIds: ['direct-expanded'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
  LessonExperienceStage(
    id: 'stage-transfer',
    type: 'evidence',
    instruction: 'Tercera etapa dinámica',
    activityIds: ['direct-transfer'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
];

const directEvidence = [
  LessonExperienceEvidenceDefinition(
    id: 'evidence-guided',
    stageId: 'stage-guided',
    activityId: 'direct-guided',
    evidenceType: 'guided_production',
  ),
  LessonExperienceEvidenceDefinition(
    id: 'evidence-expanded',
    stageId: 'stage-expanded',
    activityId: 'direct-expanded',
    evidenceType: 'contextual_response',
  ),
  LessonExperienceEvidenceDefinition(
    id: 'evidence-transfer',
    stageId: 'stage-transfer',
    activityId: 'direct-transfer',
    evidenceType: 'contextual_response',
  ),
];

Conversation _v3DirectConversation(String id) => Conversation(
  id: id,
  title: 'Direct $id',
  turns: [
    ConversationTurn(
      id: '$id-guided-turn',
      speaker: 'learner',
      en: 'Introduce yourself.',
      productionPrompt: LearnerProductionPrompt(
        id: '$id-guided-prompt',
        acceptedModalities: const ['voice', 'text'],
        productionFunction: 'guided',
      ),
    ),
    ConversationTurn(
      id: '$id-expanded-turn',
      speaker: 'learner',
      en: 'Add one detail.',
      productionPrompt: LearnerProductionPrompt(
        id: '$id-expanded-prompt',
        acceptedModalities: const ['voice', 'text'],
        productionFunction: 'expanded',
      ),
    ),
    ConversationTurn(
      id: '$id-transfer-turn',
      speaker: 'learner',
      en: 'Answer the transfer prompt.',
      productionPrompt: LearnerProductionPrompt(
        id: '$id-transfer-prompt',
        acceptedModalities: const ['voice', 'text'],
        productionFunction: 'transfer',
      ),
    ),
  ],
);

const v3DirectStages = [
  LessonExperienceStage(
    id: 'v3-comprehension-stage',
    type: 'comprehension',
    instruction: 'Listen first.',
    activityIds: ['v3-comprehension-activity'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
  LessonExperienceStage(
    id: 'v3-direct-a-stage',
    type: 'guided_production',
    instruction: 'First direct source.',
    activityIds: ['v3-direct-a'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
  LessonExperienceStage(
    id: 'v3-direct-b-stage',
    type: 'applied_conversation',
    instruction: 'Second direct source.',
    activityIds: ['v3-direct-b'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
  LessonExperienceStage(
    id: 'v3-final-conversation-stage',
    type: 'evidence',
    instruction: 'Final conversation.',
    activityIds: ['v3-final-conversation'],
    mode: 'required',
    completionCondition: 'evidence_recorded',
  ),
];

const v3DirectEvidence = [
  LessonExperienceEvidenceDefinition(
    id: 'v3-comprehension-evidence',
    stageId: 'v3-comprehension-stage',
    activityId: 'v3-comprehension-activity',
    evidenceType: 'comprehension_result',
    comprehensionExerciseId: 'v3-comprehension-exercise',
  ),
  LessonExperienceEvidenceDefinition(
    id: 'v3-guided-evidence',
    stageId: 'v3-direct-a-stage',
    activityId: 'v3-direct-a',
    evidenceType: 'guided_production',
  ),
  LessonExperienceEvidenceDefinition(
    id: 'v3-contextual-evidence',
    stageId: 'v3-direct-b-stage',
    activityId: 'v3-direct-b',
    evidenceType: 'contextual_response',
  ),
  LessonExperienceEvidenceDefinition(
    id: 'v3-conversation-evidence',
    stageId: 'v3-final-conversation-stage',
    activityId: 'v3-final-conversation',
    evidenceType: 'conversation_completion',
  ),
];

List<ExperienceEvidenceStateRecord> v3EvidenceStates({
  String guided = 'pending',
  String contextual = 'pending',
  String conversation = 'pending',
}) => [
  const ExperienceEvidenceStateRecord(
    evidenceDefinitionId: 'v3-comprehension-evidence',
    evidenceType: 'comprehension_result',
    status: 'pending',
  ),
  ExperienceEvidenceStateRecord(
    evidenceDefinitionId: 'v3-guided-evidence',
    evidenceType: 'guided_production',
    status: guided,
  ),
  ExperienceEvidenceStateRecord(
    evidenceDefinitionId: 'v3-contextual-evidence',
    evidenceType: 'contextual_response',
    status: contextual,
  ),
  ExperienceEvidenceStateRecord(
    evidenceDefinitionId: 'v3-conversation-evidence',
    evidenceType: 'conversation_completion',
    status: conversation,
  ),
];

Lesson v3DirectLesson() => v2Lesson(
  id: 'lesson-v3',
  contractVersion: '3.0',
  method: 'direct_english_construction',
  stages: v3DirectStages,
  evidence: v3DirectEvidence,
  conversations: [
    _v3DirectConversation('v3-direct-a'),
    _v3DirectConversation('v3-direct-b'),
    _guidedConversation('v3-final-conversation'),
  ],
  exercises: const [
    LessonExercise(
      id: 'v3-comprehension-exercise',
      type: 'multiple_choice',
      prompt: 'What did you hear?',
      options: ['One', 'Two'],
      answerIndex: 1,
      skillIds: [],
    ),
  ],
);

List<ExperienceEvidenceStateRecord> authoritativeStatesFor(
  Iterable<LessonExperienceEvidenceDefinition> definitions,
) {
  return definitions
      .map(
        (definition) => ExperienceEvidenceStateRecord(
          evidenceDefinitionId: definition.id,
          evidenceType: definition.evidenceType,
          status: 'pending',
        ),
      )
      .toList();
}

const _audioFirstPolicy = AudioFirstPresentationPolicy(
  primaryPresentation: 'audio',
  audioReplayAllowed: true,
  transcriptInitiallyHidden: true,
  transcriptAccess: 'after_listening',
  transcriptUseInterpretation: 'support',
  transcriptIsAnswerModel: false,
);

Conversation _guidedConversation(String id) => Conversation(
  id: id,
  title: 'Guided conversation',
  turns: const [
    ConversationTurn(id: 'guided-turn', speaker: 'partner', en: 'Hello'),
  ],
);

Conversation _productionConversation({
  required String id,
  required List<String> promptIds,
}) => Conversation(
  id: id,
  title: 'Production conversation',
  mode: 'free',
  audioFirstPolicy: _audioFirstPolicy,
  turns: promptIds
      .map(
        (promptId) => ConversationTurn(
          id: 'turn-$promptId',
          speaker: 'learner',
          en: 'Respond',
          productionPrompt: LearnerProductionPrompt(
            id: promptId,
            acceptedModalities: const ['voice'],
          ),
        ),
      )
      .toList(),
);

Lesson _comprehensionLesson(String id) => v2Lesson(
  id: id,
  stages: const [
    LessonExperienceStage(
      id: 'comprehension',
      type: 'comprehension',
      instruction: 'Choose what you understood',
      activityIds: ['conversation-listening'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    ),
  ],
  evidence: const [
    LessonExperienceEvidenceDefinition(
      id: 'evidence-comprehension',
      stageId: 'comprehension',
      activityId: 'conversation-listening',
      evidenceType: 'comprehension_result',
      comprehensionExerciseId: 'exercise-comprehension',
    ),
  ],
  exercises: const [
    LessonExercise(
      id: 'exercise-comprehension',
      type: 'multiple_choice',
      prompt: 'What did you hear?',
      options: ['One', 'Two'],
      answerIndex: 1,
      skillIds: [],
    ),
  ],
);

Lesson _strictTimingLesson({
  String contractVersion = '3.0',
  String? transcriptExerciseId = 'timing-exercise',
  String? spanishExerciseId = 'timing-exercise',
}) => v2Lesson(
  id: 'lesson-strict-timing',
  contractVersion: contractVersion,
  stages: const [
    LessonExperienceStage(
      id: 'encounter',
      type: 'encounter',
      instruction: 'Listen.',
      activityIds: ['timing-conversation'],
      mode: 'required',
      completionCondition: 'acknowledged',
    ),
    LessonExperienceStage(
      id: 'comprehension',
      type: 'comprehension',
      instruction: 'Choose.',
      activityIds: ['timing-activity'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    ),
  ],
  conversations: [
    Conversation(
      id: 'timing-conversation',
      title: 'Timing conversation',
      audioFirstPolicy: AudioFirstPresentationPolicy(
        primaryPresentation: 'audio',
        audioReplayAllowed: true,
        transcriptInitiallyHidden: true,
        transcriptAccess: 'after_listening',
        transcriptUseInterpretation: 'support',
        transcriptIsAnswerModel: false,
        transcriptRevealAfterFirstResponseToExerciseId: transcriptExerciseId,
      ),
      turns: const [
        ConversationTurn(
          id: 'timing-partner',
          speaker: 'partner',
          en: 'Timing transcript.',
          pronunciations: [
            LessonPronunciation(
              locale: 'en-US',
              ipa: 'timing',
              audioAsset: 'audio/timing.wav',
            ),
          ],
        ),
      ],
    ),
  ],
  support: [
    LessonExperienceLanguageSupport(
      id: 'timing-support',
      type: 'hint',
      en: 'Timing support.',
      es: 'Apoyo temporal.',
      stageIds: const ['encounter'],
      spanishRevealAfterFirstResponseToExerciseId: spanishExerciseId,
    ),
  ],
  evidence: const [
    LessonExperienceEvidenceDefinition(
      id: 'timing-evidence',
      stageId: 'comprehension',
      activityId: 'timing-activity',
      evidenceType: 'comprehension_result',
      comprehensionExerciseId: 'timing-exercise',
    ),
  ],
  exercises: const [
    LessonExercise(
      id: 'timing-exercise',
      type: 'multiple_choice',
      prompt: 'Timing question?',
      options: ['Incorrect', 'Correct'],
      answerIndex: 1,
      skillIds: [],
    ),
  ],
);

Widget _experienceShell({
  required Lesson lesson,
  required FakeExperienceApiService api,
  required FakeExperienceAudioController audio,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: LessonExperienceCard(
        lesson: lesson,
        levelId: 'A1',
        unitId: 'a1-u1',
        userId: 'user-1',
        audioService: audio,
        apiService: api,
      ),
    ),
  ),
);

Future<FakeExperienceAudioController> pumpExperience(
  WidgetTester tester, {
  required Lesson lesson,
  required FakeExperienceApiService apiService,
  String userId = 'user-1',
}) async {
  final audio = FakeExperienceAudioController();
  addTearDown(audio.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LessonExperienceCard(
            lesson: lesson,
            levelId: 'A1',
            unitId: 'a1-u1',
            userId: userId,
            audioService: audio,
            apiService: apiService,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return audio;
}

Key _v3DirectKey(String activityId, String function, String suffix) {
  return Key('direct-english-$activityId-$function-$suffix');
}

Future<void> saveV3DirectCaptures(
  WidgetTester tester,
  String activityId,
) async {
  for (final function in const ['guided', 'expanded', 'transfer']) {
    await tester.enterText(
      find.byKey(_v3DirectKey(activityId, function, 'text')),
      '$activityId $function response',
    );
    final save = find.byKey(_v3DirectKey(activityId, function, 'save-text'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }
}

Future<void> listenToTimingPartner(
  WidgetTester tester,
  FakeExperienceAudioController audio,
) async {
  final listen = find.text('Escuchar al interlocutor');
  await tester.ensureVisible(listen);
  await tester.tap(listen);
  await tester.pumpAndSettle();
  audio.activePlaybackId = null;
  audio._playback.add(null);
  audio._completed.add(
    'conversation-reference:timing-conversation:'
    'timing-partner:en-US',
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Lesson parser preserves complete v2 runtime fields and legacy null',
    () {
      final parsed = Lesson.fromJson({
        'id': 'lesson-v2',
        'title': 'Lesson',
        'vocabulary': <String>[],
        'grammar': <String>[],
        'examples': <Map<String, dynamic>>[],
        'conversations': <Map<String, dynamic>>[],
        'exercises': <Map<String, dynamic>>[],
        'experience': {
          'contract_version': '2.0',
          'pedagogical_method': 'direct_english_construction',
          'mission': {
            'title': 'Mission',
            'situation': 'Situation',
            'observable_outcome': 'Outcome',
            'success_criteria': ['Criterion'],
          },
          'stages': [
            {
              'id': 'stage-unknown',
              'type': 'future_stage',
              'instruction': 'Do not skip me',
              'activity_ids': ['activity-1'],
              'mode': 'required',
              'completion_condition': 'acknowledged',
            },
          ],
          'language_support': [
            {
              'id': 'support-1',
              'type': 'hint',
              'en': 'Hello',
              'es': 'Hola',
              'usage_note': 'Only when needed',
              'pronunciations': <Map<String, dynamic>>[],
              'stage_ids': ['stage-unknown'],
            },
          ],
          'evidence_definitions': [
            {
              'id': 'evidence-1',
              'stage_id': 'stage-unknown',
              'activity_id': 'activity-1',
              'evidence_type': 'comprehension_result',
              'comprehension_exercise_id': 'exercise-1',
            },
          ],
          'pronunciation_reinforcement': {
            'stage_id': 'stage-unknown',
            'reference_text': 'Hello',
            'listening_objective': 'Listen',
            'shadowing': true,
            'pronunciations': [
              {
                'locale': 'en-US',
                'ipa': '/həˈloʊ/',
                'audio_asset': 'audio/hello.wav',
              },
            ],
            'phonetic_targets': ['/ə/'],
          },
        },
      });
      final legacy = Lesson.fromJson({
        'id': 'legacy',
        'title': 'Legacy',
        'vocabulary': <String>[],
        'grammar': <String>[],
        'examples': <Map<String, dynamic>>[],
        'conversations': <Map<String, dynamic>>[],
        'exercises': <Map<String, dynamic>>[],
      });

      expect(parsed.experience?.stages.single.type, 'future_stage');
      expect(parsed.experience?.languageSupport.single.es, 'Hola');
      expect(
        parsed.experience?.evidenceDefinitions.single.comprehensionExerciseId,
        'exercise-1',
      );
      expect(
        parsed.experience?.pronunciationReinforcement?.stageId,
        'stage-unknown',
      );
      expect(legacy.experience, isNull);
    },
  );

  testWidgets(
    'v3 strict timing blocks transcript and Spanish before a response',
    (tester) async {
      final lesson = _strictTimingLesson();
      final api = FakeExperienceApiService(
        startResult: attemptRecord(
          lessonId: lesson.id,
          contractVersion: '3.0',
          evidenceStates: authoritativeStatesFor(
            lesson.experience!.evidenceDefinitions,
          ),
        ),
      );
      final audio = await pumpExperience(
        tester,
        lesson: lesson,
        apiService: api,
      );

      expect(find.text('Necesito apoyo en español'), findsNothing);
      await listenToTimingPartner(tester, audio);
      expect(find.text('Mostrar transcript por accesibilidad'), findsNothing);
    },
  );

  testWidgets('v3 strict timing unlocks after a correct target response', (
    tester,
  ) async {
    final lesson = _strictTimingLesson();
    final states = authoritativeStatesFor(
      lesson.experience!.evidenceDefinitions,
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: lesson.id,
        contractVersion: '3.0',
        evidenceStates: states,
      ),
      refreshResult: attemptRecord(
        lessonId: lesson.id,
        contractVersion: '3.0',
        evidenceStates: states,
        submittedComprehensionExerciseIds: const {'timing-exercise'},
      ),
    );
    final audio = await pumpExperience(tester, lesson: lesson, apiService: api);

    final response = find.byKey(
      const Key('experience-comprehension-timing-exercise-option-1'),
    );
    await tester.ensureVisible(response);
    await tester.tap(response);
    await tester.pumpAndSettle();

    expect(find.text('Necesito apoyo en español'), findsOneWidget);
    await listenToTimingPartner(tester, audio);
    expect(find.text('Mostrar transcript por accesibilidad'), findsOneWidget);
  });

  testWidgets('v3 strict timing unlocks after an incorrect target response', (
    tester,
  ) async {
    final lesson = _strictTimingLesson();
    final states = authoritativeStatesFor(
      lesson.experience!.evidenceDefinitions,
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: lesson.id,
        contractVersion: '3.0',
        evidenceStates: states,
      ),
      refreshResult: attemptRecord(
        lessonId: lesson.id,
        contractVersion: '3.0',
        evidenceStates: states,
        submittedComprehensionExerciseIds: const {'timing-exercise'},
      ),
    );
    await pumpExperience(tester, lesson: lesson, apiService: api);

    final response = find.byKey(
      const Key('experience-comprehension-timing-exercise-option-0'),
    );
    await tester.ensureVisible(response);
    await tester.tap(response);
    await tester.pumpAndSettle();

    expect(
      find.text('Respuesta guardada. Puedes volver a intentarlo.'),
      findsOneWidget,
    );
    expect(find.text('Necesito apoyo en español'), findsOneWidget);
  });

  testWidgets(
    'v3 strict timing ignores responses submitted to another exercise',
    (tester) async {
      final lesson = _strictTimingLesson();
      final api = FakeExperienceApiService(
        startResult: attemptRecord(
          lessonId: lesson.id,
          contractVersion: '3.0',
          evidenceStates: authoritativeStatesFor(
            lesson.experience!.evidenceDefinitions,
          ),
          submittedComprehensionExerciseIds: const {'other-exercise'},
        ),
      );
      final audio = await pumpExperience(
        tester,
        lesson: lesson,
        apiService: api,
      );

      expect(find.text('Necesito apoyo en español'), findsNothing);
      await listenToTimingPartner(tester, audio);
      expect(find.text('Mostrar transcript por accesibilidad'), findsNothing);
    },
  );

  testWidgets('v2 preserves support timing behavior when metadata is present', (
    tester,
  ) async {
    final lesson = _strictTimingLesson(contractVersion: '2.0');
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: lesson.id,
        evidenceStates: authoritativeStatesFor(
          lesson.experience!.evidenceDefinitions,
        ),
      ),
    );
    final audio = await pumpExperience(tester, lesson: lesson, apiService: api);

    expect(find.text('Necesito apoyo en español'), findsOneWidget);
    await listenToTimingPartner(tester, audio);
    expect(find.text('Mostrar transcript por accesibilidad'), findsOneWidget);
  });

  testWidgets('v3 preserves support timing behavior without new metadata', (
    tester,
  ) async {
    final lesson = _strictTimingLesson(
      transcriptExerciseId: null,
      spanishExerciseId: null,
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: lesson.id,
        contractVersion: '3.0',
        evidenceStates: authoritativeStatesFor(
          lesson.experience!.evidenceDefinitions,
        ),
      ),
    );
    final audio = await pumpExperience(tester, lesson: lesson, apiService: api);

    expect(find.text('Necesito apoyo en español'), findsOneWidget);
    await listenToTimingPartner(tester, audio);
    expect(find.text('Mostrar transcript por accesibilidad'), findsOneWidget);
  });

  testWidgets('renders every backend stage once and in received order', (
    tester,
  ) async {
    final stages = [
      const LessonExperienceStage(
        id: 'closure-first',
        type: 'closure',
        instruction: 'First backend stage',
        activityIds: [],
        mode: 'required',
        completionCondition: 'acknowledged',
      ),
      const LessonExperienceStage(
        id: 'support-second',
        type: 'language_support',
        instruction: 'Second backend stage',
        activityIds: [],
        mode: 'required',
        completionCondition: 'acknowledged',
      ),
    ];
    await pumpExperience(
      tester,
      lesson: v2Lesson(stages: stages),
      apiService: FakeExperienceApiService(),
    );

    expect(find.byKey(const Key('lesson-experience-card')), findsOneWidget);
    expect(
      find.byKey(const Key('experience-stage-closure-first')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('experience-stage-support-second')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('First backend stage')).dy,
      lessThan(tester.getTopLeft(find.text('Second backend stage')).dy),
    );
    expect(find.textContaining('3.'), findsNothing);
  });

  testWidgets('unsupported known and unknown stages fail visibly', (
    tester,
  ) async {
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [
          LessonExperienceStage(
            id: 'assisted',
            type: 'assisted_response',
            instruction: 'Assisted',
            activityIds: [],
            mode: 'adaptive',
            completionCondition: 'acknowledged',
          ),
          LessonExperienceStage(
            id: 'future',
            type: 'future_stage',
            instruction: 'Future',
            activityIds: [],
            mode: 'required',
            completionCondition: 'acknowledged',
          ),
        ],
      ),
      apiService: FakeExperienceApiService(),
    );

    expect(find.textContaining('assisted_response'), findsOneWidget);
    expect(find.textContaining('future_stage'), findsOneWidget);
    expect(
      find.textContaining('No se enviará ninguna evidencia.'),
      findsNWidgets(2),
    );
  });

  testWidgets('starts once and resets when lesson identity changes', (
    tester,
  ) async {
    final api = FakeExperienceApiService();
    final audio = FakeExperienceAudioController();
    addTearDown(audio.dispose);
    Widget build(String lessonId) => MaterialApp(
      home: LessonExperienceCard(
        lesson: v2Lesson(id: lessonId),
        levelId: 'A1',
        unitId: 'a1-u1',
        userId: 'user-1',
        audioService: audio,
        apiService: api,
      ),
    );

    await tester.pumpWidget(build('lesson-one'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(build('lesson-one'));
    await tester.pumpAndSettle();
    expect(api.startCalls, 1);

    await tester.pumpWidget(build('lesson-two'));
    await tester.pumpAndSettle();
    expect(api.startCalls, 2);
  });

  testWidgets('shows ordered authoritative states with neutral review label', (
    tester,
  ) async {
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: const [
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'pending',
            evidenceType: 'comprehension_result',
            status: 'pending',
          ),
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'review',
            evidenceType: 'contextual_response',
            status: 'needs_review',
          ),
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'done',
            evidenceType: 'guided_production',
            status: 'satisfied',
          ),
        ],
      ),
    );
    await pumpExperience(tester, lesson: v2Lesson(), apiService: api);

    expect(find.text('Por practicar'), findsOneWidget);
    expect(find.text('En revisión'), findsOneWidget);
    expect(find.text('Conseguido'), findsOneWidget);
    expect(find.textContaining('evidence-'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('only backend completed status drives completion UX', (
    tester,
  ) async {
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        status: 'in_progress',
        evidenceStates: const [
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'done',
            evidenceType: 'guided_production',
            status: 'satisfied',
          ),
        ],
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [
          LessonExperienceStage(
            id: 'closure',
            type: 'closure',
            instruction: 'Last visible stage',
            activityIds: [],
            mode: 'required',
            completionCondition: 'acknowledged',
          ),
        ],
      ),
      apiService: api,
    );
    expect(find.byKey(const Key('experience-completed')), findsNothing);
    expect(find.textContaining('no completa'), findsOneWidget);

    api.startResult = attemptRecord(status: 'completed');
    await pumpExperience(
      tester,
      lesson: v2Lesson(id: 'completed-lesson'),
      apiService: api,
    );
    expect(find.byKey(const Key('experience-completed')), findsOneWidget);
  });

  testWidgets('comprehension uses source endpoint then authoritative refresh', (
    tester,
  ) async {
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: const [
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'evidence-comprehension',
            evidenceType: 'comprehension_result',
            status: 'pending',
          ),
        ],
      ),
      refreshResult: attemptRecord(
        evidenceStates: const [
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'evidence-comprehension',
            evidenceType: 'comprehension_result',
            status: 'satisfied',
          ),
        ],
      ),
    );
    final lesson = v2Lesson(
      stages: const [
        LessonExperienceStage(
          id: 'comprehension',
          type: 'comprehension',
          instruction: 'Choose what you understood',
          activityIds: ['conversation-listening'],
          mode: 'required',
          completionCondition: 'evidence_recorded',
        ),
      ],
      evidence: const [
        LessonExperienceEvidenceDefinition(
          id: 'evidence-comprehension',
          stageId: 'comprehension',
          activityId: 'conversation-listening',
          evidenceType: 'comprehension_result',
          comprehensionExerciseId: 'exercise-comprehension',
        ),
      ],
      exercises: const [
        LessonExercise(
          id: 'exercise-comprehension',
          type: 'multiple_choice',
          prompt: 'What did you hear?',
          options: ['One', 'Two'],
          answerIndex: 1,
          skillIds: [],
        ),
      ],
    );
    await pumpExperience(tester, lesson: lesson, apiService: api);

    await tester.tap(
      find.byKey(
        const Key('experience-comprehension-exercise-comprehension-option-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.comprehensionCalls, 1);
    expect(api.lastSelectedIndex, 1);
    expect(api.lastComprehensionExerciseId, 'exercise-comprehension');
    expect(api.saveProgressCalls, 0);
    expect(api.refreshCalls, 1);
    expect(find.text('Respuesta correcta.'), findsOneWidget);
    expect(find.text('Conseguido'), findsOneWidget);
  });

  testWidgets('refresh failure retains the prior authoritative snapshot', (
    tester,
  ) async {
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: const [
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'evidence-comprehension',
            evidenceType: 'comprehension_result',
            status: 'pending',
          ),
        ],
      ),
      refreshResult: null,
    );
    final lesson = v2Lesson(
      stages: const [
        LessonExperienceStage(
          id: 'comprehension',
          type: 'comprehension',
          instruction: 'Choose',
          activityIds: ['conversation-listening'],
          mode: 'required',
          completionCondition: 'evidence_recorded',
        ),
      ],
      evidence: const [
        LessonExperienceEvidenceDefinition(
          id: 'evidence-comprehension',
          stageId: 'comprehension',
          activityId: 'conversation-listening',
          evidenceType: 'comprehension_result',
          comprehensionExerciseId: 'exercise-comprehension',
        ),
      ],
      exercises: const [
        LessonExercise(
          id: 'exercise-comprehension',
          type: 'multiple_choice',
          prompt: 'Question',
          options: ['One', 'Two'],
          answerIndex: 1,
          skillIds: [],
        ),
      ],
    );
    await pumpExperience(tester, lesson: lesson, apiService: api);
    await tester.tap(
      find.byKey(
        const Key('experience-comprehension-exercise-comprehension-option-0'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Por practicar'), findsOneWidget);
    expect(find.byKey(const Key('experience-stale-state')), findsOneWidget);
    expect(find.byKey(const Key('experience-completed')), findsNothing);
  });

  testWidgets('optional evidence never binds a conversation source', (
    tester,
  ) async {
    const stage = LessonExperienceStage(
      id: 'interaction',
      type: 'applied_conversation',
      instruction: 'Practice',
      activityIds: ['conversation-1'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: const [
          ExperienceEvidenceStateRecord(
            evidenceDefinitionId: 'another-required-evidence',
            evidenceType: 'conversation_completion',
            status: 'pending',
          ),
        ],
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [stage],
        conversations: [_guidedConversation('conversation-1')],
        evidence: const [
          LessonExperienceEvidenceDefinition(
            id: 'optional-completion',
            stageId: 'interaction',
            activityId: 'conversation-1',
            evidenceType: 'conversation_completion',
          ),
        ],
      ),
      apiService: api,
    );

    final card = tester.widget<LessonConversationCard>(
      find.byType(LessonConversationCard),
    );
    expect(card.experienceAttemptId, isNull);
  });

  testWidgets('wrong source kind never binds a conversation attempt', (
    tester,
  ) async {
    const stage = LessonExperienceStage(
      id: 'interaction',
      type: 'applied_conversation',
      instruction: 'Practice',
      activityIds: ['conversation-1'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    );
    const evidence = LessonExperienceEvidenceDefinition(
      id: 'contextual-evidence',
      stageId: 'interaction',
      activityId: 'conversation-1',
      evidenceType: 'contextual_response',
      productionPromptId: 'prompt-1',
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: authoritativeStatesFor(const [evidence]),
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [stage],
        conversations: [_guidedConversation('conversation-1')],
        evidence: const [evidence],
      ),
      apiService: api,
    );

    expect(
      tester
          .widget<LessonConversationCard>(find.byType(LessonConversationCard))
          .experienceAttemptId,
      isNull,
    );
  });

  testWidgets('incomplete contextual prompt mapping never binds production', (
    tester,
  ) async {
    const stage = LessonExperienceStage(
      id: 'interaction',
      type: 'applied_conversation',
      instruction: 'Practice',
      activityIds: ['conversation-1'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    );
    const evidence = LessonExperienceEvidenceDefinition(
      id: 'contextual-evidence',
      stageId: 'interaction',
      activityId: 'conversation-1',
      evidenceType: 'contextual_response',
      productionPromptId: 'prompt-1',
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: authoritativeStatesFor(const [evidence]),
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [stage],
        conversations: [
          _productionConversation(
            id: 'conversation-1',
            promptIds: const ['prompt-1', 'prompt-2', 'prompt-3'],
          ),
        ],
        evidence: const [evidence],
      ),
      apiService: api,
    );

    expect(
      tester
          .widget<LessonConversationCard>(find.byType(LessonConversationCard))
          .experienceAttemptId,
      isNull,
    );
  });

  testWidgets('exact required conversation completion binds its source', (
    tester,
  ) async {
    const stage = LessonExperienceStage(
      id: 'interaction',
      type: 'applied_conversation',
      instruction: 'Practice',
      activityIds: ['conversation-1'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    );
    const evidence = LessonExperienceEvidenceDefinition(
      id: 'completion-evidence',
      stageId: 'interaction',
      activityId: 'conversation-1',
      evidenceType: 'conversation_completion',
    );
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: authoritativeStatesFor(const [evidence]),
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [stage],
        conversations: [_guidedConversation('conversation-1')],
        evidence: const [evidence],
      ),
      apiService: api,
    );

    expect(
      tester
          .widget<LessonConversationCard>(find.byType(LessonConversationCard))
          .experienceAttemptId,
      'experience-attempt-1',
    );
  });

  testWidgets('exact required contextual prompts bind production source', (
    tester,
  ) async {
    const stage = LessonExperienceStage(
      id: 'interaction',
      type: 'applied_conversation',
      instruction: 'Practice',
      activityIds: ['conversation-1'],
      mode: 'required',
      completionCondition: 'evidence_recorded',
    );
    const evidence = [
      LessonExperienceEvidenceDefinition(
        id: 'contextual-1',
        stageId: 'interaction',
        activityId: 'conversation-1',
        evidenceType: 'contextual_response',
        productionPromptId: 'prompt-1',
      ),
      LessonExperienceEvidenceDefinition(
        id: 'contextual-2',
        stageId: 'interaction',
        activityId: 'conversation-1',
        evidenceType: 'contextual_response',
        productionPromptId: 'prompt-2',
      ),
      LessonExperienceEvidenceDefinition(
        id: 'contextual-3',
        stageId: 'interaction',
        activityId: 'conversation-1',
        evidenceType: 'contextual_response',
        productionPromptId: 'prompt-3',
      ),
    ];
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        evidenceStates: authoritativeStatesFor(evidence),
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [stage],
        conversations: [
          _productionConversation(
            id: 'conversation-1',
            promptIds: const ['prompt-1', 'prompt-2', 'prompt-3'],
          ),
        ],
        evidence: evidence,
      ),
      apiService: api,
    );

    expect(
      tester
          .widget<LessonConversationCard>(find.byType(LessonConversationCard))
          .experienceAttemptId,
      'experience-attempt-1',
    );
  });

  testWidgets('late comprehension response from another lesson is discarded', (
    tester,
  ) async {
    final delayed = Completer<ExperienceComprehensionResponseRecord?>();
    final requiredState = const ExperienceEvidenceStateRecord(
      evidenceDefinitionId: 'evidence-comprehension',
      evidenceType: 'comprehension_result',
      status: 'pending',
    );
    final api = FakeExperienceApiService(
      startResults: [
        attemptRecord(
          attemptId: 'attempt-A',
          lessonId: 'lesson-A',
          evidenceStates: [requiredState],
        ),
        attemptRecord(
          attemptId: 'attempt-B',
          lessonId: 'lesson-B',
          evidenceStates: [requiredState],
        ),
      ],
    )..delayedComprehension = delayed;
    final audio = FakeExperienceAudioController();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      _experienceShell(
        lesson: _comprehensionLesson('lesson-A'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('experience-comprehension-exercise-comprehension-option-1'),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      _experienceShell(
        lesson: _comprehensionLesson('lesson-B'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    delayed.complete(
      ExperienceComprehensionResponseRecord(
        responseId: 'response-A',
        experienceAttemptId: 'attempt-A',
        evidenceDefinitionId: 'evidence-comprehension',
        activityId: 'conversation-listening',
        comprehensionExerciseId: 'exercise-comprehension',
        selectedIndex: 1,
        isCorrect: true,
        submittedAt: DateTime.utc(2026, 9, 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Respuesta correcta.'), findsNothing);
    expect(api.refreshCalls, 0);
  });

  testWidgets('late Direct English start from another lesson is discarded', (
    tester,
  ) async {
    final delayed = Completer<DirectEnglishPublicSourceRecord?>();
    final api = FakeExperienceApiService(
      startResults: [
        attemptRecord(
          attemptId: 'attempt-A',
          lessonId: 'lesson-A',
          evidenceStates: authoritativeStatesFor(directEvidence),
        ),
        attemptRecord(
          attemptId: 'attempt-B',
          lessonId: 'lesson-B',
          evidenceStates: authoritativeStatesFor(directEvidence),
        ),
      ],
    )..delayedDirectStart = delayed;
    final audio = FakeExperienceAudioController();
    addTearDown(audio.dispose);
    Lesson directLesson(String id) => v2Lesson(
      id: id,
      method: 'direct_english_construction',
      stages: directStages,
      evidence: directEvidence,
      conversations: directConversations,
    );

    await tester.pumpWidget(
      _experienceShell(
        lesson: directLesson('lesson-A'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('direct-english-guided-text')),
      'I am Alex.',
    );
    await tester.tap(find.byKey(const Key('direct-english-guided-save-text')));
    await tester.pump();

    await tester.pumpWidget(
      _experienceShell(
        lesson: directLesson('lesson-B'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    api.delayedDirectStart = null;
    delayed.complete(
      const DirectEnglishPublicSourceRecord(
        directEnglishAttemptId: 'direct-english:attempt-A',
        experienceAttemptId: 'attempt-A',
        status: 'started',
        transferVariantId: 'variant-A',
        transferPrompt: 'Prompt A',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('direct-english-guided-text')),
      'I am Bea.',
    );
    await tester.tap(find.byKey(const Key('direct-english-guided-save-text')));
    await tester.pumpAndSettle();

    expect(api.startedDirectIds, [
      'direct-english:attempt-A',
      'direct-english:attempt-B',
    ]);
    expect(find.text('Prompt A'), findsNothing);
  });

  testWidgets('late Direct English finalize from another lesson is discarded', (
    tester,
  ) async {
    final delayed = Completer<DirectEnglishPublicSourceRecord?>();
    final api = FakeExperienceApiService(
      startResults: [
        attemptRecord(
          attemptId: 'attempt-A',
          lessonId: 'lesson-A',
          evidenceStates: authoritativeStatesFor(directEvidence),
        ),
        attemptRecord(
          attemptId: 'attempt-B',
          lessonId: 'lesson-B',
          evidenceStates: authoritativeStatesFor(directEvidence),
        ),
      ],
    );
    final audio = FakeExperienceAudioController();
    addTearDown(audio.dispose);
    Lesson directLesson(String id) => v2Lesson(
      id: id,
      method: 'direct_english_construction',
      stages: directStages,
      evidence: directEvidence,
      conversations: directConversations,
    );

    await tester.pumpWidget(
      _experienceShell(
        lesson: directLesson('lesson-A'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    for (final function in const ['guided', 'expanded', 'transfer']) {
      await tester.enterText(
        find.byKey(Key('direct-english-$function-text')),
        'Answer for $function',
      );
      final saveButton = find.byKey(Key('direct-english-$function-save-text'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
    }
    api.delayedDirectFinalize = delayed;
    final finalizeButton = find.byKey(const Key('direct-english-finalize'));
    await tester.ensureVisible(finalizeButton);
    expect(tester.widget<FilledButton>(finalizeButton).onPressed, isNotNull);
    await tester.tap(finalizeButton);
    await tester.pump();

    await tester.pumpWidget(
      _experienceShell(
        lesson: directLesson('lesson-B'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    delayed.complete(
      const DirectEnglishPublicSourceRecord(
        directEnglishAttemptId: 'direct-english:attempt-A',
        experienceAttemptId: 'attempt-A',
        status: 'finalized',
        transferVariantId: 'variant-A',
        transferPrompt: 'Prompt A',
      ),
    );
    await tester.pumpAndSettle();

    expect(api.refreshCalls, 0);
    expect(find.byKey(const Key('experience-completed')), findsNothing);
    expect(find.text('Prompt A'), findsNothing);
  });

  testWidgets('late authoritative refresh cannot replace another lesson', (
    tester,
  ) async {
    final delayed = Completer<ExperienceAttemptRecord?>();
    final requiredState = const ExperienceEvidenceStateRecord(
      evidenceDefinitionId: 'evidence-comprehension',
      evidenceType: 'comprehension_result',
      status: 'pending',
    );
    final api = FakeExperienceApiService(
      startResults: [
        attemptRecord(
          attemptId: 'attempt-A',
          lessonId: 'lesson-A',
          evidenceStates: [requiredState],
        ),
        attemptRecord(
          attemptId: 'attempt-B',
          lessonId: 'lesson-B',
          evidenceStates: [requiredState],
        ),
      ],
    )..delayedRefresh = delayed;
    final audio = FakeExperienceAudioController();
    addTearDown(audio.dispose);

    await tester.pumpWidget(
      _experienceShell(
        lesson: _comprehensionLesson('lesson-A'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const Key('experience-comprehension-exercise-comprehension-option-1'),
      ),
    );
    await tester.pump();
    expect(api.refreshCalls, 1);

    await tester.pumpWidget(
      _experienceShell(
        lesson: _comprehensionLesson('lesson-B'),
        api: api,
        audio: audio,
      ),
    );
    await tester.pumpAndSettle();
    delayed.complete(
      attemptRecord(
        attemptId: 'attempt-A',
        lessonId: 'lesson-A',
        status: 'completed',
        evidenceStates: [requiredState],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('experience-completed')), findsNothing);
    expect(find.text('Respuesta correcta.'), findsNothing);
  });

  testWidgets(
    'v3 creates distinct activity-scoped sources only after authoritative refresh',
    (tester) async {
      final delayedRefresh = Completer<ExperienceAttemptRecord?>();
      final api = FakeExperienceApiService(
        startResult: attemptRecord(
          lessonId: 'lesson-v3',
          contractVersion: '3.0',
          evidenceStates: v3EvidenceStates(),
        ),
      )..delayedRefresh = delayedRefresh;
      await pumpExperience(tester, lesson: v3DirectLesson(), apiService: api);

      for (final function in const ['guided', 'expanded', 'transfer']) {
        expect(
          find.byKey(_v3DirectKey('v3-direct-a', function, 'text')),
          findsOneWidget,
        );
        expect(
          find.byKey(_v3DirectKey('v3-direct-b', function, 'text')),
          findsNothing,
        );
      }

      await saveV3DirectCaptures(tester, 'v3-direct-a');
      expect(api.startedDirectIds, [
        'direct-english:experience-attempt-1:v3-direct-a',
      ]);
      final firstFinalize = find.byKey(
        const Key('direct-english-v3-direct-a-finalize'),
      );
      await tester.ensureVisible(firstFinalize);
      await tester.tap(firstFinalize);
      await tester.pump();

      expect(api.directFinalizeCalls, 1);
      expect(
        api.finalizedCapturesBySource['direct-english:experience-attempt-1:v3-direct-a']
            ?.map((capture) => capture.productionFunction),
        ['guided', 'expanded', 'transfer'],
      );
      expect(
        find.byKey(_v3DirectKey('v3-direct-b', 'guided', 'text')),
        findsNothing,
      );

      api.delayedRefresh = null;
      api.refreshResult = attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(guided: 'satisfied'),
      );
      delayedRefresh.complete(api.refreshResult);
      await tester.pumpAndSettle();

      final secondFinalize = find.byKey(
        const Key('direct-english-v3-direct-b-finalize'),
      );
      expect(
        find.byKey(_v3DirectKey('v3-direct-b', 'guided', 'text')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(secondFinalize).onPressed, isNull);

      api.refreshResult = attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(
          guided: 'satisfied',
          contextual: 'satisfied',
        ),
      );

      await saveV3DirectCaptures(tester, 'v3-direct-b');
      expect(api.startedDirectIds, [
        'direct-english:experience-attempt-1:v3-direct-a',
        'direct-english:experience-attempt-1:v3-direct-b',
      ]);
      await tester.ensureVisible(secondFinalize);
      await tester.tap(secondFinalize);
      await tester.pumpAndSettle();

      expect(api.directFinalizeCalls, 2);
      expect(
        api.finalizedCapturesBySource.keys,
        containsAll([
          'direct-english:experience-attempt-1:v3-direct-a',
          'direct-english:experience-attempt-1:v3-direct-b',
        ]),
      );
      expect(find.byKey(const Key('experience-completed')), findsNothing);
      expect(find.text('Conseguido'), findsNWidgets(2));
    },
  );

  testWidgets('v3 final conversation uses the exact completion source', (
    tester,
  ) async {
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(
          guided: 'satisfied',
          contextual: 'satisfied',
        ),
      ),
    );
    await pumpExperience(tester, lesson: v3DirectLesson(), apiService: api);

    final conversation = tester.widget<LessonConversationCard>(
      find.byType(LessonConversationCard),
    );
    expect(conversation.conversation.id, 'v3-final-conversation');
    expect(conversation.experienceAttemptId, 'experience-attempt-1');
    expect(
      find.byKey(_v3DirectKey('v3-direct-a', 'guided', 'text')),
      findsNothing,
    );
  });

  testWidgets('stale v3 source start cannot mutate the next source', (
    tester,
  ) async {
    final delayedStart = Completer<DirectEnglishPublicSourceRecord?>();
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(),
      ),
      refreshResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(guided: 'satisfied'),
      ),
    )..delayedDirectStart = delayedStart;
    await pumpExperience(tester, lesson: v3DirectLesson(), apiService: api);

    await tester.enterText(
      find.byKey(_v3DirectKey('v3-direct-a', 'guided', 'text')),
      'I am Alex.',
    );
    final saveGuided = find.byKey(
      _v3DirectKey('v3-direct-a', 'guided', 'save-text'),
    );
    await tester.ensureVisible(saveGuided);
    await tester.tap(saveGuided);
    await tester.pump();
    final comprehension = find.byKey(
      const Key('experience-comprehension-v3-comprehension-exercise-option-1'),
    );
    await tester.ensureVisible(comprehension);
    await tester.tap(comprehension);
    await tester.pumpAndSettle();

    expect(
      find.byKey(_v3DirectKey('v3-direct-b', 'guided', 'text')),
      findsOneWidget,
    );
    api.delayedDirectStart = null;
    delayedStart.complete(
      const DirectEnglishPublicSourceRecord(
        directEnglishAttemptId:
            'direct-english:experience-attempt-1:v3-direct-a',
        experienceAttemptId: 'experience-attempt-1',
        status: 'started',
        transferVariantId: 'variant-a',
        transferPrompt: 'Prompt A',
      ),
    );
    await tester.pumpAndSettle();

    final secondFinalize = find.byKey(
      const Key('direct-english-v3-direct-b-finalize'),
    );
    expect(tester.widget<FilledButton>(secondFinalize).onPressed, isNull);
    expect(find.text('Prompt A'), findsNothing);
  });

  testWidgets('stale v3 finalize cannot mutate the next source', (
    tester,
  ) async {
    final delayedFinalize = Completer<DirectEnglishPublicSourceRecord?>();
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(),
      ),
      refreshResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(guided: 'satisfied'),
      ),
    )..delayedDirectFinalize = delayedFinalize;
    await pumpExperience(tester, lesson: v3DirectLesson(), apiService: api);
    await saveV3DirectCaptures(tester, 'v3-direct-a');

    final firstFinalize = find.byKey(
      const Key('direct-english-v3-direct-a-finalize'),
    );
    await tester.ensureVisible(firstFinalize);
    await tester.tap(firstFinalize);
    await tester.pump();

    final comprehension = find.byKey(
      const Key('experience-comprehension-v3-comprehension-exercise-option-1'),
    );
    await tester.ensureVisible(comprehension);
    await tester.tap(comprehension);
    await tester.pumpAndSettle();
    expect(
      find.byKey(_v3DirectKey('v3-direct-b', 'guided', 'text')),
      findsOneWidget,
    );

    api.delayedDirectFinalize = null;
    delayedFinalize.complete(
      const DirectEnglishPublicSourceRecord(
        directEnglishAttemptId:
            'direct-english:experience-attempt-1:v3-direct-a',
        experienceAttemptId: 'experience-attempt-1',
        status: 'finalized',
        transferVariantId: 'variant-a',
        transferPrompt: 'Prompt A',
      ),
    );
    await tester.pumpAndSettle();

    expect(api.refreshCalls, 1);
    final secondFinalize = find.byKey(
      const Key('direct-english-v3-direct-b-finalize'),
    );
    expect(tester.widget<FilledButton>(secondFinalize).onPressed, isNull);
    expect(find.text('Prompt A'), findsNothing);
  });

  testWidgets('stale v3 upload cannot populate the next source', (
    tester,
  ) async {
    final delayedUpload = Completer<String?>();
    final api = FakeExperienceApiService(
      startResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(),
      ),
      refreshResult: attemptRecord(
        lessonId: 'lesson-v3',
        contractVersion: '3.0',
        evidenceStates: v3EvidenceStates(guided: 'satisfied'),
      ),
    )..delayedDirectUpload = delayedUpload;
    await pumpExperience(tester, lesson: v3DirectLesson(), apiService: api);

    final record = find.byKey(_v3DirectKey('v3-direct-a', 'guided', 'record'));
    await tester.ensureVisible(record);
    await tester.tap(record);
    await tester.pump();
    await tester.ensureVisible(record);
    await tester.tap(record);
    await tester.pump();

    await saveV3DirectCaptures(tester, 'v3-direct-a');
    final firstFinalize = find.byKey(
      const Key('direct-english-v3-direct-a-finalize'),
    );
    await tester.ensureVisible(firstFinalize);
    await tester.tap(firstFinalize);
    await tester.pumpAndSettle();

    final secondFinalize = find.byKey(
      const Key('direct-english-v3-direct-b-finalize'),
    );
    expect(tester.widget<FilledButton>(secondFinalize).onPressed, isNull);
    delayedUpload.complete('production-audio://stale-a');
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(secondFinalize).onPressed, isNull);
    expect(find.text('Producción preparada (voz).'), findsNothing);
  });

  testWidgets(
    'Direct English keeps stable source ID and finalizes three facts',
    (tester) async {
      final api = FakeExperienceApiService(
        startResult: attemptRecord(
          evidenceStates: authoritativeStatesFor(directEvidence),
        ),
        refreshResult: attemptRecord(status: 'completed'),
      );
      await pumpExperience(
        tester,
        lesson: v2Lesson(
          method: 'direct_english_construction',
          stages: directStages,
          evidence: directEvidence,
          conversations: directConversations,
        ),
        apiService: api,
      );

      for (final function in const ['guided', 'expanded', 'transfer']) {
        await tester.enterText(
          find.byKey(Key('direct-english-$function-text')),
          'My $function response',
        );
        final saveButton = find.byKey(
          Key('direct-english-$function-save-text'),
        );
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(
        find.byKey(const Key('direct-english-finalize')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('direct-english-finalize')));
      await tester.pumpAndSettle();

      expect(api.directStartCalls, 1);
      expect(api.startedDirectIds, ['direct-english:experience-attempt-1']);
      expect(api.directFinalizeCalls, 1);
      expect(
        api.finalizedCaptures.map((capture) => capture.productionFunction),
        ['guided', 'expanded', 'transfer'],
      );
      expect(api.refreshCalls, 1);
      expect(find.byKey(const Key('experience-completed')), findsOneWidget);
    },
  );

  testWidgets('Direct English start retry reuses the same deterministic ID', (
    tester,
  ) async {
    final api = FakeExperienceApiService(
      failFirstDirectStart: true,
      startResult: attemptRecord(
        evidenceStates: authoritativeStatesFor(directEvidence),
      ),
    );
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        method: 'direct_english_construction',
        stages: directStages,
        evidence: directEvidence,
        conversations: directConversations,
      ),
      apiService: api,
    );
    await tester.enterText(
      find.byKey(const Key('direct-english-guided-text')),
      'I am Alex.',
    );
    await tester.tap(find.byKey(const Key('direct-english-guided-save-text')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('direct-english-guided-save-text')));
    await tester.pumpAndSettle();

    expect(api.startedDirectIds, [
      'direct-english:experience-attempt-1',
      'direct-english:experience-attempt-1',
    ]);
    expect(find.byKey(const Key('experience-completed')), findsNothing);
  });

  testWidgets('technical pronunciation UI never completes evidence locally', (
    tester,
  ) async {
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [
          LessonExperienceStage(
            id: 'encounter',
            type: 'encounter',
            instruction: 'Listen and repeat',
            activityIds: [],
            mode: 'required',
            completionCondition: 'acknowledged',
          ),
        ],
        reinforcement: const LessonPronunciationReinforcement(
          stageId: 'encounter',
          referenceText: 'Hello',
          listeningObjective: 'Listen to the rhythm',
          shadowing: true,
          pronunciations: [
            LessonPronunciation(
              locale: 'en-US',
              ipa: '/həˈloʊ/',
              audioAsset: 'audio/hello.wav',
            ),
          ],
          phoneticTargets: ['/ə/'],
        ),
      ),
      apiService: FakeExperienceApiService(),
    );

    expect(find.text('Listen to the rhythm'), findsOneWidget);
    expect(find.byKey(const Key('experience-completed')), findsNothing);
    expect(find.textContaining('satisfied'), findsNothing);
  });

  testWidgets('lesson screen branches v2 while legacy remains unchanged', (
    tester,
  ) async {
    final v2Api = FakeExperienceApiService(lessonResult: v2Lesson());
    await tester.pumpWidget(
      MaterialApp(
        home: LessonDetailScreen(
          lessonId: 'lesson-v2',
          levelId: 'A1',
          unitId: 'a1-u1',
          apiService: v2Api,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LessonExperienceCard), findsOneWidget);
    expect(find.byType(LessonDetailCard), findsNothing);

    final legacy = const Lesson(
      id: 'legacy',
      title: 'Legacy',
      vocabulary: [],
      grammar: [],
      examples: [],
      exercises: [],
    );
    final legacyApi = FakeExperienceApiService(lessonResult: legacy);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonDetailScreen(
          lessonId: 'legacy',
          levelId: 'A1',
          unitId: 'a1-u1',
          apiService: legacyApi,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LessonDetailCard), findsOneWidget);
    expect(find.byType(LessonExperienceCard), findsNothing);
  });

  testWidgets('v2 renderer never consumes B183 demo identities', (
    tester,
  ) async {
    await pumpExperience(
      tester,
      lesson: v2Lesson(
        stages: const [
          LessonExperienceStage(
            id: 'real-stage',
            type: 'closure',
            instruction: 'Real backend stage',
            activityIds: [],
            mode: 'required',
            completionCondition: 'acknowledged',
          ),
        ],
      ),
      apiService: FakeExperienceApiService(),
    );

    expect(find.textContaining('demo-visual-'), findsNothing);
    expect(find.text('Real backend stage'), findsOneWidget);
  });
}
