import 'dart:async';

import 'package:app_ingles/models/visual_demo_content.dart';
import 'package:app_ingles/screens/main_shell_screen.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/theme/loguic_theme.dart';
import 'package:app_ingles/widgets/lesson_conversation_card.dart';
import 'package:app_ingles/widgets/lesson_pronunciation_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DemoAudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _completed = StreamController<String>.broadcast();
  final _recording = StreamController<String?>.broadcast();

  final List<String> deletedPaths = [];
  bool failNextReference = false;

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
    if (failNextReference) {
      failNextReference = false;
      activePlaybackId = null;
      _playback.add(null);
      throw StateError('reference playback failed');
    }
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  void completePlayback() {
    final completedId = activePlaybackId;
    activePlaybackId = null;
    _playback.add(null);
    if (completedId != null) _completed.add(completedId);
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
    return '/tmp/demo-visual-recording.wav';
  }

  @override
  Future<void> cancelRecording() async {
    activeRecordingId = null;
    _recording.add(null);
  }

  @override
  Future<void> deleteRecording(String path) async {
    deletedPaths.add(path);
  }

  @override
  Future<void> dispose() async {
    await _playback.close();
    await _completed.close();
    await _recording.close();
  }
}

class WriteSpyApiService extends ApiService {
  int writeCalls = 0;

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
    writeCalls += 1;
    return true;
  }

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
    writeCalls += 1;
    return true;
  }

  @override
  Future<String?> uploadConversationProductionAudio(String audioPath) async {
    writeCalls += 1;
    return 'production-audio://should-not-exist';
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
    writeCalls += 1;
    return true;
  }
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  test('uses only the demo namespace for presentation identities', () {
    final ids = <String>[
      visualDemoContent.id,
      visualDemoContent.conversation.id,
      ...visualDemoContent.conversation.turns.map((turn) => turn.id),
      ...visualDemoContent.conversation.turns
          .map((turn) => turn.productionPrompt?.id)
          .whereType<String>(),
    ];

    expect(ids, isNotEmpty);
    expect(ids.every((id) => id.startsWith('demo-visual-')), isTrue);
    expect(ids.any((id) => id.contains('a1-u1-l1')), isFalse);
    expect(
      visualDemoContent.conversation.turns.first.pronunciations
          .map((pronunciation) => pronunciation.audioAsset),
      everyElement(startsWith('audio/')),
    );
  });

  testWidgets('runs the visual route with contingent listening support', (
    tester,
  ) async {
    _setViewport(tester, const Size(700, 1100));
    final audioController = DemoAudioController();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: LoguicTheme.light,
        home: MainShellScreen(demoAudioController: audioController),
      ),
    );

    expect(find.text('Explorar demostración'), findsOneWidget);
    expect(find.text(visualDemoNotice), findsOneWidget);

    await tester.tap(find.text('Explorar demostración'));
    await tester.pump();

    expect(find.text(visualDemoNotice), findsOneWidget);
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      expect(find.text(level), findsOneWidget);
    }
    expect(find.text('Demostración disponible'), findsOneWidget);
    expect(find.text('Horizonte del producto'), findsNWidgets(5));
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('mastery'), findsNothing);

    await tester.tap(find.byKey(const Key('visual-level-A1')));
    await tester.pumpAndSettle();

    expect(find.text(visualDemoNotice), findsOneWidget);
    expect(find.byKey(const Key('demo-visual-context')), findsOneWidget);
    expect(find.text('Abrir escucha y pronunciación'), findsOneWidget);
    expect(find.text('Abrir conversación breve'), findsOneWidget);

    await tester.tap(find.text('Abrir escucha y pronunciación'));
    await tester.pumpAndSettle();

    expect(find.text(visualDemoNotice), findsOneWidget);
    expect(find.text(visualDemoContent.transcript), findsNothing);
    expect(find.text(visualDemoContent.translation), findsNothing);
    expect(find.text('Mostrar transcript'), findsNothing);
    expect(find.text('Ver traducción de rescate'), findsNothing);

    await tester.tap(find.byTooltip('Escuchar pronunciación').first);
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();

    expect(find.byKey(const Key('demo-listening-hint')), findsOneWidget);
    expect(find.text('Mostrar transcript'), findsOneWidget);
    expect(find.text(visualDemoContent.transcript), findsNothing);
    expect(find.text(visualDemoContent.translation), findsNothing);

    await tester.tap(find.text('Mostrar transcript'));
    await tester.pump();

    expect(find.text(visualDemoContent.transcript), findsOneWidget);
    expect(find.text('Ver traducción de rescate'), findsOneWidget);
    expect(find.text(visualDemoContent.translation), findsNothing);

    await tester.tap(find.text('Ver traducción de rescate'));
    await tester.pump();

    expect(find.text(visualDemoContent.translation), findsOneWidget);

    await tester.ensureVisible(find.text('Volver a la portada demo'));
    await tester.tap(find.text('Volver a la portada demo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Abrir conversación breve'));
    await tester.tap(find.text('Abrir conversación breve'));
    await tester.pumpAndSettle();

    expect(find.text(visualDemoNotice), findsOneWidget);
    expect(find.text('Prueba una respuesta personal'), findsOneWidget);
    await tester.ensureVisible(find.text('Volver a la portada demo'));
    await tester.tap(find.text('Volver a la portada demo'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Volver al mapa'));
    await tester.tap(find.text('Volver al mapa'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Volver a Inicio'));
    await tester.tap(find.text('Volver a Inicio'));
    await tester.pump();

    expect(find.text('Explorar demostración'), findsOneWidget);
  });

  testWidgets('demo conversation completes without any API write', (
    tester,
  ) async {
    _setViewport(tester, const Size(700, 1100));
    final audioController = DemoAudioController();
    final apiService = WriteSpyApiService();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: LoguicTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: visualDemoContent.conversation,
              levelId: 'demo-visual-a1',
              unitId: 'demo-visual-a1-situation',
              lessonId: visualDemoContent.id,
              userId: 'demo-visual-local-user',
              audioService: audioController,
              apiService: apiService,
              persistencePolicy: ConversationPersistencePolicy.disabled,
              demoMode: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text(visualDemoContent.transcript), findsNothing);
    expect(find.byKey(const Key('demo-conversation-hint')), findsNothing);

    await tester.tap(find.text('Escuchar al interlocutor'));
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();

    expect(find.byKey(const Key('demo-conversation-hint')), findsOneWidget);
    expect(find.text('Mostrar transcript'), findsOneWidget);
    expect(find.text(visualDemoContent.translation), findsNothing);

    await tester.tap(find.text('Mostrar transcript'));
    await tester.pump();
    expect(find.text(visualDemoContent.transcript), findsOneWidget);
    expect(find.text('Ver traducción de rescate'), findsOneWidget);
    expect(find.text(visualDemoContent.translation), findsNothing);

    await tester.tap(find.text('Ver traducción de rescate'));
    await tester.pump();
    expect(find.text(visualDemoContent.translation), findsOneWidget);

    await tester.tap(find.text('Seguir a mi respuesta'));
    await tester.pump();
    await tester.tap(find.text('Grabar mi respuesta'));
    await tester.pump();
    await tester.tap(find.text('Detener grabación'));
    await tester.pump();
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();
    await tester.tap(find.text('Avanzar al siguiente turno'));
    await tester.pump();

    expect(find.text('Demostración conversacional recorrida'), findsOneWidget);
    expect(
      find.text('Este recorrido no guarda resultados ni evalúa tu respuesta.'),
      findsOneWidget,
    );
    expect(find.textContaining('mastery'), findsNothing);
    expect(find.textContaining('Progreso conversacional'), findsNothing);
    expect(apiService.writeCalls, 0);
    expect(audioController.deletedPaths, ['/tmp/demo-visual-recording.wav']);
  });

  testWidgets('demo mode disables writes when persistence policy is omitted', (
    tester,
  ) async {
    _setViewport(tester, const Size(700, 1100));
    final audioController = DemoAudioController();
    final apiService = WriteSpyApiService();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: LoguicTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonConversationCard(
              conversation: visualDemoContent.conversation,
              levelId: 'demo-visual-a1',
              unitId: 'demo-visual-a1-situation',
              lessonId: visualDemoContent.id,
              userId: 'demo-visual-local-user',
              audioService: audioController,
              apiService: apiService,
              demoMode: true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Escuchar al interlocutor'));
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();
    await tester.tap(find.text('Seguir a mi respuesta'));
    await tester.pump();
    await tester.tap(find.text('Grabar mi respuesta'));
    await tester.pump();
    await tester.tap(find.text('Detener grabación'));
    await tester.pump();
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();
    await tester.tap(find.text('Avanzar al siguiente turno'));
    await tester.pump();

    expect(find.text('Demostración conversacional recorrida'), findsOneWidget);
    expect(apiService.writeCalls, 0);
    expect(audioController.deletedPaths, ['/tmp/demo-visual-recording.wav']);
  });

  testWidgets('demo pronunciation keeps self-assessment neutral', (
    tester,
  ) async {
    final audioController = DemoAudioController();
    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LessonPronunciationControls(
            exampleId: '${visualDemoContent.id}-neutral-copy',
            pronunciations: visualDemoContent.pronunciations,
            audioService: audioController,
            demoMode: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Escuchar pronunciación').first);
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();
    await tester.tap(find.text('Grabar mi voz'));
    await tester.pump();
    await tester.tap(find.text('Detener grabación'));
    await tester.pump();
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();
    await tester.tap(find.text('Casi, necesito practicar'));
    await tester.pump();

    expect(
      find.text('Puedes probar otra vez, más despacio y sin puntuación.'),
      findsOneWidget,
    );
    expect(find.textContaining('aprendizaje'), findsNothing);
    expect(find.textContaining('consolid'), findsNothing);
    expect(find.textContaining('mastery'), findsNothing);
    expect(find.textContaining('progreso'), findsNothing);
  });

  testWidgets('failed partner playback keeps audio-first controls locked', (
    tester,
  ) async {
    final audioController = DemoAudioController()..failNextReference = true;
    addTearDown(audioController.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: LoguicTheme.light,
      home: Scaffold(
        body: LessonConversationCard(
          conversation: visualDemoContent.conversation,
          levelId: 'demo-visual-a1',
          unitId: 'demo-visual-a1-situation',
          lessonId: visualDemoContent.id,
          userId: 'demo-visual-local-user',
          audioService: audioController,
          demoMode: true,
        ),
      ),
    ));
    await tester.tap(find.text('Escuchar al interlocutor'));
    await tester.pump();
    expect(find.text('No se pudo reproducir al interlocutor. Inténtalo nuevamente.'), findsOneWidget);
    expect(find.text('Mostrar transcript'), findsNothing);
    expect(find.text('Seguir a mi respuesta'), findsNothing);

    await tester.tap(find.text('Escuchar al interlocutor'));
    await tester.pump();
    audioController.completePlayback();
    await tester.pump();
    expect(find.text('Mostrar transcript'), findsOneWidget);
    expect(find.text('Seguir a mi respuesta'), findsOneWidget);
  });
}
