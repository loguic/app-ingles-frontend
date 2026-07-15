import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/progress_record.dart';
import '../services/api_service.dart';
import 'info_card.dart';

/// Shows the lesson list for the selected unit.
/// Muestra la lista de lecciones de la unidad seleccionada.
class LessonListCard extends StatelessWidget {
  const LessonListCard({
    required this.selectedUnitId,
    required this.selectedLessonId,
    required this.onLessonSelected,
    this.apiService,
    this.userId = 'demo-user',
    super.key,
  });

  static final ApiService _defaultApiService = ApiService();

  final String selectedUnitId;
  final String? selectedLessonId;
  final ValueChanged<String> onLessonSelected;
  final ApiService? apiService;
  final String userId;

  ApiService get _apiService => apiService ?? _defaultApiService;

  /// Loads lessons and saved progress in parallel.
  /// Carga en paralelo las lecciones y el progreso guardado.
  Future<_LessonListData> _loadData() async {
    final lessonsFuture = _apiService.getLessons(selectedUnitId);
    final progressFuture = _apiService.getProgress(userId);

    return _LessonListData(
      lessons: await lessonsFuture,
      progressRecords: await progressFuture,
    );
  }

  /// Calculates persistent progress using unique answered exercise IDs.
  /// Calcula el progreso persistente usando ejercicios respondidos únicos.
  String _progressLabel(Lesson lesson, List<ProgressRecord> progressRecords) {
    final lessonExerciseIds = lesson.exercises
        .map((exercise) => exercise.id)
        .toSet();

    final answeredExerciseIds = progressRecords
        .where(
          (record) =>
              record.lessonId == lesson.id &&
              lessonExerciseIds.contains(record.exerciseId),
        )
        .map((record) => record.exerciseId)
        .toSet();

    final totalExercises = lessonExerciseIds.length;
    final answeredExercises = answeredExerciseIds.length;

    if (totalExercises == 0 || answeredExercises == 0) {
      return 'Sin actividad';
    }

    if (answeredExercises >= totalExercises) {
      return 'Todos los ejercicios respondidos';
    }

    return 'En progreso: $answeredExercises de $totalExercises ejercicios';
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Lecciones de $selectedUnitId',
      child: FutureBuilder<_LessonListData>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando lecciones...');
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('No se pudieron cargar las lecciones');
          }

          final data = snapshot.data!;
          final lessons = data.lessons;

          if (lessons.isEmpty) {
            return const Text('No hay lecciones para esta unidad');
          }

          return Column(
            children: lessons
                .map(
                  (lesson) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.school),
                      title: Text(lesson.title),
                      subtitle: Text(
                        '${lesson.objective ?? lesson.id}\n'
                        '${_progressLabel(lesson, data.progressRecords)}',
                      ),
                      selected: lesson.id == selectedLessonId,
                      onTap: () => onLessonSelected(lesson.id),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

/// Groups the data required to render the lesson list.
/// Agrupa los datos necesarios para mostrar la lista de lecciones.
class _LessonListData {
  const _LessonListData({required this.lessons, required this.progressRecords});

  final List<Lesson> lessons;
  final List<ProgressRecord> progressRecords;
}
