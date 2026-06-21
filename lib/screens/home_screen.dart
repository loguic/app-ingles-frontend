import 'package:flutter/material.dart';

import '../models/level.dart';
import '../models/unit.dart';

import '../services/api_service.dart';

/// Initial home screen shown when the app starts.
/// Pantalla inicial que se muestra al arrancar la aplicación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Backend service used to check if the API is available.
  /// Servicio del backend usado para verificar si la API está disponible.
  static final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Inglés'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bienvenido a App Inglés',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              FutureBuilder<bool>(
                future: _apiService.checkHealth(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Verificando backend...');
                  }

                  if (snapshot.hasError) {
                    return const Text('Backend no disponible');
                  }

                  final isBackendAvailable = snapshot.data ?? false;

                  return Text(
                    isBackendAvailable
                        ? 'Backend conectado'
                        : 'Backend no disponible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isBackendAvailable ? Colors.green : Colors.red,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<Level>>(
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
                    alignment: WrapAlignment.center,
                    children: levels
                        .map(
                          (level) => Chip(
                            label: Text(level.code),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
                            const SizedBox(height: 24),
              FutureBuilder<List<Unit>>(
                future: _apiService.getUnits('A1'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Cargando unidades A1...');
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text('No se pudieron cargar las unidades');
                  }

                  final units = snapshot.data!;

                  return Column(
                    children: units
                        .map(
                          (unit) => Card(
                            child: ListTile(
                              title: Text(unit.title),
                              subtitle: Text(unit.id),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}