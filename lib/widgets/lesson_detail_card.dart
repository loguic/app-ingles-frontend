import 'package:flutter/material.dart';

import '../models/lesson.dart';
import 'info_card.dart';
import 'lesson_exercise_card.dart';

/// Shows the full content of a selected lesson.
/// Muestra el contenido completo de una lección seleccionada.
class LessonDetailCard extends StatelessWidget {
  const LessonDetailCard({
    required this.lesson,
    required this.levelId,
    required this.unitId,
    super.key,
  });

  final Lesson lesson;
  final String levelId;
  final String unitId;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: lesson.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lesson.objective != null)
            LessonContentSection(
              title: 'Objetivo',
              child: Text(lesson.objective!),
            ),
          LessonContentSection(
            title: 'Vocabulario',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lesson.vocabulary
                  .map((word) => Chip(label: Text(word)))
                  .toList(),
            ),
          ),
          LessonContentSection(
            title: 'Gramática',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lesson.grammar.map((item) => Text('• $item')).toList(),
            ),
          ),
          LessonContentSection(
            title: 'Ejemplos',
            child: Column(
              children: lesson.examples
                  .map(
                    (example) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(example.en),
                      subtitle: Text(example.es),
                    ),
                  )
                  .toList(),
            ),
          ),
          LessonContentSection(
            title: 'Ejercicios',
            child: Column(
              children: lesson.exercises
                  .map(
                    (exercise) => LessonExerciseCard(
                      exercise: exercise,
                      levelId: levelId,
                      unitId: unitId,
                      lessonId: lesson.id,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}