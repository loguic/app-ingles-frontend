import 'dart:async';

import 'package:app_ingles/models/lesson.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/widgets/lesson_conversation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates audio without activating native plugins.
/// Simula audio sin activar complementos nativos.
class FakeConversationAudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _recording = StreamController<String?>.broadcast();

  @override
  String? activePlaybackId;

  @override
  String? activeRecordingId;

  @override
  Stream<String?> get onPlaybackChanged => _playback.stream;

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
    return '/tmp/conversation-test.wav';
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
    await _recording.close();
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

void main() {
  testWidgets('completes and restarts a guided conversation', (tester) async {
    final audioController = FakeConversationAudioController();
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
              audioService: audioController,
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

    expect(find.text('Escucha tu voz antes de avanzar.'), findsOneWidget);
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pumpAndSettle();
    audioController.completePlayback();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Avanzar al siguiente turno'));
    await tester.tap(find.text('Avanzar al siguiente turno'));
    await tester.pumpAndSettle();

    expect(find.text('Conversación completada'), findsOneWidget);
    expect(find.text('Repetir conversación'), findsOneWidget);

    await tester.tap(find.text('Repetir conversación'));
    await tester.pumpAndSettle();

    expect(find.text('Turno 1 de 2'), findsOneWidget);
    expect(find.text('Escuchar al interlocutor'), findsOneWidget);
    expect(find.text('Conversación completada'), findsNothing);
  });

  testWidgets("follows the selected conversation branch", (tester) async {
    final audioController = FakeConversationAudioController();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: branchingConversation,
              audioService: audioController,
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
    expect(find.text("Repetir conversación"), findsOneWidget);

    await tester.tap(find.text("Repetir conversación"));
    await tester.pumpAndSettle();

    expect(find.text("Hello. How are you?"), findsOneWidget);
    expect(find.text("Conversación completada"), findsNothing);
    expect(find.text("Estoy cansado hoy."), findsNothing);
  });
}
