import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/level.dart';
import '../models/unit.dart';
import '../services/api_service.dart';

/// Initial home screen shown when the app starts.
/// Pantalla inicial que se muestra al arrancar la aplicación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final ApiService _apiService = ApiService();

  String _selectedLevelCode = 'A1';
  String? _selectedUnitId;
  String? _selectedLessonId;

  void _selectLevel(String levelCode) {
    setState(() {
      _selectedLevelCode = levelCode;
      _selectedUnitId = null;
      _selectedLessonId = null;
    });
  }

  void _selectUnit(String unitId) {
    setState(() {
      _selectedUnitId = unitId;
      _selectedLessonId = null;
    });
  }

  void _selectLesson(String lessonId) {
    setState(() {
      _selectedLessonId = lessonId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Inglés'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Center(
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
                      children: levels.map((level) {
                        final isSelected = level.code == _selectedLevelCode;

                        return ChoiceChip(
                          label: Text(level.code),
                          selected: isSelected,
                          onSelected: (_) => _selectLevel(level.code),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Unidades de $_selectedLevelCode',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Unit>>(
                  future: _apiService.getUnits(_selectedLevelCode),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text('Cargando unidades $_selectedLevelCode...');
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text('No se pudieron cargar las unidades');
                    }

                    final units = snapshot.data!;

                    if (units.isEmpty) {
                      return Text('No hay unidades para $_selectedLevelCode');
                    }

                    return Column(
                      children: units
                          .map(
                            (unit) => Card(
                              child: ListTile(
                                title: Text(unit.title),
                                subtitle: Text(unit.id),
                                selected: unit.id == _selectedUnitId,
                                onTap: () => _selectUnit(unit.id),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedUnitId != null) ...[
                  Text(
                    'Lecciones de $_selectedUnitId',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Lesson>>(
                    future: _apiService.getLessons(_selectedUnitId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Cargando lecciones...');
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const Text(
                          'No se pudieron cargar las lecciones',
                        );
                      }

                      final lessons = snapshot.data!;

                      if (lessons.isEmpty) {
                        return const Text('No hay lecciones para esta unidad');
                      }

                      return Column(
                        children: lessons
                            .map(
                              (lesson) => Card(
                                child: ListTile(
                                  title: Text(lesson.title),
                                  subtitle: Text(lesson.objective ?? lesson.id),
                                  selected: lesson.id == _selectedLessonId,
                                  onTap: () => _selectLesson(lesson.id),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 24),
                if (_selectedLessonId != null)
                  FutureBuilder<Lesson?>(
                    future: _apiService.getLesson(_selectedLessonId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Cargando detalle de lección...');
                      }

                      if (snapshot.hasError || snapshot.data == null) {
                        return const Text('No se pudo cargar la lección');
                      }

                      final lesson = snapshot.data!;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (lesson.objective != null) ...[
                                const SizedBox(height: 12),
                                Text(lesson.objective!),
                              ],
                              const SizedBox(height: 16),
                              const Text(
                                'Vocabulario',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: lesson.vocabulary
                                    .map((word) => Chip(label: Text(word)))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Gramática',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...lesson.grammar.map((item) => Text('- $item')),
                              const SizedBox(height: 16),
                              const Text(
                                'Ejemplos',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...lesson.examples.map(
                                (example) => ListTile(
                                  title: Text(example.en),
                                  subtitle: Text(example.es),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Ejercicios',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ...lesson.exercises.map(
                                (exercise) => ListTile(
                                  title: Text(exercise.prompt),
                                  subtitle: Text(exercise.options.join(' / ')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}