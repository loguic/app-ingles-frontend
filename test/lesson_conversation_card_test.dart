import 'dart:async';

import 'package:app_ingles/models/lesson.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/services/speech_recognition_service.dart';
import 'package:app_ingles/widgets/lesson_conversation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates audio without activating native plugins.
/// Simula audio sin activar complementos nativos.
class FakeConversationAudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _completed = StreamController<String>.broadcast();
  final _recording = StreamController<String?>.broadcast();
  final List<String> deletedRecordingPaths = [];

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
    _playback.add(activePlaybackId);
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    activePlaybackId = playbackId;
    _playback.add(activePlaybackId);
  }

  @override
  Future<void> stopPlayback() async {
    activePlaybackId = null;
    _playback.add(null);
  }

  void completePlayback() {
    final completedId = activePlaybackId;
    activePlaybackId = null;
    _playback.add(null);
    if (completedId != null) _completed.add(completedId);
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
    return '/tmp/conversation-test.wav';
  }

  @override
  Future<void> cancelRecording() async {
    activeRecordingId = null;
    _recording.add(null);
  }

  @override
  Future<void> deleteRecording(String path) async {
    deletedRecordingPaths.add(path);
  }

  @override
  Future<void> dispose() async {
    await _playback.close();
    await _completed.close();
    await _recording.close();
  }
}

/// Simulates speech recognition without activating Sherpa-ONNX.
/// Simula reconocimiento de voz sin activar Sherpa-ONNX.
class FakeSpeechRecognitionController implements SpeechRecognitionController {
  SpeechRecognitionRequest? lastRequest;

  @override
  Future<SpeechRecognitionResult> recognize(
    SpeechRecognitionRequest request,
  ) async {
    lastRequest = request;

    return SpeechRecognitionResult(
      status: SpeechRecognitionStatus.recognized,
      languageCode: request.languageCode,
      userId: request.userId,
      levelId: request.levelId,
      unitId: request.unitId,
      lessonId: request.lessonId,
      conversationId: request.conversationId,
      turnId: request.turnId,
      promptId: request.promptId,
      locale: request.locale,
      transcript: 'Hello, I am John.',
      words: const ['Hello', 'I', 'am', 'John'],
    );
  }
}

/// Simulates successful persistence without network access.
/// Simula persistencia correcta sin acceder a la red.
class FakeConversationApiService extends ApiService {
  FakeConversationApiService({
    this.saveResult = true,
    this.throwOnSave = false,
    this.failedUploadAttemptsRemaining = 0,
  });

  final bool saveResult;
  final bool throwOnSave;
  int failedUploadAttemptsRemaining;

  int saveCallCount = 0;
  String? lastUserId;
  String? lastLevelId;
  String? lastUnitId;
  String? lastLessonId;
  String? lastConversationId;
  String? lastMode;
  List<String>? lastVisitedTurnIds;
  List<String>? lastSelectedChoiceIds;
  int uploadCallCount = 0;
  int productionSubmissionCallCount = 0;
  final List<String> uploadedPaths = [];
  List<Map<String, dynamic>>? submittedProductions;

  @override
  String? get lastConversationProductionAudioUploadError =>
      failedUploadAttemptsRemaining > 0
      ? null
      : 'PRODUCTION_AUDIO_DIR is not configured';

  @override
  Future<bool> saveConversationAttempt({
    required String userId,
    required String levelId,
    required String unitId,
    required String lessonId,
    required String conversationId,
    required String mode,
    required List<String> visitedTurnIds,
    required List<String> selectedChoiceIds,
  }) async {
    saveCallCount += 1;
    lastUserId = userId;
    lastLevelId = levelId;
    lastUnitId = unitId;
    lastLessonId = lessonId;
    lastConversationId = conversationId;
    lastMode = mode;
    lastVisitedTurnIds = List<String>.from(visitedTurnIds);
    lastSelectedChoiceIds = List<String>.from(selectedChoiceIds);

    if (throwOnSave) {
      throw Exception("Simulated network failure");
    }

    return saveResult;
  }

  @override
  Future<String?> uploadConversationProductionAudio(String audioPath) async {
    uploadCallCount += 1;
    uploadedPaths.add(audioPath);
    if (failedUploadAttemptsRemaining > 0) {
      failedUploadAttemptsRemaining -= 1;
      return null;
    }
    return 'production-audio://$uploadCallCount';
  }

  @override
  Future<bool> saveConversationProductions({
    required String userId,
    required String levelId,
    required String unitId,
    required String lessonId,
    required String conversationId,
    required List<Map<String, dynamic>> productions,
  }) async {
    productionSubmissionCallCount += 1;
    submittedProductions = productions;
    return saveResult;
  }
}

class SequencedConversationAudioController
    extends FakeConversationAudioController {
  int stopCount = 0;

  @override
  Future<String?> stopRecording() async {
    await super.stopRecording();
    stopCount += 1;
    return '/tmp/b181-$stopCount.wav';
  }
}

const conversation = Conversation(
  id: 'conversation-test',
  title: 'Meeting someone',
  context: 'Greet someone and introduce yourself.',
  turns: [
    ConversationTurn(
      id: 'partner-turn',
      speaker: 'partner',
      en: 'Hello! What is your name?',
      es: '¡Hola! ¿Cómo te llamas?',
      pronunciations: [
        LessonPronunciation(
          locale: 'en-US',
          ipa: 'test us',
          audioAsset: 'audio/partner-us.wav',
        ),
        LessonPronunciation(
          locale: 'en-GB',
          ipa: 'test uk',
          audioAsset: 'audio/partner-uk.wav',
        ),
      ],
    ),
    ConversationTurn(
      id: 'learner-turn',
      speaker: 'learner',
      en: 'Hello, I am John.',
      es: 'Hola, soy John.',
    ),
  ],
);

const branchingConversation = Conversation(
  id: "branching-conversation-test",
  title: "How are you?",
  mode: "branching",
  startTurnId: "partner-start",
  turns: [
    ConversationTurn(
      id: "partner-start",
      speaker: "partner",
      en: "Hello. How are you?",
      es: "Hola. ¿Cómo estás?",
      nextTurnId: "learner-choice",
    ),
    ConversationTurn(
      id: "learner-choice",
      speaker: "learner",
      en: "Choose your answer.",
      choices: [
        ConversationChoice(
          id: "choice-fine",
          en: "I am fine, thank you.",
          es: "Estoy bien, gracias.",
          nextTurnId: "partner-fine",
        ),
        ConversationChoice(
          id: "choice-tired",
          en: "I am tired today.",
          es: "Estoy cansado hoy.",
          nextTurnId: "partner-tired",
        ),
      ],
    ),
    ConversationTurn(
      id: "partner-fine",
      speaker: "partner",
      en: "That is good to hear.",
    ),
    ConversationTurn(
      id: "partner-tired",
      speaker: "partner",
      en: "I hope you can rest.",
    ),
  ],
);

const b181Conversation = Conversation(
  id: 'a1-u1-l2-c1',
  title: 'Keep the conversation going',
  mode: 'free',
  audioFirstPolicy: AudioFirstPresentationPolicy(
    primaryPresentation: 'audio',
    audioReplayAllowed: true,
    transcriptInitiallyHidden: true,
    transcriptAccess: 'contingency_accessibility',
    transcriptUseInterpretation: 'assisted_not_exclusively_auditory',
    transcriptIsAnswerModel: false,
  ),
  turns: [
    ConversationTurn(
      id: 't1',
      speaker: 'partner',
      en: 'Where are you from?',
      pronunciations: [
        LessonPronunciation(
          locale: 'en-US',
          ipa: 't1',
          audioAsset: 'audio/t1.wav',
        ),
      ],
      nextTurnId: 't2',
    ),
    ConversationTurn(
      id: 't2',
      speaker: 'learner',
      en: 'Answer about your place.',
      productionPrompt: LearnerProductionPrompt(
        id: 'p1',
        acceptedModalities: ['voice', 'text'],
        primaryModality: 'voice',
        supportLevel: 'anchors',
        visibleSupport: ['Place', 'I am from'],
      ),
      nextTurnId: 't3',
    ),
    ConversationTurn(
      id: 't3',
      speaker: 'partner',
      en: 'What do you like doing?',
      pronunciations: [
        LessonPronunciation(
          locale: 'en-US',
          ipa: 't3',
          audioAsset: 'audio/t3.wav',
        ),
      ],
      nextTurnId: 't4',
    ),
    ConversationTurn(
      id: 't4',
      speaker: 'learner',
      en: 'Answer about an interest.',
      productionPrompt: LearnerProductionPrompt(
        id: 'p2',
        acceptedModalities: ['voice', 'text'],
        primaryModality: 'voice',
        supportLevel: 'initial_word',
        visibleSupport: ['I'],
      ),
      nextTurnId: 't5',
    ),
    ConversationTurn(
      id: 't5',
      speaker: 'partner',
      en: 'Where do you usually do that?',
      pronunciations: [
        LessonPronunciation(
          locale: 'en-US',
          ipa: 't5',
          audioAsset: 'audio/t5.wav',
        ),
      ],
      nextTurnId: 't6',
    ),
    ConversationTurn(
      id: 't6',
      speaker: 'learner',
      en: 'React in your own words.',
      productionPrompt: LearnerProductionPrompt(
        id: 'p3',
        acceptedModalities: ['voice', 'text'],
        primaryModality: 'voice',
        supportLevel: 'none',
      ),
      nextTurnId: 't7',
    ),
    ConversationTurn(
      id: 't7',
      speaker: 'partner',
      en: 'It was nice talking with you. See you!',
      pronunciations: [
        LessonPronunciation(
          locale: 'en-US',
          ipa: 't7',
          audioAsset: 'audio/t7.wav',
        ),
      ],
      interactionFunction: 'reaction_closure',
    ),
  ],
);

void main() {
  testWidgets('completes and restarts a guided conversation', (tester) async {
    final audioController = FakeConversationAudioController();
    final apiService = FakeConversationApiService();
    final speechRecognitionController = FakeSpeechRecognitionController();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: conversation,
              levelId: "A1",
              unitId: "a1-u1",
              lessonId: "a1-u1-l1",
              userId: "test-user-b101",
              audioService: audioController,
              apiService: apiService,
              speechRecognitionController: speechRecognitionController,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Turno 1 de 2'), findsOneWidget);
    expect(find.text('Estados Unidos'), findsOneWidget);
    expect(find.text('Reino Unido'), findsOneWidget);

    await tester.tap(find.text('Escuchar al interlocutor'));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();

    expect(find.text('¡Hola! ¿Cómo te llamas?'), findsOneWidget);
    await tester.tap(find.text('Entendí, continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Turno 2 de 2'), findsOneWidget);
    await tester.tap(find.text('Grabar mi respuesta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();

    final recognitionRequest = speechRecognitionController.lastRequest;
    expect(recognitionRequest, isNotNull);
    expect(recognitionRequest!.audioPath, '/tmp/conversation-test.wav');
    expect(recognitionRequest.languageCode, 'en');
    expect(recognitionRequest.userId, 'test-user-b101');
    expect(recognitionRequest.levelId, 'A1');
    expect(recognitionRequest.unitId, 'a1-u1');
    expect(recognitionRequest.lessonId, 'a1-u1-l1');
    expect(recognitionRequest.conversationId, 'conversation-test');
    expect(recognitionRequest.turnId, 'learner-turn');
    expect(recognitionRequest.promptId, isNull);
    expect(recognitionRequest.locale, isNull);
    expect(find.text('Reconocido: Hello, I am John.'), findsOneWidget);
    expect(find.text('Escucha tu voz antes de avanzar.'), findsOneWidget);
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Avanzar al siguiente turno'));
    await tester.tap(find.text('Avanzar al siguiente turno'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación completada'), findsOneWidget);
    expect(find.text('Progreso conversacional guardado.'), findsOneWidget);
    expect(find.text('Repetir conversación'), findsOneWidget);
    expect(apiService.saveCallCount, 1);
    expect(apiService.lastUserId, "test-user-b101");
    expect(apiService.lastLevelId, "A1");
    expect(apiService.lastUnitId, "a1-u1");
    expect(apiService.lastLessonId, "a1-u1-l1");
    expect(apiService.lastConversationId, "conversation-test");
    expect(apiService.lastMode, "guided");
    expect(apiService.lastVisitedTurnIds, ["partner-turn", "learner-turn"]);
    expect(apiService.lastSelectedChoiceIds, isEmpty);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(apiService.saveCallCount, 1);

    await tester.tap(find.text('Repetir conversación'));
    await tester.pumpAndSettle();

    expect(find.text('Turno 1 de 2'), findsOneWidget);
    expect(find.text('Escuchar al interlocutor'), findsOneWidget);
    expect(find.text('Conversación completada'), findsNothing);

    await tester.tap(find.text('Escuchar al interlocutor'));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendí, continuar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Grabar mi respuesta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Avanzar al siguiente turno'));
    await tester.tap(find.text('Avanzar al siguiente turno'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación completada'), findsOneWidget);
    expect(find.text('Progreso conversacional guardado.'), findsOneWidget);
    expect(apiService.saveCallCount, 2);
  });

  testWidgets("follows the selected conversation branch", (tester) async {
    final audioController = FakeConversationAudioController();
    final apiService = FakeConversationApiService();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: branchingConversation,
              levelId: "A1",
              unitId: "a1-u1",
              lessonId: "a1-u1-l1",
              userId: "test-user-b101",
              audioService: audioController,
              apiService: apiService,
            ),
          ),
        ),
      ),
    );

    expect(find.text("Hello. How are you?"), findsOneWidget);

    await tester.tap(find.text("Continuar sin audio"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Entendí, continuar"));
    await tester.pumpAndSettle();

    expect(
      find.text("Elige la respuesta que quieres practicar:"),
      findsOneWidget,
    );
    expect(find.text("I am fine, thank you."), findsOneWidget);
    expect(find.text("I am tired today."), findsOneWidget);

    await tester.tap(find.text("I am tired today."));
    await tester.pumpAndSettle();

    expect(find.text("Estoy cansado hoy."), findsOneWidget);
    await tester.tap(find.text("Grabar mi respuesta"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Detener grabación"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Reproducir mi voz"));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Avanzar al siguiente turno"));
    await tester.tap(find.text("Avanzar al siguiente turno"));
    await tester.pumpAndSettle();

    expect(find.text("I hope you can rest."), findsOneWidget);
    expect(find.text("That is good to hear."), findsNothing);

    await tester.tap(find.text("Continuar sin audio"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Entendí, continuar"));
    await tester.pumpAndSettle();

    expect(find.text("Conversación completada"), findsOneWidget);
    expect(find.text("Progreso conversacional guardado."), findsOneWidget);
    expect(find.text("Repetir conversación"), findsOneWidget);
    expect(apiService.saveCallCount, 1);
    expect(apiService.lastUserId, "test-user-b101");
    expect(apiService.lastLevelId, "A1");
    expect(apiService.lastUnitId, "a1-u1");
    expect(apiService.lastLessonId, "a1-u1-l1");
    expect(apiService.lastConversationId, "branching-conversation-test");
    expect(apiService.lastMode, "branching");
    expect(apiService.lastVisitedTurnIds, [
      "partner-start",
      "learner-choice",
      "partner-tired",
    ]);
    expect(apiService.lastSelectedChoiceIds, ["choice-tired"]);

    await tester.tap(find.text("Repetir conversación"));
    await tester.pumpAndSettle();

    expect(find.text("Hello. How are you?"), findsOneWidget);
    expect(find.text("Conversación completada"), findsNothing);
    expect(find.text("Estoy cansado hoy."), findsNothing);
  });
  testWidgets("keeps completion available when persistence fails", (
    tester,
  ) async {
    final audioController = FakeConversationAudioController();
    final apiService = FakeConversationApiService(throwOnSave: true);
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: conversation,
              levelId: "A1",
              unitId: "a1-u1",
              lessonId: "a1-u1-l1",
              userId: "test-user-b101",
              audioService: audioController,
              apiService: apiService,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Escuchar al interlocutor"));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();
    await tester.tap(find.text("Entendí, continuar"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Grabar mi respuesta"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Detener grabación"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reproducir mi voz"));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Avanzar al siguiente turno"));
    await tester.tap(find.text("Avanzar al siguiente turno"));
    await tester.pumpAndSettle();

    expect(find.text("Conversación completada"), findsOneWidget);
    expect(
      find.text(
        "La conversación terminó, pero no se pudo guardar el progreso.",
      ),
      findsOneWidget,
    );
    expect(apiService.saveCallCount, 1);
    expect(find.text("Repetir conversación"), findsOneWidget);

    await tester.tap(find.text("Repetir conversación"));
    await tester.pumpAndSettle();

    expect(find.text("Turno 1 de 2"), findsOneWidget);
    expect(find.text("Conversación completada"), findsNothing);
  });

  testWidgets('runs B181 audio-first and submits three voice productions', (
    tester,
  ) async {
    final audioController = SequencedConversationAudioController();
    final apiService = FakeConversationApiService();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: b181Conversation,
              levelId: 'A1',
              unitId: 'a1-u1',
              lessonId: 'a1-u1-l2',
              userId: 'b181-user',
              audioService: audioController,
              apiService: apiService,
            ),
          ),
        ),
      ),
    );

    Future<void> completePartnerTurn({bool revealTranscript = false}) async {
      expect(find.text('Escucha primero la intervención.'), findsOneWidget);
      expect(find.text('Mostrar transcript por accesibilidad'), findsNothing);
      await tester.tap(find.text('Escuchar al interlocutor'));
      await tester.pumpAndSettle();
      audioController.completePlayback();
      await tester.pumpAndSettle();
      expect(find.text('Volver a escuchar'), findsOneWidget);
      expect(find.text('Mostrar transcript por accesibilidad'), findsOneWidget);
      if (revealTranscript) {
        await tester.tap(find.text('Mostrar transcript por accesibilidad'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Entendí, continuar'));
      await tester.pumpAndSettle();
    }

    Future<void> completeLearnerTurn({
      required String instruction,
      required String supportHeading,
    }) async {
      expect(find.text('Responde con tus palabras'), findsOneWidget);
      expect(find.text('Tu respuesta'), findsNothing);
      expect(find.text('Qué debes hacer'), findsOneWidget);
      expect(find.text(instruction), findsOneWidget);
      expect(
        find.text(
          'Responde con información propia. No repitas la instrucción.',
        ),
        findsOneWidget,
      );
      if (supportHeading.isNotEmpty) {
        expect(find.text(supportHeading), findsOneWidget);
      }
      await tester.tap(find.text('Grabar mi respuesta'));
      await tester.pumpAndSettle();
      expect(find.text('Qué debes hacer'), findsOneWidget);
      expect(find.text(instruction), findsOneWidget);
      expect(
        find.text(
          'Responde con información propia. No repitas la instrucción.',
        ),
        findsOneWidget,
      );
      if (supportHeading.isNotEmpty) {
        expect(find.text(supportHeading), findsOneWidget);
      }
      await tester.tap(find.text('Detener grabación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir mi voz'));
      await tester.pumpAndSettle();
      audioController.completePlayback();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Avanzar al siguiente turno'));
      await tester.tap(find.text('Avanzar al siguiente turno'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Where are you from?'), findsNothing);
    await completePartnerTurn(revealTranscript: true);
    expect(find.text('Palabras que pueden ayudarte'), findsOneWidget);
    expect(
      find.text('Úsalas como guía. No tienes que repetirlas exactamente.'),
      findsOneWidget,
    );
    expect(find.text('Place'), findsOneWidget);
    expect(find.text('I am from'), findsOneWidget);
    await completeLearnerTurn(
      instruction: 'Answer about your place.',
      supportHeading: 'Palabras que pueden ayudarte',
    );

    expect(find.text('What do you like doing?'), findsNothing);
    await completePartnerTurn();
    expect(find.text('Puedes empezar con…'), findsOneWidget);
    expect(find.text('Continúa con tu propia información.'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('Place'), findsNothing);
    await completeLearnerTurn(
      instruction: 'Answer about an interest.',
      supportHeading: 'Puedes empezar con…',
    );

    expect(find.text('Where do you usually do that?'), findsNothing);
    await completePartnerTurn();
    expect(find.text('Apoyo disponible'), findsNothing);
    expect(find.text('Palabras que pueden ayudarte'), findsNothing);
    expect(find.text('Puedes empezar con…'), findsNothing);
    expect(find.text('Place'), findsNothing);
    expect(find.text('I am from'), findsNothing);
    expect(find.text('I'), findsNothing);
    await completeLearnerTurn(
      instruction: 'React in your own words.',
      supportHeading: '',
    );

    expect(find.text('It was nice talking with you. See you!'), findsNothing);
    await completePartnerTurn();
    await tester.pumpAndSettle();

    expect(apiService.saveCallCount, 0);
    expect(apiService.uploadCallCount, 3);
    expect(apiService.productionSubmissionCallCount, 1);
    expect(apiService.uploadedPaths, [
      '/tmp/b181-1.wav',
      '/tmp/b181-2.wav',
      '/tmp/b181-3.wav',
    ]);
    expect(audioController.deletedRecordingPaths, [
      '/tmp/b181-1.wav',
      '/tmp/b181-2.wav',
      '/tmp/b181-3.wav',
    ]);
    expect(apiService.submittedProductions, [
      {
        'prompt_id': 'p1',
        'turn_id': 't2',
        'modality': 'voice',
        'audio_reference': 'production-audio://1',
      },
      {
        'prompt_id': 'p2',
        'turn_id': 't4',
        'modality': 'voice',
        'audio_reference': 'production-audio://2',
      },
      {
        'prompt_id': 'p3',
        'turn_id': 't6',
        'modality': 'voice',
        'audio_reference': 'production-audio://3',
      },
    ]);
    expect(find.text('Conversación completada'), findsOneWidget);
    expect(
      find.text(
        'Tres respuestas guardadas. Esto no implica comprensión ni progreso.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('retries one failed B181 save with the retained recordings', (
    tester,
  ) async {
    final audioController = SequencedConversationAudioController();
    final apiService = FakeConversationApiService(
      failedUploadAttemptsRemaining: 2,
    );
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: b181Conversation,
              levelId: 'A1',
              unitId: 'a1-u1',
              lessonId: 'a1-u1-l2',
              userId: 'b181-user',
              audioService: audioController,
              apiService: apiService,
            ),
          ),
        ),
      ),
    );

    Future<void> completePartnerTurn() async {
      await tester.tap(find.text('Escuchar al interlocutor'));
      await tester.pumpAndSettle();
      audioController.completePlayback();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entendí, continuar'));
      await tester.pumpAndSettle();
    }

    Future<void> completeLearnerTurn() async {
      await tester.tap(find.text('Grabar mi respuesta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Detener grabación'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reproducir mi voz'));
      await tester.pumpAndSettle();
      audioController.completePlayback();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Avanzar al siguiente turno'));
      await tester.tap(find.text('Avanzar al siguiente turno'));
      await tester.pumpAndSettle();
    }

    for (var index = 0; index < 3; index += 1) {
      await completePartnerTurn();
      await completeLearnerTurn();
    }
    await completePartnerTurn();
    await tester.pumpAndSettle();

    expect(find.text('Conversación recorrida'), findsOneWidget);
    expect(find.text('Reintentar guardado'), findsOneWidget);
    expect(audioController.deletedRecordingPaths, isEmpty);
    expect(apiService.productionSubmissionCallCount, 0);

    await tester.tap(find.text('Reintentar guardado'));
    await tester.pumpAndSettle();

    expect(find.text('Reintentar guardado'), findsOneWidget);
    expect(audioController.deletedRecordingPaths, isEmpty);
    expect(apiService.productionSubmissionCallCount, 0);
    expect(
      find.text(
        'No se pudo subir el audio: PRODUCTION_AUDIO_DIR is not configured',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Reintentar guardado'));
    await tester.pumpAndSettle();

    expect(apiService.uploadCallCount, 5);
    expect(apiService.productionSubmissionCallCount, 1);
    expect(audioController.deletedRecordingPaths, [
      '/tmp/b181-1.wav',
      '/tmp/b181-2.wav',
      '/tmp/b181-3.wav',
    ]);
    expect(find.text('Reintentar guardado'), findsNothing);
    expect(find.text('Conversación completada'), findsOneWidget);
    expect(
      find.text(
        'Tres respuestas guardadas. Esto no implica comprensión ni progreso.',
      ),
      findsOneWidget,
    );
  });
}
