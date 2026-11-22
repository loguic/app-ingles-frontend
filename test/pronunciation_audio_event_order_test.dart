import 'dart:async';

import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';

/// Real onPlayerComplete streams, one per injected player instance.
/// Eventos reales del contrato de AudioPlayer, aislados por instancia.
class _Player implements AudioPlayer {
  final completions = StreamController<void>.broadcast();
  final sources = <Source>[];
  Completer<void>? pendingStart;
  Completer<void>? pendingDisposal;
  bool playing = false;
  bool disposed = false;
  bool failStop = false;
  bool failDispose = false;
  int stops = 0;
  int disposals = 0;

  @override
  Stream<void> get onPlayerComplete => completions.stream;
  @override
  Stream<Duration> get onPositionChanged => const Stream.empty();
  @override
  Stream<Duration> get onDurationChanged => const Stream.empty();
  @override
  Future<void> stop() async {
    stops++;
    if (failStop) throw StateError('fake stop failed');
    playing = false;
  }

  @override
  Future<void> dispose() async {
    disposals++;
    await pendingDisposal?.future;
    if (failDispose) throw StateError('fake disposal failed');
    disposed = true;
    playing = false;
  }

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    sources.add(source);
    await pendingStart?.future;
    // Deliberately simulate a late start even after the first stop().
    // Simula un arranque tardío pese al primer stop().
    playing = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Recorder implements AudioRecorder {
  int disposals = 0;
  @override
  Future<bool> isRecording() async => false;
  @override
  Future<void> dispose() async {
    disposals++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _drainEvents() => Future<void>.delayed(Duration.zero);

List<Source> playersStartedSources(Iterable<_Player> players) =>
    players.expand((player) => player.sources).toList();

Future<void> _finish(
  PronunciationAudioService service,
  Iterable<_Player> players,
) async {
  await service.dispose();
  for (final player in players) {
    await player.completions.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a valid completion emits the owning session ID exactly once', () async {
    final player = _Player();
    final service = PronunciationAudioService(
      audioPlayerFactory: () => player,
      audioRecorder: _Recorder(),
    );
    final completed = <String>[];
    final subscription = service.onPlaybackCompleted.listen(completed.add);

    await service.playReference('first.wav', playbackId: 'first');
    expect(service.activePlaybackId, 'first');
    expect(player.sources.single, isA<AssetSource>());
    player.completions.add(null);
    await _drainEvents();
    player.completions.add(null);
    await _drainEvents();

    expect(completed, ['first']);
    expect(service.activePlaybackId, isNull);
    await subscription.cancel();
    await _finish(service, [player]);
    expect(player.disposals, 1);
  });

  test(
    'old player completion cannot complete the replacement session',
    () async {
      final first = _Player();
      final second = _Player();
      final players = [first, second];
      final service = PronunciationAudioService(
        audioPlayerFactory: () => players.removeAt(0),
        audioRecorder: _Recorder(),
      );
      final completed = <String>[];
      final subscription = service.onPlaybackCompleted.listen(completed.add);

      await service.playReference('a.wav', playbackId: 'A');
      await service.playReference('b.wav', playbackId: 'B');
      first.completions.add(null); // Comes from A's actual player.
      await _drainEvents();
      expect(completed, isEmpty);
      expect(service.activePlaybackId, 'B');

      second.completions.add(null);
      await _drainEvents();
      expect(completed, ['B']);
      await subscription.cancel();
      await _finish(service, [first, second]);
      expect(first.disposals, 1);
      expect(second.disposals, 1);
    },
  );

  test(
    'stopping while play is pending immediately invalidates the session',
    () async {
      final player = _Player()..pendingStart = Completer<void>();
      final service = PronunciationAudioService(
        audioPlayerFactory: () => player,
        audioRecorder: _Recorder(),
      );
      final completed = <String>[];
      final subscription = service.onPlaybackCompleted.listen(completed.add);

      final starting = service.playReference('slow.wav', playbackId: 'slow');
      expect(service.activePlaybackId, 'slow');
      await service.stopPlayback(); // Must not block on pending play().
      expect(service.activePlaybackId, isNull);
      player.completions.add(null);
      await _drainEvents();
      expect(completed, isEmpty);

      player.pendingStart!.complete();
      await starting;
      await subscription.cancel();
      await _finish(service, [player]);
      expect(player.stops, greaterThanOrEqualTo(2));
      expect(player.disposals, 1);
    },
  );

  test('concurrent starts cannot reactivate an invalidated session', () async {
    final first = _Player()..pendingStart = Completer<void>();
    final second = _Player();
    final players = [first, second];
    final service = PronunciationAudioService(
      audioPlayerFactory: () => players.removeAt(0),
      audioRecorder: _Recorder(),
    );
    final completed = <String>[];
    final subscription = service.onPlaybackCompleted.listen(completed.add);

    final slowStart = service.playReference('slow.wav', playbackId: 'slow');
    final fastStart = service.playReference('fast.wav', playbackId: 'fast');
    await _drainEvents();
    expect(second.sources, isEmpty); // B cannot start behind an unsettled A.
    first.completions.add(null);
    first.pendingStart!.complete();
    await slowStart;
    await fastStart;
    await _drainEvents();
    expect(first.playing, isFalse);
    expect(second.playing, isTrue);
    expect(completed, isEmpty);
    expect(service.activePlaybackId, 'fast');

    second.completions.add(null);
    await _drainEvents();
    expect(completed, ['fast']);
    await subscription.cancel();
    await _finish(service, [first, second]);
    expect(first.disposals, 1);
    expect(second.disposals, 1);
  });

  test('three queued starts leave only the newest request physically active', () async {
    final first = _Player()
      ..pendingStart = Completer<void>()
      ..pendingDisposal = Completer<void>();
    final second = _Player();
    final third = _Player();
    final players = [first, second, third];
    final service = PronunciationAudioService(
      audioPlayerFactory: () => players.removeAt(0),
      audioRecorder: _Recorder(),
    );
    final completed = <String>[];
    final subscription = service.onPlaybackCompleted.listen(completed.add);

    final startA = service.playReference('a.wav', playbackId: 'A');
    final startB = service.playReference('b.wav', playbackId: 'B');
    final startC = service.playReference('c.wav', playbackId: 'C');
    await _drainEvents();
    expect(second.sources, isEmpty);
    expect(third.sources, isEmpty);

    first.pendingStart!.complete();
    await _drainEvents();
    expect(first.playing, isFalse);
    first.pendingDisposal!.complete();
    await Future.wait([startA, startB, startC]);
    await _drainEvents();

    final startedSources = playersStartedSources([first, second, third]);
    expect(startedSources.where((source) => (source as AssetSource).path == 'b.wav'), isEmpty);
    expect(startedSources.where((source) => (source as AssetSource).path == 'c.wav'), hasLength(1));
    expect([first, second, third].where((player) => player.playing), hasLength(1));
    expect(([first, second, third].singleWhere((player) => player.playing).sources.single as AssetSource).path, 'c.wav');
    expect(service.activePlaybackId, 'C');
    expect(service.debugTrackedPlaybackSessionCount, 1);
    expect(service.debugPendingPlaybackFenceCount, 0);

    first.completions.add(null);
    await _drainEvents();
    expect(completed, isEmpty);
    final cPlayer = [first, second, third].singleWhere(
      (player) => player.sources.any((source) => (source as AssetSource).path == 'c.wav'),
    );
    cPlayer.completions.add(null);
    await _drainEvents();
    expect(completed, ['C']);

    await subscription.cancel();
    await _finish(service, [first, second, third]);
    expect(first.disposals, 1);
    expect([first, second, third].fold<int>(0, (n, p) => n + p.disposals), 2);
    expect(service.debugTrackedPlaybackSessionCount, 0);
    expect(service.debugPendingPlaybackFenceCount, 0);
  });

  test(
    'stop and dispose release players once and reject later starts',
    () async {
      final player = _Player();
      final recorder = _Recorder();
      final service = PronunciationAudioService(
        audioPlayerFactory: () => player,
        audioRecorder: recorder,
      );

      await service.playRecording('/tmp/learner.wav', playbackId: 'voice');
      expect(player.sources.single, isA<DeviceFileSource>());
      await service.stopPlayback();
      expect(service.activePlaybackId, isNull);
      await _finish(service, [player]);
      expect(player.disposals, 1);
      expect(recorder.disposals, 1);
      await expectLater(
        service.playReference('later.wav'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('dispose completes while a previous play never settles', () async {
    final player = _Player()..pendingStart = Completer<void>();
    final service = PronunciationAudioService(
      audioPlayerFactory: () => player,
      audioRecorder: _Recorder(),
    );

    final unresolved = service.playReference('hung.wav', playbackId: 'hung');
    await service.dispose().timeout(const Duration(seconds: 1));
    expect(player.disposals, 1);
    expect(service.activePlaybackId, isNull);
    expect(service.debugTrackedPlaybackSessionCount, 0);
    expect(service.debugPendingPlaybackFenceCount, 0);
    // Intentionally NEVER resolve play(): disposal must not depend on it.
    // Deliberadamente NO resolver play(): sin retención en el servicio.
    unawaited(unresolved);
    await player.completions.close();
  });

  test(
    'B cannot overlap a late physical start or an unfinished release',
    () async {
      final first = _Player()
        ..pendingStart = Completer<void>()
        ..pendingDisposal = Completer<void>();
      final second = _Player();
      final players = [first, second];
      final service = PronunciationAudioService(
        audioPlayerFactory: () => players.removeAt(0),
        audioRecorder: _Recorder(),
      );

      final startA = service.playReference('a.wav', playbackId: 'A');
      final startB = service.playReference('b.wav', playbackId: 'B');
      await _drainEvents();
      expect(second.sources, isEmpty);
      expect(service.activePlaybackId, isNull);

      first.pendingStart!.complete(); // The fake starts A after first stop.
      await _drainEvents();
      expect(first.playing, isFalse); // Late stop has already run.
      expect(second.sources, isEmpty); // A's disposal remains pending.
      first.pendingDisposal!.complete();
      await startA;
      await startB;
      expect(first.playing, isFalse);
      expect(first.disposed, isTrue);
      expect(second.playing, isTrue);
      await _finish(service, [first, second]);
    },
  );

  test(
    'an unresolved old play rejects B instead of starting overlapping audio',
    () async {
      final first = _Player()..pendingStart = Completer<void>();
      final second = _Player();
      final players = [first, second];
      final service = PronunciationAudioService(
        audioPlayerFactory: () => players.removeAt(0),
        audioRecorder: _Recorder(),
      );

      final startA = service.playReference('a.wav', playbackId: 'A');
      final startB = service.playReference('b.wav', playbackId: 'B');
      await expectLater(startB, throwsA(isA<StateError>()));
      expect(second.sources, isEmpty);
      expect(service.activePlaybackId, isNull);
      await service.dispose().timeout(const Duration(seconds: 1));
      first.pendingStart!.complete();
      await startA;
      await first.completions.close();
    },
  );

  test(
    'any failed stop or disposal permanently blocks later playback',
    () async {
      for (final failures in <(bool, bool)>[
        (true, false),
        (false, true),
        (true, true),
      ]) {
        final first = _Player()
          ..failStop = failures.$1
          ..failDispose = failures.$2;
        final second = _Player();
        final players = [first, second];
        final service = PronunciationAudioService(
          audioPlayerFactory: () => players.removeAt(0),
          audioRecorder: _Recorder(),
        );

        await service.playReference('a.wav', playbackId: 'A');
        await expectLater(
          service.playReference('b.wav', playbackId: 'B'),
          throwsA(isA<StateError>()),
        );
        expect(service.activePlaybackId, isNull);
        expect(second.sources, isEmpty);
        expect(service.debugTrackedPlaybackSessionCount, 0);
        await expectLater(
          service.playReference('c.wav', playbackId: 'C'),
          throwsA(isA<StateError>()),
        );
        expect(second.sources, isEmpty); // Sticky fail-closed latch.
        await _finish(service, [first, second]);
      }
    },
  );

  test('stop releases tracking without resolving an old play', () async {
    final first = _Player()..pendingStart = Completer<void>();
    final service = PronunciationAudioService(
      audioPlayerFactory: () => first,
      audioRecorder: _Recorder(),
    );

    final unresolved = service.playReference('never.wav', playbackId: 'never');
    await service.stopPlayback();
    await _drainEvents();
    expect(service.debugTrackedPlaybackSessionCount, 0);
    expect(service.debugPendingPlaybackFenceCount, 1);
    await service.dispose().timeout(const Duration(seconds: 1));
    expect(service.debugPendingPlaybackFenceCount, 0);
    unawaited(unresolved);
    await first.completions.close();
  });

  test(
    'stop cancels a replacement still waiting behind an old start',
    () async {
      final first = _Player()..pendingStart = Completer<void>();
      final second = _Player();
      final players = [first, second];
      final service = PronunciationAudioService(
        audioPlayerFactory: () => players.removeAt(0),
        audioRecorder: _Recorder(),
      );

      final startA = service.playReference('a.wav', playbackId: 'A');
      final startB = service.playReference('b.wav', playbackId: 'B');
      await service.stopPlayback();
      first.pendingStart!.complete();
      await startA;
      await startB;
      expect(second.sources, isEmpty);
      expect(service.activePlaybackId, isNull);
      await _finish(service, [first]);
    },
  );
}
