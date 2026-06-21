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
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildBackendStatus(),
                const SizedBox(height: 16),
                _buildLevelsSection(),
                const SizedBox(height: 16),
                _buildUnitsSection(),
                const SizedBox(height: 16),
                if (_selectedUnitId != null) _buildLessonsSection(),
                if (_selectedLessonId != null) ...[
                  const SizedBox(height: 16),
                  _buildLessonDetailSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Text(
          'Bienvenido a App Inglés',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Aprende inglés paso a paso por niveles, unidades y lecciones.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildBackendStatus() {
    return FutureBuilder<bool>(
      future: _apiService.checkHealth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoCard(
            title: 'Estado del backend',
            child: const Text('Verificando backend...'),
          );
        }

        final isBackendAvailable = snapshot.data ?? false;

        return _buildInfoCard(
          title: 'Estado del backend',
          child: Text(
            isBackendAvailable ? 'Backend conectado' : 'Backend no disponible',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isBackendAvailable ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelsSection() {
    return _buildInfoCard(
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
    );
  }

  Widget _buildUnitsSection() {
    return _buildInfoCard(
      title: 'Unidades de $_selectedLevelCode',
      child: FutureBuilder<List<Unit>>(
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
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book),
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
    );
  }

  Widget _buildLessonsSection() {
    return _buildInfoCard(
      title: 'Lecciones de $_selectedUnitId',
      child: FutureBuilder<List<Lesson>>(
        future: _apiService.getLessons(_selectedUnitId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Cargando lecciones...');
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Text('No se pudieron cargar las lecciones');
          }

          final lessons = snapshot.data!;

          if (lessons.isEmpty) {
            return const Text('No hay lecciones para esta unidad');
          }

          return Column(
            children: lessons
                .map(
                  (lesson) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.school),
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
    );
  }

  Widget _buildLessonDetailSection() {
    return FutureBuilder<Lesson?>(
      future: _apiService.getLesson(_selectedLessonId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildInfoCard(
            title: 'Detalle de lección',
            child: const Text('Cargando detalle de lección...'),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _buildInfoCard(
            title: 'Detalle de lección',
            child: const Text('No se pudo cargar la lección'),
          );
        }

        final lesson = snapshot.data!;

        return _buildInfoCard(
          title: lesson.title,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lesson.objective != null)
                _buildLessonSection(
                  title: 'Objetivo',
                  child: Text(lesson.objective!),
                ),
              _buildLessonSection(
                title: 'Vocabulario',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: lesson.vocabulary
                      .map((word) => Chip(label: Text(word)))
                      .toList(),
                ),
              ),
              _buildLessonSection(
                title: 'Gramática',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: lesson.grammar
                      .map((item) => Text('• $item'))
                      .toList(),
                ),
              ),
              _buildLessonSection(
                title: 'Ejemplos',
                child: Column(
                  children: lesson.examples
                      .map(
                        (example) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(example.en),
                          subtitle: Text(example.es),
                        ),
                      )
                      .toList(),
                ),
              ),
              _buildLessonSection(
                title: 'Ejercicios',
                child: Column(
                  children: lesson.exercises
                      .map(
                        (exercise) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.quiz),
                          title: Text(exercise.prompt),
                          subtitle: Text(exercise.options.join(' / ')),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLessonSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
