import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';
import 'info_card.dart';

/// Shows the lesson list for the selected unit.
/// Muestra la lista de lecciones de la unidad seleccionada.
class LessonListCard extends StatelessWidget {
  const LessonListCard({
    required this.selectedUnitId,
    required this.selectedLessonId,
    required this.onLessonSelected,
    super.key,
  });

  static final ApiService _apiService = ApiService();

  final String selectedUnitId;
  final String? selectedLessonId;
  final ValueChanged<String> onLessonSelected;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Lecciones de $selectedUnitId',
      child: FutureBuilder<List<Lesson>>(
        future: _apiService.getLessons(selectedUnitId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando lecciones...');
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('No se pudieron cargar las lecciones');
          }

          final lessons = snapshot.data!;

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
                      subtitle: Text(lesson.objective ?? lesson.id),
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