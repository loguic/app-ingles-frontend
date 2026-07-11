import 'dart:async';

import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';
import '../services/pronunciation_audio_service.dart';
import '../widgets/info_card.dart';
import '../widgets/lesson_detail_card.dart';

/// Screen that loads and displays the full detail of one lesson.
/// Pantalla que carga y muestra el detalle completo de una lección.
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({
    required this.lessonId,
    required this.levelId,
    required this.unitId,
    super.key,
  });

  final String lessonId;
  final String levelId;
  final String unitId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  static final ApiService _apiService = ApiService();

  final PronunciationAudioService _pronunciationAudioService =
      PronunciationAudioService();

  @override
  void dispose() {
    // Releases audio resources and removes the temporary recording.
    // Libera los recursos de audio y elimina la grabación temporal.
    unawaited(_pronunciationAudioService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de lección'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: FutureBuilder<Lesson?>(
              future: _apiService.getLesson(widget.lessonId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const InfoCard(
                    title: 'Detalle de lección',
                    child: Text('Cargando detalle de lección...'),
                  );
                }

                if (snapshot.hasError || snapshot.data == null) {
                  return const InfoCard(
                    title: 'Detalle de lección',
                    child: Text('No se pudo cargar la lección'),
                  );
                }

                return LessonDetailCard(
                  lesson: snapshot.data!,
                  levelId: widget.levelId,
                  unitId: widget.unitId,
                  pronunciationAudioService: _pronunciationAudioService,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
