import 'dart:async';

import 'package:app_ingles/models/station_journey.dart';
import 'package:app_ingles/screens/station_journey_screen.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/services/station_journey_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryJourneyStore implements StationJourneyStore {
  StationJourney? value;

  @override
  Future<StationJourney?> load() async => value;

  @override
  Future<void> save(StationJourney journey) async => value = journey;
}

class _AudioFake implements PronunciationAudioController {
  @override
  String? activePlaybackId;
  @override
  String? activeRecordingId;
  final _playback = StreamController<String?>.broadcast();
  final _recording = StreamController<String?>.broadcast();
  final _complete = StreamController<String>.broadcast();
  Completer<void>? pendingStart;

  @override
  Stream<String?> get onPlaybackChanged => _playback.stream;
  @override
  Stream<String?> get onRecordingChanged => _recording.stream;
  @override
  Stream<String> get onPlaybackCompleted => _complete.stream;
  @override
  Stream<Duration> get onPlaybackDuration => const Stream.empty();
  @override
  Stream<Duration> get onPlaybackPosition => const Stream.empty();
  @override
  Future<bool> hasMicrophonePermission() async => true;
  @override
  Future<void> startRecording(String id) async {
    activeRecordingId = id;
    _recording.add(id);
  }

  @override
  Future<String?> stopRecording() async {
    activeRecordingId = null;
    _recording.add(null);
    return '/tmp/station.wav';
  }

  @override
  Future<void> playReference(String asset, {String? playbackId}) async {
    activePlaybackId = playbackId;
    _playback.add(playbackId);
    await pendingStart?.future;
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  void completeActivePlayback() {
    final id = activePlaybackId;
    if (id == null) throw StateError('No active playback');
    activePlaybackId = null;
    _complete.add(id);
    _playback.add(null);
  }

  void emitCompletion(String id) => _complete.add(id);

  @override
  Future<void> stopPlayback() async {
    activePlaybackId = null;
    _playback.add(null);
  }

  @override
  Future<void> cancelRecording() async {}
  @override
  Future<void> deleteRecording(String path) async {}
  @override
  Future<void> dispose() async {
    await _playback.close();
    await _recording.close();
    await _complete.close();
  }
}

void main() {
  testWidgets("station meets basic accessibility guidelines", (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final audio = _AudioFake();
      addTearDown(audio.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StationJourneyScreen(
            audioController: audio,
            journeyStore: _MemoryJourneyStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel("Escena de una estación de tren"),
        findsOneWidget,
      );

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    } finally {
      semantics.dispose();
    }
  });

  for (final width in [390.0, 700.0, 1280.0]) {
    testWidgets('station layout fits at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = _AudioFake();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: StationJourneyScreen(
            audioController: audio,
            journeyStore: _MemoryJourneyStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('station-play-reference'))).width,
        lessThanOrEqualTo(360),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('station-record')),
        200,
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('station-record')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('station-record'))).width,
        lessThanOrEqualTo(360),
      );
    });
  }

  testWidgets(
    'the station unlocks speaking only after reference playback completes',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = _AudioFake();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: StationJourneyScreen(
            audioController: audio,
            journeyStore: _MemoryJourneyStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final record = find.byKey(const Key('station-record'));
      final play = find.byKey(const Key('station-play-reference'));
      expect(find.text('Ask for the toilet in your own words.'), findsNothing);
      expect(
        find.byKey(const Key('station-comprehension-instruction')),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(record).onPressed, isNull);

      await tester.tap(play);
      await tester.pumpAndSettle();
      expect(find.text('Ask for the toilet in your own words.'), findsNothing);
      expect(tester.widget<FilledButton>(record).onPressed, isNull);
      audio.emitCompletion('unrelated-playback');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(record).onPressed, isNull);

      audio.completeActivePlayback();
      await tester.pumpAndSettle();
      expect(
        find.text('Ask for the toilet in your own words.'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(record).onPressed, isNotNull);
    },
  );

  testWidgets('interruption while starting rejects a late completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final audio = _AudioFake()..pendingStart = Completer<void>();
    addTearDown(audio.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: StationJourneyScreen(
          audioController: audio,
          journeyStore: _MemoryJourneyStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('station-play-reference')));
    await tester.pump();
    final interruptedId = audio.activePlaybackId!;
    await audio.stopPlayback();
    await tester.pump();
    audio.pendingStart!.complete();
    await tester.pump();
    audio.emitCompletion(interruptedId);
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('station-record')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
    'interruption and old playback completion never unlock recording',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = _AudioFake();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: StationJourneyScreen(
            audioController: audio,
            journeyStore: _MemoryJourneyStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final record = find.byKey(const Key('station-record'));
      final play = find.byKey(const Key('station-play-reference'));
      await tester.ensureVisible(play);
      await tester.tap(play);
      await tester.pumpAndSettle();
      final interruptedId = audio.activePlaybackId!;
      await audio.stopPlayback();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(record).onPressed, isNull);
      audio.emitCompletion(interruptedId);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(record).onPressed, isNull);

      await tester.tap(play);
      await tester.pumpAndSettle();
      audio.emitCompletion(interruptedId);
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(record).onPressed, isNull);
      audio.completeActivePlayback();
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(record).onPressed, isNotNull);
    },
  );

  testWidgets(
    'records, orients, retries, saves and opens the data-defined exit situation',
    (tester) async {
      final audio = _AudioFake();
      final store = _MemoryJourneyStore();
      addTearDown(audio.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: StationJourneyScreen(
            audioController: audio,
            journeyStore: store,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('station-provisional-audio-label')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const Key('station-play-reference')),
      );
      await tester.tap(find.byKey(const Key('station-play-reference')));
      audio.completeActivePlayback();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('station-record')),
        200,
      );
      await tester.tap(find.byKey(const Key('station-record')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('station-record')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('station-orientation')), findsOneWidget);

      await tester.tap(find.byKey(const Key('station-start-retry')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('station-record')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('station-record')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('station-saved')), findsOneWidget);
      expect(store.value?.phase, StationJourneyPhase.complete);

      await tester.tap(find.byKey(const Key('station-next-situation')));
      await tester.pumpAndSettle();
      expect(find.text('Find the exit'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('station-record')),
        200,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('station-record')))
            .onPressed,
        isNull,
      );
    },
  );
}
