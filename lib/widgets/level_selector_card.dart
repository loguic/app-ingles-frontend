import 'package:flutter/material.dart';

import '../models/level.dart';
import '../services/api_service.dart';
import 'info_card.dart';

/// Shows the available English levels.
/// Muestra los niveles de inglés disponibles.
class LevelSelectorCard extends StatelessWidget {
  const LevelSelectorCard({
    required this.selectedLevelCode,
    required this.onLevelSelected,
    super.key,
  });

  static final ApiService _apiService = ApiService();

  final String selectedLevelCode;
  final ValueChanged<String> onLevelSelected;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Nivel',
      child: FutureBuilder<List<Level>>(
        future: _apiService.getLevels(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando niveles...');
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('No se pudieron cargar los niveles');
          }

          final levels = snapshot.data!;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: levels.map((level) {
              final isSelected = level.code == selectedLevelCode;

              return ChoiceChip(
                label: Text(level.code),
                selected: isSelected,
                onSelected: (_) => onLevelSelected(level.code),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}