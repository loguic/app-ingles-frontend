import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';

/// Interactive card for one lesson exercise.
/// Tarjeta interactiva para un ejercicio de la lección.
class LessonExerciseCard extends StatefulWidget {
  const LessonExerciseCard({
    required this.exercise,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    this.apiService,
    this.onResultChanged,
    super.key,
  });

  final LessonExercise exercise;
  final String levelId;
  final String unitId;
  final String lessonId;

  /// Optional API service used to make the widget testable.
  /// Servicio API opcional que permite probar el widget.
  final ApiService? apiService;

  /// Reports each successfully checked result to the parent widget.
  /// Comunica cada resultado comprobado correctamente al widget padre.
  final ValueChanged<bool>? onResultChanged;

  @override
  State<LessonExerciseCard> createState() => _LessonExerciseCardState();
}

class _LessonExerciseCardState extends State<LessonExerciseCard> {
  static final ApiService _defaultApiService = ApiService();

  ApiService get _apiService => widget.apiService ?? _defaultApiService;

  int? _selectedOptionIndex;
  bool? _isCorrect;
  bool _isSubmitting = false;
  String? _feedbackMessage;

  String get _correctAnswer {
    return widget.exercise.options[widget.exercise.answerIndex];
  }

  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
      _isCorrect = null;
      _feedbackMessage = null;
    });
  }

  Future<void> _checkAnswer() async {
    final selectedOptionIndex = _selectedOptionIndex;

    if (selectedOptionIndex == null || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isCorrect = null;
      _feedbackMessage = null;
    });

    final result = await _apiService.submitExerciseAnswer(
      exerciseId: widget.exercise.id,
      selectedIndex: selectedOptionIndex,
    );

    if (result != null) {
      await _apiService.saveProgress(
        userId: 'demo-user',
        levelId: widget.levelId,
        unitId: widget.unitId,
        lessonId: widget.lessonId,
        exerciseId: widget.exercise.id,
        selectedIndex: selectedOptionIndex,
        correct: result,
      );
      widget.onResultChanged?.call(result);
    }

    setState(() {
      _isSubmitting = false;
      _isCorrect = result;
      _feedbackMessage = _buildFeedbackMessage(result);
    });
  }

  String _buildFeedbackMessage(bool? isCorrect) {
    if (isCorrect == null) {
      return 'No se pudo comprobar la respuesta. Inténtalo nuevamente.';
    }

    if (isCorrect) {
      return 'Muy bien. Esta respuesta encaja con el objetivo del ejercicio.';
    }

    return 'Revisa la opción correcta: "$_correctAnswer". '
        'Compárala con tu respuesta y observa cuándo se usa.';
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptionIndex = _selectedOptionIndex;
    final isCorrect = _isCorrect;
    final feedbackMessage = _feedbackMessage;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.exercise.prompt,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...widget.exercise.options.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  selectedOptionIndex == entry.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                title: Text(entry.value),
                onTap: _isSubmitting ? null : () => _selectOption(entry.key),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: selectedOptionIndex == null || _isSubmitting
                  ? null
                  : _checkAnswer,
              child: Text(_isSubmitting ? 'Comprobando...' : 'Comprobar'),
            ),
            if (isCorrect != null || feedbackMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                isCorrect == true
                    ? 'Respuesta correcta'
                    : 'Respuesta incorrecta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCorrect == true ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text(feedbackMessage ?? ''),
            ],
          ],
        ),
      ),
    );
  }
}
