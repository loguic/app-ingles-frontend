import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../models/level.dart';
import '../models/unit.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/lesson_detail_card.dart';

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
          return const InfoCard(
            title: 'Estado del backend',
            child: Text('Verificando backend...'),
          );
        }

        final isBackendAvailable = snapshot.data ?? false;

        return InfoCard(
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
    return InfoCard(
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
    return InfoCard(
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
          return const InfoCard(
            title: 'Detalle de lección',
            child: Text('Cargando detalle de lección...'),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const InfoCard(
            title: 'Detalle de lección',
            child: Text('No se pudo cargar la lección'),
          );
        }

        return LessonDetailCard(lesson: snapshot.data!);
      },
    );
  }
}