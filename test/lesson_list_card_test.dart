import 'package:app_ingles/models/lesson.dart';
import 'package:app_ingles/models/progress_record.dart';
import 'package:app_ingles/services/api_service.dart';
import 'package:app_ingles/widgets/lesson_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simulates lesson and progress requests without using the real backend.
/// Simula solicitudes de lecciones y progreso sin utilizar el backend real.
class FakeApiService extends ApiService {
  FakeApiService({required this.lessons, required this.progressRecords});

  final List<Lesson> lessons;
  final List<ProgressRecord> progressRecords;

  @override
  Future<List<Lesson>> getLessons(String unitId) async => lessons;

  @override
  Future<List<ProgressRecord>> getProgress(String userId) async =>
      progressRecords;
}

LessonExercise testExercise(String id) {
  return LessonExercise(
    id: id,
    type: 'multiple_choice',
    prompt: 'Ejercicio $id',
    options: const ['Opción uno', 'Opción dos'],
    answerIndex: 0,
    skillIds: const [],
  );
}

Lesson testLesson(String id, String title) {
  return Lesson(
    id: id,
    title: title,
    objective: 'Objetivo de $title',
    vocabulary: const [],
    grammar: const [],
    examples: const [],
    exercises: [testExercise('$id-q1'), testExercise('$id-q2')],
  );
}

ProgressRecord testProgress({
  required String lessonId,
  required String exerciseId,
}) {
  return ProgressRecord(
    userId: 'demo-user',
    levelId: 'A1',
    unitId: 'unit-test',
    lessonId: lessonId,
    exerciseId: exerciseId,
    selectedIndex: 0,
    correct: true,
  );
}

void main() {
  testWidgets('shows persistent progress using unique answered exercises', (
    tester,
  ) async {
    final lessons = [
      testLesson('lesson-empty', 'Lección sin actividad'),
      testLesson('lesson-progress', 'Lección en progreso'),
      testLesson('lesson-complete', 'Lección respondida'),
    ];

    final progressRecords = [
      testProgress(
        lessonId: 'lesson-progress',
        exerciseId: 'lesson-progress-q1',
      ),
      testProgress(
        lessonId: 'lesson-progress',
        exerciseId: 'lesson-progress-q1',
      ),
      testProgress(
        lessonId: 'lesson-complete',
        exerciseId: 'lesson-complete-q1',
      ),
      testProgress(
        lessonId: 'lesson-complete',
        exerciseId: 'lesson-complete-q2',
      ),
      testProgress(
        lessonId: 'lesson-complete',
        exerciseId: 'exercise-that-does-not-belong',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LessonListCard(
              selectedUnitId: 'unit-test',
              selectedLessonId: null,
              onLessonSelected: (_) {},
              apiService: FakeApiService(
                lessons: lessons,
                progressRecords: progressRecords,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Sin actividad'), findsOneWidget);
    expect(
      find.textContaining('En progreso: 1 de 2 ejercicios'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Todos los ejercicios respondidos'),
      findsOneWidget,
    );
  });
}
