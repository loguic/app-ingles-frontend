import 'package:flutter/material.dart';

import 'services/api_service.dart';

void main() {
  runApp(const AppIngles());
}

/// Root widget of the English learning application.
/// Widget raíz de la aplicación de aprendizaje de inglés.
class AppIngles extends StatelessWidget {
  const AppIngles({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Inglés',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const HomeScreen(),
    );
  }
}

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
            ],
          ),
        ),
      ),
    );
  }
}