import "package:app_ingles/services/sherpa_onnx_speech_recognition_service.dart";
import "package:app_ingles/services/speech_recognition_service.dart";
import "package:flutter_test/flutter_test.dart";

class FakeSherpaOnnxRecognitionRuntime
    implements SherpaOnnxRecognitionRuntime {
  @override
  Future<SherpaOnnxRecognitionOutput> recognize({
    required String audioPath,
    required SherpaOnnxMoonshineModelPaths modelPaths,
  }) async {
    return const SherpaOnnxRecognitionOutput(
      transcript: "Hello, what is your name?",
      detectedLanguage: "en",
    );
  }
}

class EmptySherpaOnnxRecognitionRuntime
    implements SherpaOnnxRecognitionRuntime {
  @override
  Future<SherpaOnnxRecognitionOutput> recognize({
    required String audioPath,
    required SherpaOnnxMoonshineModelPaths modelPaths,
  }) async {
    return const SherpaOnnxRecognitionOutput(transcript: "   ");
  }
}

class FailingSherpaOnnxRecognitionRuntime
    implements SherpaOnnxRecognitionRuntime {
  @override
  Future<SherpaOnnxRecognitionOutput> recognize({
    required String audioPath,
    required SherpaOnnxMoonshineModelPaths modelPaths,
  }) async {
    throw StateError("recognition failed");
  }
}

void main() {
  test("constructs the native Sherpa runtime without starting recognition", () {
    final SherpaOnnxRecognitionRuntime runtime =
        SherpaOnnxNativeRecognitionRuntime();

    expect(runtime, isA<SherpaOnnxNativeRecognitionRuntime>());
  });


  test("maps runtime failure to failed status", () async {
    const paths = SherpaOnnxMoonshineModelPaths(
      preprocessorPath: "/models/preprocess.onnx",
      encoderPath: "/models/encode.int8.onnx",
      uncachedDecoderPath: "/models/uncached_decode.int8.onnx",
      cachedDecoderPath: "/models/cached_decode.int8.onnx",
      tokensPath: "/models/tokens.txt",
    );

    final controller = SherpaOnnxSpeechRecognitionController(
      modelPaths: paths,
      runtime: FailingSherpaOnnxRecognitionRuntime(),
    );

    const request = SpeechRecognitionRequest(
      audioPath: "/tmp/broken.wav",
      languageCode: "en",
      userId: "demo-user",
      levelId: "A1",
      unitId: "a1-u1",
      lessonId: "a1-u1-l1",
      conversationId: "a1-u1-l1-c1",
      turnId: "t2",
    );

    final result = await controller.recognize(request);

    expect(result.status, SpeechRecognitionStatus.failed);
    expect(result.transcript, isNull);
    expect(result.words, isEmpty);
    expect(result.turnId, request.turnId);
  });


  test("maps empty runtime transcript to noSpeech", () async {
    const paths = SherpaOnnxMoonshineModelPaths(
      preprocessorPath: "/models/preprocess.onnx",
      encoderPath: "/models/encode.int8.onnx",
      uncachedDecoderPath: "/models/uncached_decode.int8.onnx",
      cachedDecoderPath: "/models/cached_decode.int8.onnx",
      tokensPath: "/models/tokens.txt",
    );

    final controller = SherpaOnnxSpeechRecognitionController(
      modelPaths: paths,
      runtime: EmptySherpaOnnxRecognitionRuntime(),
    );

    const request = SpeechRecognitionRequest(
      audioPath: "/tmp/silence.wav",
      languageCode: "en",
      userId: "demo-user",
      levelId: "A1",
      unitId: "a1-u1",
      lessonId: "a1-u1-l1",
      conversationId: "a1-u1-l1-c1",
      turnId: "t2",
    );

    final result = await controller.recognize(request);

    expect(result.status, SpeechRecognitionStatus.noSpeech);
    expect(result.transcript, isNull);
    expect(result.words, isEmpty);
    expect(result.turnId, request.turnId);
  });


  test("maps runtime recognition into the neutral contract", () async {
    const paths = SherpaOnnxMoonshineModelPaths(
      preprocessorPath: "/models/preprocess.onnx",
      encoderPath: "/models/encode.int8.onnx",
      uncachedDecoderPath: "/models/uncached_decode.int8.onnx",
      cachedDecoderPath: "/models/cached_decode.int8.onnx",
      tokensPath: "/models/tokens.txt",
    );

    final controller = SherpaOnnxSpeechRecognitionController(
      modelPaths: paths,
      runtime: FakeSherpaOnnxRecognitionRuntime(),
    );

    const request = SpeechRecognitionRequest(
      audioPath: "/tmp/learner.wav",
      languageCode: "en",
      userId: "demo-user",
      levelId: "A1",
      unitId: "a1-u1",
      lessonId: "a1-u1-l1",
      conversationId: "a1-u1-l1-c1",
      turnId: "t2",
    );

    final result = await controller.recognize(request);

    expect(result.status, SpeechRecognitionStatus.recognized);
    expect(result.transcript, "Hello, what is your name?");
    expect(result.words, ["Hello", "what", "is", "your", "name"]);
    expect(result.languageCode, "en");
    expect(result.userId, request.userId);
    expect(result.conversationId, request.conversationId);
    expect(result.turnId, request.turnId);
  });


  test("derives recognized words from transcript instead of engine tokens", () {
    expect(
      SherpaOnnxSpeechRecognitionController.wordsFromTranscript(
        "Hello, what is your name?",
      ),
      ["Hello", "what", "is", "your", "name"],
    );
  });


  test("keeps Moonshine paths explicit and controller engine-neutral", () {
    const paths = SherpaOnnxMoonshineModelPaths(
      preprocessorPath: "/models/preprocess.onnx",
      encoderPath: "/models/encode.int8.onnx",
      uncachedDecoderPath: "/models/uncached_decode.int8.onnx",
      cachedDecoderPath: "/models/cached_decode.int8.onnx",
      tokensPath: "/models/tokens.txt",
    );

    final SpeechRecognitionController controller =
        SherpaOnnxSpeechRecognitionController(modelPaths: paths);

    expect(paths.preprocessorPath, "/models/preprocess.onnx");
    expect(paths.encoderPath, "/models/encode.int8.onnx");
    expect(paths.uncachedDecoderPath, "/models/uncached_decode.int8.onnx");
    expect(paths.cachedDecoderPath, "/models/cached_decode.int8.onnx");
    expect(paths.tokensPath, "/models/tokens.txt");
    expect(controller, isA<SherpaOnnxSpeechRecognitionController>());
  });
}
