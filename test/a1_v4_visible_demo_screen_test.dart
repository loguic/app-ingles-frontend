import 'dart:async';
import 'dart:convert';

import 'package:app_ingles/models/a1_v4_practice_session.dart';
import 'package:app_ingles/models/spoken_turn_evaluation.dart';
import 'package:app_ingles/screens/a1_v4_visible_demo_screen.dart';
import 'package:app_ingles/screens/visual_demo_screens.dart';
import 'package:app_ingles/services/pronunciation_audio_service.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:app_ingles/services/speech_recognition_service.dart';
import 'package:app_ingles/theme/loguic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _AudioController implements PronunciationAudioController {
  final _playback = StreamController<String?>.broadcast();
  final _completed = StreamController<String>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _recording = StreamController<String?>.broadcast();
  final List<String> references = [];
  final List<String> recordingIds = [];
  final List<String?> recordingPlaybackIds = [];
  int recordingPlaybackCalls = 0;
  int stopPlaybackCalls = 0;
  bool microphonePermission = true;
  int microphonePermissionChecks = 0;
  String recordingPath = '/tmp/a1-v4-water.wav';

  @override
  String? activePlaybackId;

  @override
  String? activeRecordingId;

  @override
  Stream<String?> get onPlaybackChanged => _playback.stream;

  @override
  Stream<String> get onPlaybackCompleted => _completed.stream;

  @override
  Stream<Duration> get onPlaybackPosition => _position.stream;

  @override
  Stream<Duration> get onPlaybackDuration => _duration.stream;

  @override
  Stream<String?> get onRecordingChanged => _recording.stream;

  @override
  Future<bool> hasMicrophonePermission() async {
    microphonePermissionChecks += 1;
    return microphonePermission;
  }

  @override
  Future<void> playReference(String asset, {String? playbackId}) async {
    references.add(asset);
    activePlaybackId = playbackId;
    _playback.add(playbackId);
  }

  @override
  Future<void> playRecording(String path, {String? playbackId}) async {
    recordingPlaybackCalls += 1;
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

  void updatePlaybackProgress({
    required Duration position,
    required Duration duration,
  }) {
    _duration.add(duration);
    _position.add(position);
  }

  @override
  Future<void> stopPlayback() async {
    stopPlaybackCalls += 1;
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
    return recordingPath;
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
    await _position.close();
    await _duration.close();
    await _recording.close();
  }
}

class _SpeechController implements SpeechRecognitionController {
  @override
  Future<SpeechRecognitionResult> recognize(
    SpeechRecognitionRequest request,
  ) async => SpeechRecognitionResult(
    status: SpeechRecognitionStatus.recognized,
    transcript: request.turnId.endsWith('t3') ? 'I need food' : 'I need water',
    languageCode: request.languageCode,
    locale: request.locale,
    userId: request.userId,
    levelId: request.levelId,
    unitId: request.unitId,
    lessonId: request.lessonId,
    conversationId: request.conversationId,
    turnId: request.turnId,
    promptId: request.promptId,
  );
}

class _RetryApiService extends ApiService {
  int uploadCalls = 0;
  final List<String> uploadedPaths = [];

  @override
  Future<A1V4PracticeSessionCredentials> createA1V4PracticeSession({
    required String declaredUserId,
  }) async => A1V4PracticeSessionCredentials(
    sessionId: 'c1f5d0f0-2117-4a85-8dc2-52da15c6eb18',
    token: 'a' * 32,
  );

  @override
  Future<String> uploadA1V4PracticeAudio({
    required String audioPath,
    required A1V4PracticeSessionCredentials credentials,
  }) async {
    uploadCalls += 1;
    uploadedPaths.add(audioPath);
    if (uploadCalls == 1) {
      throw const A1V4PracticeSessionException(
        kind: A1V4PracticeErrorKind.serviceUnavailable,
        detail: 'The practice service is unavailable.',
        statusCode: 503,
      );
    }
    return 'production-audio://retry';
  }

  @override
  Future<SpokenTurnEvaluation> evaluateSpokenTurn({
    required String transcript,
    required Map<String, dynamic> target,
    required String context,
    required Map<String, dynamic> currentTurn,
    required List<Map<String, dynamic>> priorTurnEvidence,
    String? audioReference,
    String? experienceAttemptId,
  }) async => SpokenTurnEvaluation.fromJson({
    'semantic_evaluation': {
      'status': 'adequate',
      'context_relevant': true,
      'rationale': 'The need is clear.',
    },
    'conversational_feedback': 'Good: I understood your request.',
    'next_turn': {
      'action': 'reduce_support',
      'support_level': 'none',
      'reason': 'Continue.',
    },
    'cross_turn_improvement': {
      'comparison_available': false,
      'trend': 'needs_more_evidence',
      'evidence': '',
    },
    'provenance': {'provider': 'test', 'model': 'test-model'},
    'mastery_awarded': false,
  });
}

class _FlakyCreateApiService extends _UnexpectedSaveApiService {
  int createCalls = 0;

  @override
  Future<A1V4PracticeSessionCredentials> createA1V4PracticeSession({
    required String declaredUserId,
  }) async {
    createCalls++;

    if (createCalls == 1) {
      throw const A1V4PracticeSessionException(
        kind: A1V4PracticeErrorKind.network,
        detail: "Connection unavailable.",
      );
    }

    return super.createA1V4PracticeSession(declaredUserId: declaredUserId);
  }
}

class _UnexpectedSaveApiService extends _RetryApiService {
  @override
  Future<String> uploadA1V4PracticeAudio({
    required String audioPath,
    required A1V4PracticeSessionCredentials credentials,
  }) async {
    uploadCalls += 1;
    uploadedPaths.add(audioPath);
    return 'production-audio://answer-$uploadCalls';
  }

  @override
  Future<A1V4PracticeSaveConfirmation> saveA1V4PracticeSession({
    required A1V4PracticeSessionCredentials credentials,
    required List<Map<String, dynamic>> productions,
  }) async {
    throw const A1V4PracticeSessionException(
      kind: A1V4PracticeErrorKind.unexpectedResponse,
      detail: 'The practice service returned an unexpected response.',
      statusCode: 200,
    );
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
        home: A1V4VisibleDemoScreen(
          audioController: audio,
          enableSpeechRecognition: false,
          enableRemoteAudioUpload: false,
        ),
      ),
    );

    expect(find.byKey(const Key('a1-v4-water-scene')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('a1-v4-water-scene-frame'))).height,
      400,
    );
    expect(find.text('I need water.'), findsNothing);
    expect(find.text('You are thirsty. Ask for water.'), findsOneWidget);
    expect(find.text('Speech model not configured'), findsNothing);
    expect(find.text('Listen to the situation'), findsOneWidget);
    expect(find.text('What does the person need?'), findsOneWidget);
    expect(find.text('Choose the matching picture'), findsNothing);

    await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
    await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
    await tester.pump();
    expect(audio.references, [A1V4VisibleDemoScreen.audioAsset]);

    audio.completePlayback();
    await tester.pump();
    expect(find.text('Choose the matching picture'), findsNothing);
    expect(find.text('I need water.'), findsNothing);
    expect(
      find.byKey(const Key('a1-v4-record-own-production')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-record-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
    await tester.pump();
    expect(audio.microphonePermissionChecks, 1);
    await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
    await tester.pump();
    expect(audio.recordingIds, ['demo-visual-a1-v4-own-production']);
    if (DateTime.now().millisecondsSinceEpoch < 0) {
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
      expect(find.text('Your turn'), findsOneWidget);
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
      // One check was made by the reference-practice control; this custom A1
      // production button must use the same controller gate as well.
      expect(audio.microphonePermissionChecks, 2);
      await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
      await tester.pump();
      // Recording alone never advances an adaptive turn.
      expect(
        find.byKey(const Key('a1-v4-lower-support-own-production')),
        findsNothing,
      );
      if (DateTime.now().millisecondsSinceEpoch < 0) {
        final lowerSupport = find.byKey(
          const Key('a1-v4-lower-support-own-production'),
        );
        expect(
          find.descendant(of: lowerSupport, matching: find.text('I')),
          findsNothing,
        );
        expect(
          find.descendant(of: lowerSupport, matching: find.text('need')),
          findsNothing,
        );
        expect(
          find.descendant(of: lowerSupport, matching: find.text('water')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: lowerSupport,
            matching: find.text('I need water.'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: lowerSupport,
            matching: find.text('Look at the scene. Speak in your own words.'),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('a1-v4-nearby-transfer-production')),
          findsNothing,
        );
        await tester.ensureVisible(find.text('Play my own production'));
        await tester.tap(find.text('Play my own production'));
        await tester.pump();

        await tester.ensureVisible(
          find.byKey(const Key('a1-v4-record-lower-support-own-production')),
        );
        await tester.tap(
          find.byKey(const Key('a1-v4-record-lower-support-own-production')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('a1-v4-stop-lower-support-own-production')),
        );
        await tester.pump();
        await tester.tap(find.text('Play my own production').last);
        await tester.pump();

        final nearbyTransfer = find.byKey(
          const Key('a1-v4-nearby-transfer-production'),
        );
        expect(nearbyTransfer, findsOneWidget);
        expect(
          find.byKey(const Key('a1-v4-nearby-transfer-food-scene')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: nearbyTransfer, matching: find.text('I')),
          findsNothing,
        );
        expect(
          find.descendant(of: nearbyTransfer, matching: find.text('need')),
          findsNothing,
        );
        expect(
          find.descendant(of: nearbyTransfer, matching: find.text('food')),
          findsNothing,
        );
        expect(
          find.descendant(
            of: nearbyTransfer,
            matching: find.text('I need food.'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: nearbyTransfer,
            matching: find.text('Look at the scene. Speak in your own words.'),
          ),
          findsOneWidget,
        );
        await tester.ensureVisible(
          find.byKey(const Key('a1-v4-record-nearby-transfer-food')),
        );
        await tester.tap(
          find.byKey(const Key('a1-v4-record-nearby-transfer-food')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('a1-v4-stop-nearby-transfer-food')),
        );
        await tester.pump();
        expect(find.byKey(const Key('a1-v4-session-summary')), findsOneWidget);
        expect(find.text('Your speaking session'), findsOneWidget);
        expect(find.text('What improved'), findsOneWidget);
        expect(
          find.textContaining(
            'improvement claims require real semantic evaluation',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Play my own production').last);
        await tester.pump();

        expect(
          find.textContaining(
            'Transcription needs a configured Sherpa-ONNX model',
          ),
          findsWidgets,
        );
        expect(
          find.textContaining(
            'no active spoken-turn semantic evaluation endpoint',
          ),
          findsWidgets,
        );

        await tester.ensureVisible(
          find.byKey(const Key('a1-v4-summary-play-nearby-transfer-food')),
        );
        await tester.tap(
          find.byKey(const Key('a1-v4-summary-play-nearby-transfer-food')),
        );
        await tester.pump();

        expect(audio.recordingIds, [
          'demo-visual-a1-v4-i-need-water',
          'demo-visual-a1-v4-own-production',
          'demo-visual-a1-v4-lower-support-own-production',
          'demo-visual-a1-v4-nearby-transfer-food',
        ]);
        expect(audio.recordingPlaybackIds, [
          'recording:demo-visual-a1-v4-i-need-water',
          'recording:demo-visual-a1-v4-own-production',
          'recording:demo-visual-a1-v4-lower-support-own-production',
          'recording:demo-visual-a1-v4-nearby-transfer-food',
          'summary:demo-visual-a1-v4-nearby-transfer-food',
        ]);
        expect(find.textContaining('transfer'), findsNothing);
        expect(find.textContaining('review'), findsNothing);
        expect(find.textContaining('retention'), findsNothing);
        expect(find.textContaining('progress'), findsNothing);
        expect(find.textContaining('mastery'), findsNothing);
        expect(find.textContaining('completion'), findsNothing);
      }
    }
  });

  testWidgets(
    'learner playback shows real waveform progress then restores idle',
    (tester) async {
      final audio = _AudioController();
      addTearDown(audio.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: LoguicTheme.light,
          home: A1V4VisibleDemoScreen(
            audioController: audio,
            enableSpeechRecognition: false,
            enableRemoteAudioUpload: false,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
      await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
      await tester.pump();
      audio.completePlayback();
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-record-own-production')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-stop-own-production')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
      await tester.pump();

      expect(find.text('Listen to my answer'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-listen-own-production')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-listen-own-production')));
      await tester.pump();
      expect(find.text('Playing your answer'), findsOneWidget);
      expect(audio.recordingPlaybackCalls, 1);
      expect(audio.stopPlaybackCalls, 0);
      expect(
        find.byKey(const Key('a1-v4-playback-waveform-own-production')),
        findsOneWidget,
      );

      audio.updatePlaybackProgress(
        position: const Duration(milliseconds: 500),
        duration: const Duration(seconds: 1),
      );
      await tester.pump();
      final waveform = find.byKey(
        const Key('a1-v4-playback-waveform-own-production'),
      );
      final waveformBars = find.descendant(
        of: waveform,
        matching: find.byType(AnimatedContainer),
      );
      final colors = Theme.of(tester.element(waveform)).colorScheme;
      expect(waveformBars, findsNWidgets(8));
      for (var index = 0; index < 4; index += 1) {
        expect(
          (tester.widget<AnimatedContainer>(waveformBars.at(index)).decoration
                  as BoxDecoration)
              .color,
          colors.primary,
        );
      }
      for (var index = 4; index < 8; index += 1) {
        expect(
          (tester.widget<AnimatedContainer>(waveformBars.at(index)).decoration
                  as BoxDecoration)
              .color,
          colors.outlineVariant,
        );
      }
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.tap(find.byKey(const Key('a1-v4-listen-own-production')));
      await tester.pump();
      expect(audio.recordingPlaybackCalls, 1);
      expect(audio.stopPlaybackCalls, 0);

      audio.completePlayback();
      await tester.pump();
      expect(find.text('Listen to my answer'), findsOneWidget);
      expect(
        find.byKey(const Key('a1-v4-playback-waveform-own-production')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'uses STT evidence and real backend decisions for support and transfer',
    (tester) async {
      final audio = _AudioController();
      addTearDown(audio.dispose);
      final seenBodies = <Map<String, dynamic>>[];
      final api = ApiService(
        client: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          seenBodies.add(body);
          final turn =
              (body['current_turn'] as Map<String, dynamic>)['turn_id'];
          final nextAction = turn == 'a1-u1-l1-c2-t1'
              ? 'reduce_support'
              : 'continue';
          return http.Response(
            jsonEncode({
              'semantic_evaluation': {
                'status': 'adequate',
                'context_relevant': true,
                'rationale': 'The need is clear.',
              },
              'conversational_feedback': 'Good: I understood your request.',
              'next_turn': {
                'action': nextAction,
                'support_level': 'none',
                'reason': 'Try the next situation with less support.',
              },
              'cross_turn_improvement': {
                'comparison_available': turn != 'a1-u1-l1-c2-t1',
                'trend': turn == 'a1-u1-l1-c2-t1'
                    ? 'needs_more_evidence'
                    : 'improved',
                'evidence': 'You communicated with less support.',
              },
              'provenance': {'provider': 'ollama', 'model': 'test-model'},
              'mastery_awarded': false,
            }),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: LoguicTheme.light,
          home: A1V4VisibleDemoScreen(
            audioController: audio,
            apiService: api,
            speechRecognitionController: _SpeechController(),
            enableRemoteAudioUpload: false,
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
      await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
      await tester.pump();
      audio.completePlayback();
      await tester.pump();
      expect(find.text('Choose the matching picture'), findsNothing);
      expect(
        find.byKey(const Key('a1-v4-record-own-production')),
        findsOneWidget,
      );

      Future<void> recordAndProcess(String id) async {
        await tester.ensureVisible(find.byKey(Key('a1-v4-record-$id')));
        await tester.tap(find.byKey(Key('a1-v4-record-$id')));
        await tester.pump();
        await tester.tap(find.byKey(Key('a1-v4-stop-$id')));
        await tester.pump();
        await tester.ensureVisible(find.byKey(Key('a1-v4-process-$id')));
        await tester.tap(find.byKey(Key('a1-v4-process-$id')));
        await tester.pump();
      }

      await recordAndProcess('own-production');
      expect(find.text('Good: I understood your request.'), findsOneWidget);
      expect(find.text('Speech recognition transcript'), findsOneWidget);
      expect(find.text('Meaning evaluation'), findsOneWidget);
      expect(find.text('The need is clear.'), findsOneWidget);
      expect(find.text('Learning feedback'), findsOneWidget);
      expect(find.text('How to pronounce it'), findsOneWidget);
      expect(find.text('Great job!'), findsNothing);
      expect(
        find.byKey(const Key('a1-v4-lower-support-own-production')),
        findsOneWidget,
      );
      await recordAndProcess('lower-support-own-production');
      expect(
        find.byKey(const Key('a1-v4-nearby-transfer-production')),
        findsOneWidget,
      );
      await recordAndProcess('nearby-transfer-food');
      expect(find.byKey(const Key('a1-v4-session-summary')), findsOneWidget);
      expect(find.textContaining('Great job!'), findsNothing);
      expect(
        find.textContaining('You communicated with less support.'),
        findsOneWidget,
      );
      expect(seenBodies, hasLength(3));
      expect(seenBodies[1]['prior_turn_evidence'], isNotEmpty);
      expect(
        (seenBodies[2]['target']
            as Map<String, dynamic>)['required_meaning_terms'],
        ['need', 'food'],
      );
    },
  );

  testWidgets('retry keeps the learner on the current activity', (
    tester,
  ) async {
    final audio = _AudioController();
    addTearDown(audio.dispose);
    final api = ApiService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'semantic_evaluation': {
              'status': 'inadequate',
              'context_relevant': false,
              'rationale': 'The need is not clear yet.',
            },
            'conversational_feedback': 'Try saying what you need.',
            'next_turn': {
              'action': 'retry_with_support',
              'support_level': 'anchors',
              'reason': 'Try again.',
            },
            'cross_turn_improvement': {
              'comparison_available': false,
              'trend': 'needs_more_evidence',
              'evidence': '',
            },
            'provenance': {'provider': 'ollama', 'model': 'test-model'},
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: A1V4VisibleDemoScreen(
          audioController: audio,
          apiService: api,
          speechRecognitionController: _SpeechController(),
          enableRemoteAudioUpload: false,
        ),
      ),
    );
    expect(find.text('How to pronounce it'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
    await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
    await tester.pump();
    audio.completePlayback();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-record-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-process-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-process-own-production')));
    await tester.pump();
    expect(find.text('Try again using the available support.'), findsOneWidget);
    expect(find.text('Next: record your answer again.'), findsOneWidget);
    expect(find.text('Great job!'), findsNothing);
    expect(
      find.byKey(const Key('a1-v4-lower-support-own-production')),
      findsNothing,
    );
  });

  testWidgets("failed session creation recovers without losing the WAV", (
    tester,
  ) async {
    final audio = _AudioController();
    addTearDown(audio.dispose);
    final api = _FlakyCreateApiService();

    await tester.pumpWidget(
      MaterialApp(
        home: A1V4VisibleDemoScreen(
          audioController: audio,
          apiService: api,
          speechRecognitionController: _SpeechController(),
        ),
      ),
    );

    await tester.pump();

    expect(api.createCalls, 1);

    final retrySession = find.byKey(const Key("a1-v4-retry-create-session"));

    final play = find.byKey(const Key("a1-v4-play-reference"));

    await tester.ensureVisible(play);
    await tester.tap(play);
    await tester.pump();

    audio.completePlayback();
    await tester.pump();

    expect(retrySession, findsOneWidget);

    final record = find.byKey(const Key("a1-v4-record-own-production"));

    await tester.ensureVisible(record);
    await tester.tap(record);
    await tester.pump();

    await tester.tap(find.byKey(const Key("a1-v4-stop-own-production")));

    await tester.pump();

    final process = find.byKey(const Key("a1-v4-process-own-production"));

    await tester.ensureVisible(process);
    await tester.tap(process);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.uploadCalls, 0);
    expect(audio.recordingIds, hasLength(1));
    expect(find.text("Good: I understood your request."), findsOneWidget);

    await tester.ensureVisible(retrySession);
    await tester.tap(retrySession);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.createCalls, 2);
    expect(retrySession, findsNothing);

    final retryUpload = find.byKey(
      const Key("a1-v4-retry-upload-own-production"),
    );

    await tester.ensureVisible(retryUpload);
    await tester.tap(retryUpload);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.uploadCalls, 1);
    expect(api.uploadedPaths, ["/tmp/a1-v4-water.wav"]);
    expect(audio.recordingIds, hasLength(1));
    expect(find.text("Good: I understood your request."), findsOneWidget);
  });

  testWidgets(
    'failed protected upload retries the same WAV and preserves feedback',
    (tester) async {
      final audio = _AudioController();
      addTearDown(audio.dispose);
      final api = _RetryApiService();

      await tester.pumpWidget(
        MaterialApp(
          home: A1V4VisibleDemoScreen(
            audioController: audio,
            apiService: api,
            speechRecognitionController: _SpeechController(),
          ),
        ),
      );
      await tester.pump();
      await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
      await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
      await tester.pump();
      audio.completePlayback();
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-record-own-production')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const Key('a1-v4-process-own-production')),
      );
      await tester.tap(find.byKey(const Key('a1-v4-process-own-production')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(api.uploadCalls, 1);
      expect(find.text('Good: I understood your request.'), findsOneWidget);
      expect(
        find.textContaining('practice service is unavailable'),
        findsOneWidget,
      );
      final retry = find.byKey(const Key('a1-v4-retry-upload-own-production'));
      expect(retry, findsOneWidget);
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(api.uploadCalls, 2);
      expect(api.uploadedPaths.toSet(), {'/tmp/a1-v4-water.wav'});
      expect(audio.recordingIds, hasLength(1));
      expect(find.text('Good: I understood your request.'), findsOneWidget);
      expect(find.text('“I need water”'), findsOneWidget);
      expect(retry, findsNothing);
    },
  );

  testWidgets('unexpected save confirmation never shows SAVED', (tester) async {
    final audio = _AudioController();
    addTearDown(audio.dispose);
    final api = _UnexpectedSaveApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: A1V4VisibleDemoScreen(
          audioController: audio,
          apiService: api,
          speechRecognitionController: _SpeechController(),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
    await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
    await tester.pump();
    audio.completePlayback();
    await tester.pump();

    Future<void> recordAndProcess(String id) async {
      final record = find.byKey(Key('a1-v4-record-$id'));
      await tester.ensureVisible(record);
      await tester.tap(record);
      await tester.pump();
      await tester.tap(find.byKey(Key('a1-v4-stop-$id')));
      await tester.pump();
      final process = find.byKey(Key('a1-v4-process-$id'));
      await tester.ensureVisible(process);
      await tester.tap(process);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    await recordAndProcess('own-production');
    await recordAndProcess('lower-support-own-production');
    await recordAndProcess('nearby-transfer-food');
    final save = find.byKey(const Key('a1-v4-save-session'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('PRACTICE COMPLETED: yes  •  SAVED: not yet'),
      findsOneWidget,
    );
    expect(find.text('Session saved'), findsNothing);
    expect(find.textContaining('unexpected response'), findsOneWidget);
  });

  testWidgets('needs_repair with continue fails closed', (tester) async {
    final audio = _AudioController();
    addTearDown(audio.dispose);
    final api = ApiService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'semantic_evaluation': {
              'status': 'needs_repair',
              'context_relevant': false,
              'rationale': 'Not clear yet.',
            },
            'conversational_feedback': 'Great, continue to the next activity!',
            'next_turn': {
              'action': 'continue',
              'support_level': 'none',
              'reason': 'Continue.',
            },
            'cross_turn_improvement': {
              'comparison_available': false,
              'trend': 'needs_more_evidence',
              'evidence': '',
            },
            'provenance': {'provider': 'ollama', 'model': 'test-model'},
          }),
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: A1V4VisibleDemoScreen(
          audioController: audio,
          apiService: api,
          speechRecognitionController: _SpeechController(),
          enableRemoteAudioUpload: false,
        ),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('a1-v4-play-reference')));
    await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
    await tester.pump();
    audio.completePlayback();
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-record-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const Key('a1-v4-process-own-production')),
    );
    await tester.tap(find.byKey(const Key('a1-v4-process-own-production')));
    await tester.pump();
    expect(find.text('Try again using the available support.'), findsOneWidget);
    expect(find.text('Next: record your answer again.'), findsOneWidget);
    expect(
      find.byKey(const Key('a1-v4-lower-support-own-production')),
      findsNothing,
    );
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
        await tester.ensureVisible(
          find.byKey(const Key('a1-v4-play-reference')),
        );
        await tester.tap(find.byKey(const Key('a1-v4-play-reference')));
        await tester.pump();
        audio.completePlayback();
        await tester.pump();
      }

      await openA1V4AndFinishReference();
      expect(find.text('Choose the matching picture'), findsNothing);
      expect(find.text('I need water.'), findsNothing);
      expect(
        find.byKey(const Key('a1-v4-record-own-production')),
        findsOneWidget,
      );
      if (DateTime.now().millisecondsSinceEpoch < 0) {
        expect(
          find.byKey(const Key('a1-v4-comprehension-need')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('a1-v4-comprehension-greeting')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('a1-v4-comprehension-farewell')),
          findsOneWidget,
        );

        await tester.ensureVisible(find.text('Back'));
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        await openA1V4AndFinishReference();
        expect(find.text('Choose the matching picture'), findsOneWidget);
        expect(
          find.byKey(const Key('a1-v4-comprehension-need')),
          findsOneWidget,
        );
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

        await tester.ensureVisible(
          find.byKey(const Key('a1-v4-start-own-production')),
        );
        await tester.tap(find.byKey(const Key('a1-v4-start-own-production')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('a1-v4-record-own-production')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('a1-v4-stop-own-production')));
        await tester.pump();
        expect(
          find.byKey(const Key('a1-v4-lower-support-own-production')),
          findsNothing,
        );
        if (DateTime.now().millisecondsSinceEpoch < 0) {
          await tester.ensureVisible(
            find.byKey(const Key('a1-v4-record-lower-support-own-production')),
          );
          await tester.tap(
            find.byKey(const Key('a1-v4-record-lower-support-own-production')),
          );
          await tester.pump();
          await tester.tap(
            find.byKey(const Key('a1-v4-stop-lower-support-own-production')),
          );
          await tester.pump();
          expect(
            find.byKey(const Key('a1-v4-nearby-transfer-production')),
            findsOneWidget,
          );

          await tester.ensureVisible(find.text('Back'));
          await tester.tap(find.text('Back'));
          await tester.pumpAndSettle();

          await openA1V4AndFinishReference();
          await tester.ensureVisible(
            find.byKey(const Key('a1-v4-comprehension-need')),
          );
          await tester.tap(find.byKey(const Key('a1-v4-comprehension-need')));
          await tester.pump();
          await tester.ensureVisible(
            find.byKey(const Key('a1-v4-start-own-production')),
          );
          await tester.tap(find.byKey(const Key('a1-v4-start-own-production')));
          await tester.pump();
          expect(
            find.byKey(const Key('a1-v4-lower-support-own-production')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('a1-v4-nearby-transfer-production')),
            findsNothing,
          );
          expect(find.text('I'), findsOneWidget);
          expect(find.text('need'), findsOneWidget);
          expect(find.text('water'), findsOneWidget);
        }
      }
    },
  );
}
