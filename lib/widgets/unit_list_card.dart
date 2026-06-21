import 'package:flutter/material.dart';

import '../models/unit.dart';
import '../services/api_service.dart';
import 'info_card.dart';

/// Shows the unit list for the selected level.
/// Muestra la lista de unidades del nivel seleccionado.
class UnitListCard extends StatelessWidget {
  const UnitListCard({
    required this.selectedLevelCode,
    required this.selectedUnitId,
    required this.onUnitSelected,
    super.key,
  });

  static final ApiService _apiService = ApiService();

  final String selectedLevelCode;
  final String? selectedUnitId;
  final ValueChanged<String> onUnitSelected;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Unidades de $selectedLevelCode',
      child: FutureBuilder<List<Unit>>(
        future: _apiService.getUnits(selectedLevelCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('Cargando unidades $selectedLevelCode...');
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('No se pudieron cargar las unidades');
          }

          final units = snapshot.data!;

          if (units.isEmpty) {
            return Text('No hay unidades para $selectedLevelCode');
          }

          return Column(
            children: units
                .map(
                  (unit) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
                      title: Text(unit.title),
                      subtitle: Text(unit.id),
                      selected: unit.id == selectedUnitId,
                      onTap: () => onUnitSelected(unit.id),
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