import 'package:flutter/material.dart';

import '../models/lesson.dart';

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
  int? _selectedOptionIndex;
  bool _hasCheckedAnswer = false;

  bool get _isCorrect =>
      _selectedOptionIndex == widget.exercise.answerIndex;

  void _selectOption(int index) {
    setState(() {
      _selectedOptionIndex = index;
      _hasCheckedAnswer = false;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null) {
      return;
    }

    setState(() {
      _hasCheckedAnswer = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedOptionIndex = _selectedOptionIndex;

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
                    onTap: () => _selectOption(entry.key),
                  ),
                ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: selectedOptionIndex == null ? null : _checkAnswer,
              child: const Text('Comprobar'),
            ),
            if (_hasCheckedAnswer) ...[
              const SizedBox(height: 8),
              Text(
                _isCorrect ? 'Respuesta correcta' : 'Respuesta incorrecta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}