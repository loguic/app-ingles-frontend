import 'dart:async';

import 'package:app_ingles/models/lesson.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/widgets/lesson_pronunciation_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test double that simulates audio without using native plugins.
/// Simulador de audio que evita utilizar complementos nativos.
class FakePronunciationAudioController implements PronunciationAudioController {
  final StreamController<String?> _playbackController =
      StreamController<String?>.broadcast();

  final StreamController<String?> _recordingController =
      StreamController<String?>.broadcast();

  bool microphonePermission = true;
  String? recordingResultPath = '/tmp/pronunciation-test.wav';

  @override
  String? activePlaybackId;

  @override
  String? activeRecordingId;

  @override
  Stream<String?> get onPlaybackChanged => _playbackController.stream;

  @override
  Stream<String?> get onRecordingChanged => _recordingController.stream;

  @override
  Future<bool> hasMicrophonePermission() async {
    return microphonePermission;
  }

  @override
  Future<void> playReference(String audioAsset, {String? playbackId}) async {
    activePlaybackId = playbackId ?? 'reference:$audioAsset';
    _playbackController.add(activePlaybackId);
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    activePlaybackId = playbackId ?? 'recording:$path';
    _playbackController.add(activePlaybackId);
  }

  @override
  Future<void> stopPlayback() async {
    activePlaybackId = null;
    _playbackController.add(null);
  }

  /// Simulates the natural completion of the active audio.
  /// Simula la finalización natural del audio activo.
  void completePlayback() {
    activePlaybackId = null;
    _playbackController.add(null);
  }

  @override
  Future<void> startRecording(String recordingId) async {
    activeRecordingId = recordingId;
    _recordingController.add(recordingId);
  }

  @override
  Future<String?> stopRecording() async {
    activeRecordingId = null;
    _recordingController.add(null);
    return recordingResultPath;
  }

  @override
  Future<void> cancelRecording() async {
    activeRecordingId = null;
    _recordingController.add(null);
  }

  @override
  Future<void> deleteRecording(String path) async {}

  @override
  Future<void> dispose() async {
    await _playbackController.close();
    await _recordingController.close();
  }
}

const testPronunciations = [
  LessonPronunciation(
    locale: 'en-US',
    ipa: '/həˈloʊ/',
    audioAsset: 'audio/test-us.wav',
  ),
  LessonPronunciation(
    locale: 'en-GB',
    ipa: '/həˈləʊ/',
    audioAsset: 'audio/test-uk.wav',
  ),
];

Widget buildTestWidget(FakePronunciationAudioController audioController) {
  return MaterialApp(
    home: Scaffold(
      body: LessonPronunciationControls(
        exampleId: 'test-example',
        pronunciations: testPronunciations,
        audioService: audioController,
      ),
    ),
  );
}

void main() {
  testWidgets('shows the initial recording controls', (tester) async {
    final audioController = FakePronunciationAudioController();

    await tester.pumpWidget(buildTestWidget(audioController));

    expect(find.text('Inglés estadounidense'), findsOneWidget);
    expect(find.text('Inglés británico'), findsOneWidget);
    expect(find.text('Grabar mi voz'), findsOneWidget);
    expect(find.text('Grabando...'), findsNothing);
    expect(find.text('Grabación disponible'), findsNothing);
  });

  testWidgets('shows the recording state after starting', (tester) async {
    final audioController = FakePronunciationAudioController();

    await tester.pumpWidget(buildTestWidget(audioController));
    await tester.tap(find.text('Grabar mi voz'));
    await tester.pumpAndSettle();

    expect(find.text('Grabando...'), findsOneWidget);
    expect(find.text('Detener grabación'), findsOneWidget);
    expect(audioController.activeRecordingId, 'test-example');
  });

  testWidgets('shows playback controls after stopping recording', (
    tester,
  ) async {
    final audioController = FakePronunciationAudioController();

    await tester.pumpWidget(buildTestWidget(audioController));
    await tester.tap(find.text('Grabar mi voz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();

    expect(find.text('Grabación disponible'), findsOneWidget);
    expect(find.text('Reproducir mi voz'), findsOneWidget);
    expect(find.text('Volver a grabar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
  });

  testWidgets('plays the learner recording', (tester) async {
    final audioController = FakePronunciationAudioController();

    await tester.pumpWidget(buildTestWidget(audioController));
    await tester.tap(find.text('Grabar mi voz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pumpAndSettle();

    expect(audioController.activePlaybackId, 'recording:test-example');
    expect(find.byIcon(Icons.volume_up), findsOneWidget);
  });

  testWidgets('shows an error when microphone permission is denied', (
    tester,
  ) async {
    final audioController = FakePronunciationAudioController()
      ..microphonePermission = false;

    await tester.pumpWidget(buildTestWidget(audioController));
    await tester.tap(find.text('Grabar mi voz'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se concedió permiso para utilizar el micrófono.'),
      findsOneWidget,
    );
    expect(find.text('Grabando...'), findsNothing);
  });

  testWidgets('allows re-recording and deleting the learner recording', (
    tester,
  ) async {
    final audioController = FakePronunciationAudioController();

    await tester.pumpWidget(buildTestWidget(audioController));

    await tester.tap(find.text('Grabar mi voz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Volver a grabar'));
    await tester.pumpAndSettle();

    expect(find.text('Grabando...'), findsOneWidget);

    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Grabar mi voz'), findsOneWidget);
    expect(find.text('Grabación disponible'), findsNothing);
    expect(find.text('Reproducir mi voz'), findsNothing);
  });

  testWidgets('completes and restarts the guided pronunciation practice', (
    tester,
  ) async {
    final audioController = FakePronunciationAudioController();

    await tester.pumpWidget(buildTestWidget(audioController));

    await tester.tap(find.byTooltip('Escuchar pronunciación').first);
    await tester.pumpAndSettle();

    audioController.completePlayback();
    await tester.pumpAndSettle();

    expect(find.text('Paso 2: graba tu repetición.'), findsOneWidget);

    await tester.tap(find.text('Grabar mi voz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detener grabación'));
    await tester.pumpAndSettle();

    expect(
      find.text('Paso 3: escucha tu voz y compárala con la referencia.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pumpAndSettle();

    audioController.completePlayback();
    await tester.pumpAndSettle();

    expect(
      find.text('Práctica completada: puedes repetir el recorrido.'),
      findsOneWidget,
    );
    expect(find.text('Repetir práctica'), findsOneWidget);

    await tester.tap(find.text('Repetir práctica'));
    await tester.pumpAndSettle();

    expect(
      find.text('Paso 1: escucha la pronunciación de referencia.'),
      findsOneWidget,
    );
    expect(find.text('Repetir práctica'), findsNothing);
    expect(find.text('Grabación disponible'), findsNothing);
  });
}
