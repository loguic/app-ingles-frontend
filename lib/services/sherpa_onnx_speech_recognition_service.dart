import "dart:io";
import "dart:math" as math;
import "dart:typed_data";

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
  SherpaOnnxNativeRecognitionRuntime({this.numThreads = 1});

  final int numThreads;

  static bool _bindingsInitialized = false;

  /// Trims only leading and trailing silence while preserving internal pauses.
  /// Recorta solo silencio inicial y final conservando las pausas internas.
  Float32List _trimEdgeSilence(Float32List samples, int sampleRate) {
    if (samples.isEmpty || sampleRate <= 0) {
      return samples;
    }

    const threshold = 0.0056; // Approximately -45 dBFS.
    const frameDurationMs = 20;
    const requiredActiveMs = 100;
    const paddingMs = 100;

    final frameSize = math.max(1, sampleRate * frameDurationMs ~/ 1000);
    final requiredFrames = math.max(1, requiredActiveMs ~/ frameDurationMs);
    final paddingSamples = sampleRate * paddingMs ~/ 1000;

    bool isActiveFrame(int frameIndex) {
      final start = frameIndex * frameSize;
      final end = math.min(start + frameSize, samples.length);
      var sumSquares = 0.0;

      for (var i = start; i < end; i++) {
        final sample = samples[i];
        sumSquares += sample * sample;
      }

      final rms = math.sqrt(sumSquares / (end - start));
      return rms >= threshold;
    }

    final frameCount = (samples.length + frameSize - 1) ~/ frameSize;

    int? firstActiveFrame;
    var activeRun = 0;

    for (var frame = 0; frame < frameCount; frame++) {
      if (isActiveFrame(frame)) {
        activeRun += 1;
        if (activeRun >= requiredFrames) {
          firstActiveFrame = frame - requiredFrames + 1;
          break;
        }
      } else {
        activeRun = 0;
      }
    }

    if (firstActiveFrame == null) {
      return samples;
    }

    int? lastActiveFrame;
    activeRun = 0;

    for (var frame = frameCount - 1; frame >= 0; frame--) {
      if (isActiveFrame(frame)) {
        activeRun += 1;
        if (activeRun >= requiredFrames) {
          lastActiveFrame = frame + requiredFrames - 1;
          break;
        }
      } else {
        activeRun = 0;
      }
    }

    if (lastActiveFrame == null) {
      return samples;
    }

    final start = math.max(0, firstActiveFrame * frameSize - paddingSamples);
    final end = math.min(
      samples.length,
      (lastActiveFrame + 1) * frameSize + paddingSamples,
    );

    if (end <= start) {
      return samples;
    }

    return Float32List.fromList(samples.sublist(start, end));
  }

  Future<void> _ensureBindingsInitialized() async {
    if (_bindingsInitialized) {
      return;
    }

    if (!Platform.isLinux) {
      throw UnsupportedError(
        "B127 native recognition is currently validated only on Linux.",
      );
    }

    // Flutter Linux bundles the native Sherpa libraries with the application.
    // Flutter Linux empaqueta las librerías nativas Sherpa con la aplicación.
    sherpa.initBindings();
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

    final preparedSamples = _trimEdgeSilence(wave.samples, wave.sampleRate);

    final stream = recognizer.createStream();

    try {
      stream.acceptWaveform(
        samples: preparedSamples,
        sampleRate: wave.sampleRate,
      );
      recognizer.decode(stream);

      final result = recognizer.getResult(stream);
      final detectedLanguage = result.lang.trim();

      return SherpaOnnxRecognitionOutput(
        transcript: result.text,
        detectedLanguage: detectedLanguage.isEmpty ? null : detectedLanguage,
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
    } catch (error, stackTrace) {
      // Keeps recognition failure non-blocking while exposing technical diagnostics.
      // Mantiene el fallo no bloqueante y expone el diagnóstico técnico.
      stderr.writeln("Sherpa recognition failed: $error");
      stderr.writeln(stackTrace);

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
