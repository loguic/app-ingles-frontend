import 'dart:async';

import 'package:app_ingles/models/lesson.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/widgets/lesson_detail_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates exercise requests without using the real backend.
/// Simula las solicitudes de ejercicios sin utilizar el backend real.
class FakeApiService extends ApiService {
  @override
  Future<bool?> submitExerciseAnswer({
    required String exerciseId,
    required int selectedIndex,
  }) async {
    return selectedIndex == 0;
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
    return true;
  }
}

/// Provides the audio contract without activating native plugins.
/// Proporciona el contrato de audio sin activar complementos nativos.
class FakePronunciationAudioController implements PronunciationAudioController {
  final StreamController<String?> _playbackController =
      StreamController<String?>.broadcast();
  final StreamController<String?> _recordingController =
      StreamController<String?>.broadcast();

  @override
  String? activePlaybackId;

  @override
  String? activeRecordingId;

  @override
  Stream<String?> get onPlaybackChanged => _playbackController.stream;

  @override
  Stream<String?> get onRecordingChanged => _recordingController.stream;

  @override
  Future<bool> hasMicrophonePermission() async => true;

  @override
  Future<void> playReference(String audioAsset, {String? playbackId}) async {}

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {}

  @override
  Future<void> stopPlayback() async {}

  @override
  Future<void> startRecording(String recordingId) async {}

  @override
  Future<String?> stopRecording() async => null;

  @override
  Future<void> cancelRecording() async {}

  @override
  Future<void> deleteRecording(String path) async {}

  @override
  Future<void> dispose() async {
    await _playbackController.close();
    await _recordingController.close();
  }
}

const testLesson = Lesson(
  id: 'lesson-test',
  title: 'Lección de prueba',
  vocabulary: [],
  grammar: [],
  examples: [],
  exercises: [
    LessonExercise(
      id: 'exercise-1',
      type: 'multiple_choice',
      prompt: 'Primer ejercicio',
      options: ['Correcta uno', 'Incorrecta uno'],
      answerIndex: 0,
      skillIds: [],
    ),
    LessonExercise(
      id: 'exercise-2',
      type: 'multiple_choice',
      prompt: 'Segundo ejercicio',
      options: ['Correcta dos', 'Incorrecta dos'],
      answerIndex: 0,
      skillIds: [],
    ),
  ],
);

void main() {
  testWidgets('completes and updates the local lesson summary', (tester) async {
    final audioController = FakePronunciationAudioController();

    addTearDown(audioController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonDetailCard(
              lesson: testLesson,
              levelId: 'A1',
              unitId: 'unit-test',
              pronunciationAudioService: audioController,
              exerciseApiService: FakeApiService(),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Ejercicios completados: 0 de 2'), findsOneWidget);
    expect(find.text('Lección completada'), findsNothing);

    // First exercise: correct answer.
    // Primer ejercicio: respuesta correcta.
    await tester.tap(find.text('Correcta uno'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprobar').at(0));
    await tester.pumpAndSettle();

    expect(find.text('Ejercicios completados: 1 de 2'), findsOneWidget);
    expect(find.text('Lección completada'), findsNothing);

    // Second exercise: initially incorrect.
    // Segundo ejercicio: inicialmente incorrecto.
    await tester.ensureVisible(find.text('Incorrecta dos'));
    await tester.tap(find.text('Incorrecta dos'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprobar').at(1));
    await tester.pumpAndSettle();

    expect(find.text('Ejercicios completados: 2 de 2'), findsOneWidget);
    expect(find.text('Lección completada'), findsOneWidget);
    expect(find.text('Respuestas correctas: 1 de 2'), findsOneWidget);
    expect(
      find.text(
        'Revisa la retroalimentación de los ejercicios y vuelve a practicar los que necesites.',
      ),
      findsOneWidget,
    );

    // Rechecking updates the same exercise instead of counting it twice.
    // Una nueva comprobación actualiza el mismo ejercicio sin contarlo dos veces.
    await tester.tap(find.text('Correcta dos'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Comprobar').at(1));
    await tester.pumpAndSettle();

    expect(find.text('Ejercicios completados: 2 de 2'), findsOneWidget);
    expect(find.text('Respuestas correctas: 2 de 2'), findsOneWidget);
    expect(
      find.text(
        'Excelente trabajo. Has respondido correctamente todos los ejercicios.',
      ),
      findsOneWidget,
    );
  });
}
