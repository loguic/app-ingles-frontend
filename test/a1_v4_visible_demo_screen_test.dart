import 'dart:async';

import 'package:app_ingles/screens/a1_v4_visible_demo_screen.dart';
import 'package:app_ingles/screens/visual_demo_screens.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/theme/loguic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _completed = StreamController<String>.broadcast();
  final _recording = StreamController<String?>.broadcast();
  final List<String> references = [];
  final List<String> recordingIds = [];
  final List<String?> recordingPlaybackIds = [];

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
  Future<void> playReference(String asset, {String? playbackId}) async {
    references.add(asset);
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    recordingPlaybackIds.add(playbackId);
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  void completePlayback() {
    final id = activePlaybackId;
    activePlaybackId = null;
    _playback.add(null);
    if (id != null) _completed.add(id);
  }

  @override
  Future<void> stopPlayback() async {
    activePlaybackId = null;
    _playback.add(null);
  }

  @override
  Future<void> startRecording(String recordingId) async {
    recordingIds.add(recordingId);
    activeRecordingId = recordingId;
    _recording.add(recordingId);
  }

  @override
  Future<String?> stopRecording() async {
    activeRecordingId = null;
    _recording.add(null);
    return '/tmp/a1-v4-water.wav';
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

void main() {
  test('declares the approved backend identities and asset paths', () {
    expect(
      A1V4VisibleDemoScreen.visualAsset,
      'assets/a1_v4/visual/scene-water.png',
    );
    expect(
      A1V4VisibleDemoScreen.audioAsset,
      'a1_v4/audio/i-need-water.en-gb.wav',
    );
    expect(
      A1V4VisibleDemoScreen.visualResourceId,
      'visual.a1-u1-l1.scene.water.v1',
    );
    expect(
      A1V4VisibleDemoScreen.audioResourceId,
      'audio.a1-u1-l1.i-need-water.en-gb.v1',
    );
  });

  testWidgets('shows approved water assets and reuses listen-record-playback', (
    tester,
  ) async {
    final audio = _AudioController();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: LoguicTheme.light,
        home: A1V4VisibleDemoScreen(audioController: audio),
      ),
    );

    expect(find.byKey(const Key('a1-v4-water-scene')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('a1-v4-water-scene-frame'))).height,
      280,
    );
    expect(find.text('I need water.'), findsNothing);
    expect(find.textContaining('No activa el currículo'), findsOneWidget);
    expect(
      find.text('Listen and repeat for self-perception'),
      findsOneWidget,
    );
    expect(
      find.textContaining('it is not your own oral production.'),
      findsOneWidget,
    );
    expect(find.text('Choose the matching picture'), findsNothing);

    await tester.ensureVisible(find.byTooltip('Escuchar pronunciación'));
    await tester.tap(find.byTooltip('Escuchar pronunciación'));
    await tester.pump();
    expect(audio.references, [A1V4VisibleDemoScreen.audioAsset]);

    audio.completePlayback();
    await tester.pump();
    expect(find.text('Choose the matching picture'), findsOneWidget);
    expect(find.text('I need water.'), findsNothing);
    expect(
      find.text('Elige la imagen que representa lo que escuchaste.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('a1-v4-comprehension-need')), findsOneWidget);
    expect(
      find.byKey(const Key('a1-v4-comprehension-greeting')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('a1-v4-comprehension-farewell')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-comprehension-greeting')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-comprehension-greeting')));
    await tester.pump();
    expect(find.text('Try again.'), findsOneWidget);
    expect(find.text('I need water.'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-comprehension-need')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-comprehension-need')));
    await tester.pump();
    expect(find.text('Correct!'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-start-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-start-own-production')));
    await tester.pump();
    expect(find.text('I need water.'), findsNothing);
    expect(find.text('Your own oral production'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('need'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);

    await tester.ensureVisible(find.text('Grabar mi voz'));
    await tester.tap(find.text('Grabar mi voz'));
    await tester.pump();
    await tester.ensureVisible(find.text('Detener grabación'));
    await tester.tap(find.text('Detener grabación'));
    await tester.pump();
    await tester.ensureVisible(find.text('Reproducir mi voz'));
    await tester.tap(find.text('Reproducir mi voz'));
    await tester.pump();
    audio.completePlayback();
    await tester.pump();

    expect(
      find.text('Paso 4: describe cómo te escuchaste, según tu percepción.'),
      findsOneWidget,
    );
    expect(find.text('Choose the matching picture'), findsOneWidget);
    expect(find.byKey(const Key('a1-v4-comprehension-need')), findsOneWidget);
    expect(
      find.byKey(const Key('a1-v4-comprehension-greeting')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('a1-v4-comprehension-farewell')),
      findsOneWidget,
    );
    expect(find.text('¿Cómo te escuchaste?'), findsNothing);
    expect(find.textContaining('puntuación'), findsNothing);

    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-record-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
    await tester.pump();
    await tester.ensureVisible(find.text('Play my own production'));
    await tester.tap(find.text('Play my own production'));
    await tester.pump();

    expect(
      audio.recordingIds,
      [
        'demo-visual-a1-v4-i-need-water',
        'demo-visual-a1-v4-own-production',
      ],
    );
    expect(
      audio.recordingPlaybackIds,
      [
        'recording:demo-visual-a1-v4-i-need-water',
        'recording:demo-visual-a1-v4-own-production',
      ],
    );
    expect(find.textContaining('transfer'), findsNothing);
    expect(find.textContaining('review'), findsNothing);
    expect(find.textContaining('retention'), findsNothing);
    expect(find.textContaining('progress'), findsNothing);
    expect(find.textContaining('mastery'), findsNothing);
    expect(find.textContaining('completion'), findsNothing);
  });

  testWidgets(
    'shows comprehension again after returning and reentering A1 v4',
    (tester) async {
      final audio = _AudioController();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: LoguicTheme.light,
          home: VisualDemoLessonScreen(audioController: audio),
        ),
      );

      Future<void> openA1V4AndFinishReference() async {
        await tester.ensureVisible(find.text('Abrir escena A1 v4'));
        await tester.tap(find.text('Abrir escena A1 v4'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('Escuchar pronunciación'));
        await tester.tap(find.byTooltip('Escuchar pronunciación'));
        await tester.pump();
        audio.completePlayback();
        await tester.pump();
      }

      await openA1V4AndFinishReference();
      expect(find.text('Choose the matching picture'), findsOneWidget);
      expect(find.text('I need water.'), findsNothing);
      expect(find.byKey(const Key('a1-v4-comprehension-need')), findsOneWidget);
      expect(
        find.byKey(const Key('a1-v4-comprehension-greeting')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('a1-v4-comprehension-farewell')),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Volver a la demostración'));
      await tester.tap(find.text('Volver a la demostración'));
      await tester.pumpAndSettle();

      await openA1V4AndFinishReference();
      expect(find.text('Choose the matching picture'), findsOneWidget);
      expect(find.byKey(const Key('a1-v4-comprehension-need')), findsOneWidget);
      expect(
        find.byKey(const Key('a1-v4-comprehension-greeting')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('a1-v4-comprehension-farewell')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-comprehension-greeting')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-comprehension-greeting')));
      await tester.pump();
      expect(find.text('Try again.'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-comprehension-need')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-comprehension-need')));
      await tester.pump();
      expect(find.text('Correct!'), findsOneWidget);
    },
  );
}
