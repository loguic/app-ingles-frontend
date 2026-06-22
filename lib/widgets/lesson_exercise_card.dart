import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';

/// Interactive card for one lesson exercise.
/// Tarjeta interactiva para un ejercicio de la lección.
class LessonExerciseCard extends StatefulWidget {
  const LessonExerciseCard({
    required this.exercise,
    super.key,
  });

  final LessonExercise exercise;

  @override
  State<LessonExerciseCard> createState() => _LessonExerciseCardState();
}

class _LessonExerciseCardState extends State<LessonExerciseCard> {
  static final ApiService _apiService = ApiService();

  int? _selectedOptionIndex;
  bool? _isCorrect;
  bool _isSubmitting = false;

  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
      _isCorrect = null;
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
    });

    final result = await _apiService.submitExerciseAnswer(
      exerciseId: widget.exercise.id,
      selectedIndex: selectedOptionIndex,
    );

    setState(() {
      _isSubmitting = false;
      _isCorrect = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptionIndex = _selectedOptionIndex;
    final isCorrect = _isCorrect;

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
              onPressed:
                  selectedOptionIndex == null || _isSubmitting ? null : _checkAnswer,
              child: Text(_isSubmitting ? 'Comprobando...' : 'Comprobar'),
            ),
            if (isCorrect != null) ...[
              const SizedBox(height: 8),
              Text(
                isCorrect ? 'Respuesta correcta' : 'Respuesta incorrecta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}