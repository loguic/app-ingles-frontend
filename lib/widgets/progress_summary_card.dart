import 'package:flutter/material.dart';

import '../models/progress_record.dart';
import '../services/api_service.dart';
import 'info_card.dart';

/// Shows a basic summary of the user's saved progress.
/// Muestra un resumen básico del progreso guardado del usuario.
class ProgressSummaryCard extends StatelessWidget {
  const ProgressSummaryCard({
    super.key,
  });

  static final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProgressRecord>>(
      future: _apiService.getProgress('demo-user'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InfoCard(
            title: 'Progreso',
            child: Text('Cargando progreso...'),
          );
        }

        final progressRecords = snapshot.data ?? [];
        final totalAnswered = progressRecords.length;
        final correctAnswers =
            progressRecords.where((record) => record.correct).length;

        return InfoCard(
          title: 'Progreso',
          child: Text(
            'Ejercicios respondidos: $totalAnswered\n'
            'Respuestas correctas: $correctAnswers',
          ),
        );
      },
    );
  }
}