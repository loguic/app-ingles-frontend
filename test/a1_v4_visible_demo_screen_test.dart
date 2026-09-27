import 'dart:async';

import 'package:app_ingles/screens/a1_v4_visible_demo_screen.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/theme/loguic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _completed = StreamController<String>.broadcast();
  final _recording = StreamController<String?>.broadcast();
  final List<String> references = [];

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
    expect(find.text('I need water.'), findsOneWidget);
    expect(find.textContaining('No activa el currículo'), findsOneWidget);

    await tester.tap(find.byTooltip('Escuchar pronunciación'));
    await tester.pump();
    expect(audio.references, [A1V4VisibleDemoScreen.audioAsset]);

    audio.completePlayback();
    await tester.pump();
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

    expect(find.text('¿Cómo te escuchaste?'), findsNothing);
    expect(find.textContaining('puntuación'), findsNothing);
  });
}
