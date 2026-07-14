import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';
import '../services/pronunciation_audio_service.dart';
import 'info_card.dart';
import 'lesson_exercise_card.dart';
import 'lesson_pronunciation_controls.dart';

/// Shows the full content of a selected lesson.
/// Muestra el contenido completo de una lección seleccionada.
class LessonDetailCard extends StatefulWidget {
  const LessonDetailCard({
    required this.lesson,
    required this.levelId,
    required this.unitId,
    required this.pronunciationAudioService,
    this.exerciseApiService,
    super.key,
  });

  final Lesson lesson;
  final String levelId;
  final String unitId;

  /// Shared audio service owned by the lesson screen.
  /// Servicio de audio compartido y administrado por la pantalla.
  final PronunciationAudioController pronunciationAudioService;

  /// Optional API service forwarded to exercises for widget tests.
  /// Servicio API opcional enviado a los ejercicios para sus pruebas.
  final ApiService? exerciseApiService;

  @override
  State<LessonDetailCard> createState() => _LessonDetailCardState();
}

class _LessonDetailCardState extends State<LessonDetailCard> {
  /// Stores the latest result of each exercise during the current session.
  /// Guarda el último resultado de cada ejercicio durante la sesión actual.
  final Map<String, bool> _exerciseResults = {};

  int get _totalExercises => widget.lesson.exercises.length;

  int get _completedExercises => _exerciseResults.length;

  int get _correctAnswers =>
      _exerciseResults.values.where((isCorrect) => isCorrect).length;

  bool get _isLessonComplete =>
      _totalExercises > 0 && _completedExercises == _totalExercises;

  String get _completionGuidance {
    if (_correctAnswers == _totalExercises) {
      return 'Excelente trabajo. Has respondido correctamente todos los ejercicios.';
    }

    return 'Revisa la retroalimentación de los ejercicios y vuelve a practicar los que necesites.';
  }

  /// Updates one exercise without counting repeated checks more than once.
  /// Actualiza un ejercicio sin contar varias veces sus comprobaciones.
  void _handleExerciseResult(String exerciseId, bool isCorrect) {
    setState(() {
      _exerciseResults[exerciseId] = isCorrect;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

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
              children: lesson.examples.asMap().entries.map((entry) {
                final exampleIndex = entry.key;
                final example = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(example.en),
                      subtitle: Text(example.es),
                    ),

                    // Shares one audio coordinator across the lesson.
                    // Comparte un coordinador de audio en toda la lección.
                    LessonPronunciationControls(
                      exampleId: '${lesson.id}:example:$exampleIndex',
                      pronunciations: example.pronunciations,
                      audioService: widget.pronunciationAudioService,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          LessonContentSection(
            title: 'Ejercicios',
            child: Column(
              children: lesson.exercises
                  .map(
                    (exercise) => LessonExerciseCard(
                      exercise: exercise,
                      levelId: widget.levelId,
                      unitId: widget.unitId,
                      lessonId: lesson.id,
                      apiService: widget.exerciseApiService,
                      onResultChanged: (isCorrect) {
                        _handleExerciseResult(exercise.id, isCorrect);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          LessonContentSection(
            title: 'Progreso de la lección',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ejercicios completados: '
                  '$_completedExercises de $_totalExercises',
                ),
                if (_isLessonComplete) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Lección completada',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Respuestas correctas: '
                    '$_correctAnswers de $_totalExercises',
                  ),
                  const SizedBox(height: 4),
                  Text(_completionGuidance),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
