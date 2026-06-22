import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/lesson_detail_card.dart';

/// Screen that loads and displays the full detail of one lesson.
/// Pantalla que carga y muestra el detalle completo de una lección.
class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({
    super.key,
    required this.lessonId,
  });

  final String lessonId;

  static final ApiService _apiService = ApiService();

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
              future: _apiService.getLesson(lessonId),
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

                return LessonDetailCard(lesson: snapshot.data!);
              },
            ),
          ),
        ),
      ),
    );
  }
}
