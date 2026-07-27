import 'dart:io';

import 'sherpa_onnx_speech_recognition_service.dart';
import 'speech_recognition_config.dart';
import 'speech_recognition_service.dart';

/// Builds the real speech-recognition controller from external configuration.
/// Construye el controlador real de reconocimiento desde configuración externa.
SpeechRecognitionController? createConfiguredSpeechRecognitionController() {
  if (!Platform.isLinux || !SpeechRecognitionConfig.isConfigured) {
    return null;
  }

  final directory = SpeechRecognitionConfig.modelDirectory;
  final modelPaths = SherpaOnnxMoonshineModelPaths(
    preprocessorPath: '$directory/preprocess.onnx',
    encoderPath: '$directory/encode.int8.onnx',
    uncachedDecoderPath: '$directory/uncached_decode.int8.onnx',
    cachedDecoderPath: '$directory/cached_decode.int8.onnx',
    tokensPath: '$directory/tokens.txt',
  );

  // Recognition remains optional when the external model is incomplete.
  // El reconocimiento sigue siendo opcional si el modelo externo está incompleto.
  final requiredPaths = <String>[
    modelPaths.preprocessorPath,
    modelPaths.encoderPath,
    modelPaths.uncachedDecoderPath,
    modelPaths.cachedDecoderPath,
    modelPaths.tokensPath,
  ];

  if (requiredPaths.any((path) => !File(path).existsSync())) {
    return null;
  }

  return SherpaOnnxSpeechRecognitionController(
    modelPaths: modelPaths,
    runtime: SherpaOnnxNativeRecognitionRuntime(),
  );
}
