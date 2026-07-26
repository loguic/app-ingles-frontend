import "dart:io";
import "dart:isolate";

import "package:sherpa_onnx/sherpa_onnx.dart" as sherpa;

import "speech_recognition_service.dart";

/// File paths required by a Moonshine v1 recognition model.
/// Rutas requeridas por un modelo de reconocimiento Moonshine v1.
class SherpaOnnxMoonshineModelPaths {
  const SherpaOnnxMoonshineModelPaths({
    required this.preprocessorPath,
    required this.encoderPath,
    required this.uncachedDecoderPath,
    required this.cachedDecoderPath,
    required this.tokensPath,
  });

  final String preprocessorPath;
  final String encoderPath;
  final String uncachedDecoderPath;
  final String cachedDecoderPath;
  final String tokensPath;
}

/// Raw technical output produced by the Sherpa-ONNX runtime.
/// Resultado técnico bruto producido por el runtime Sherpa-ONNX.
class SherpaOnnxRecognitionOutput {
  const SherpaOnnxRecognitionOutput({
    required this.transcript,
    this.detectedLanguage,
  });

  final String transcript;
  final String? detectedLanguage;
}

/// Isolates native Sherpa-ONNX execution from the application contract.
/// Aísla la ejecución nativa de Sherpa-ONNX del contrato de la aplicación.
abstract interface class SherpaOnnxRecognitionRuntime {
  Future<SherpaOnnxRecognitionOutput> recognize({
    required String audioPath,
    required SherpaOnnxMoonshineModelPaths modelPaths,
  });
}

/// Executes Moonshine recognition through the native Sherpa-ONNX runtime.
/// Ejecuta reconocimiento Moonshine mediante el runtime nativo Sherpa-ONNX.
class SherpaOnnxNativeRecognitionRuntime
    implements SherpaOnnxRecognitionRuntime {
  SherpaOnnxNativeRecognitionRuntime({
    this.numThreads = 1,
  });

  final int numThreads;

  static bool _bindingsInitialized = false;

  Future<void> _ensureBindingsInitialized() async {
    if (_bindingsInitialized) {
      return;
    }

    if (!Platform.isLinux) {
      throw UnsupportedError(
        "B127 native recognition is currently validated only on Linux.",
      );
    }

    final uri = await Isolate.resolvePackageUri(
      Uri.parse("package:sherpa_onnx_linux/any_path_is_ok_here.dart"),
    );
    if (uri == null) {
      throw StateError("Unable to resolve sherpa_onnx_linux.");
    }

    final packageRoot = File.fromUri(uri).parent.parent;
    final architecture =
        Platform.version.contains("arm64") ||
            Platform.version.contains("aarch64")
        ? "aarch64"
        : "x64";

    sherpa.initBindings(
      "${packageRoot.path}/linux/$architecture",
    );
    _bindingsInitialized = true;
  }

  @override
  Future<SherpaOnnxRecognitionOutput> recognize({
    required String audioPath,
    required SherpaOnnxMoonshineModelPaths modelPaths,
  }) async {
    await _ensureBindingsInitialized();

    final moonshine = sherpa.OfflineMoonshineModelConfig(
      preprocessor: modelPaths.preprocessorPath,
      encoder: modelPaths.encoderPath,
      uncachedDecoder: modelPaths.uncachedDecoderPath,
      cachedDecoder: modelPaths.cachedDecoderPath,
    );

    final recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          moonshine: moonshine,
          tokens: modelPaths.tokensPath,
          debug: false,
          numThreads: numThreads,
        ),
      ),
    );

    final wave = sherpa.readWave(audioPath);
    if (wave.samples.isEmpty || wave.sampleRate <= 0) {
      recognizer.free();
      throw StateError("Unable to read recognition WAV.");
    }

    final stream = recognizer.createStream();

    try {
      stream.acceptWaveform(
        samples: wave.samples,
        sampleRate: wave.sampleRate,
      );
      recognizer.decode(stream);

      final result = recognizer.getResult(stream);
      final detectedLanguage = result.lang.trim();

      return SherpaOnnxRecognitionOutput(
        transcript: result.text,
        detectedLanguage:
            detectedLanguage.isEmpty ? null : detectedLanguage,
      );
    } finally {
      stream.free();
      recognizer.free();
    }
  }
}

/// Speech recognition controller backed by Sherpa-ONNX.
///
/// Controlador de reconocimiento de voz basado en Sherpa-ONNX.
///
/// Model paths are injected explicitly so the recognition layer does not own
/// model storage or packaging decisions.
/// Las rutas se inyectan explícitamente para que esta capa no decida dónde
/// se almacenan o empaquetan los modelos.
class SherpaOnnxSpeechRecognitionController
    implements SpeechRecognitionController {
  const SherpaOnnxSpeechRecognitionController({
    required this.modelPaths,
    this.runtime,
  });

  final SherpaOnnxMoonshineModelPaths modelPaths;
  final SherpaOnnxRecognitionRuntime? runtime;

  /// Derives contract-level words from the final recognized transcript.
  /// Deriva palabras del contrato desde la transcripción final reconocida.
  static List<String> wordsFromTranscript(String transcript) {
    final wordPattern = RegExp(r"[A-Za-z]+(?:[\x27’][A-Za-z]+)?");
    return wordPattern
        .allMatches(transcript)
        .map((match) => match.group(0)!)
        .toList(growable: false);
  }

  @override
  Future<SpeechRecognitionResult> recognize(
    SpeechRecognitionRequest request,
  ) async {
    final activeRuntime = runtime;
    if (activeRuntime == null) {
      throw UnsupportedError(
        "Sherpa-ONNX recognition runtime is not wired yet.",
      );
    }

    try {
      final output = await activeRuntime.recognize(
        audioPath: request.audioPath,
        modelPaths: modelPaths,
      );
      final transcript = output.transcript.trim();

      return SpeechRecognitionResult(
        status: transcript.isEmpty
            ? SpeechRecognitionStatus.noSpeech
            : SpeechRecognitionStatus.recognized,
        transcript: transcript.isEmpty ? null : transcript,
        words: transcript.isEmpty ? const [] : wordsFromTranscript(transcript),
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
    } catch (_) {
      return SpeechRecognitionResult(
        status: SpeechRecognitionStatus.failed,
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
  }
}
