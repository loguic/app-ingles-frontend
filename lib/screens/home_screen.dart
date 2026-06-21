import 'package:flutter/material.dart';

import '../models/lesson.dart';
import '../services/api_service.dart';
import '../widgets/info_card.dart';
import '../widgets/lesson_detail_card.dart';
import '../widgets/lesson_list_card.dart';
import '../widgets/level_selector_card.dart';
import '../widgets/unit_list_card.dart';

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
                LevelSelectorCard(
                  selectedLevelCode: _selectedLevelCode,
                  onLevelSelected: _selectLevel,
                ),
                const SizedBox(height: 16),
                UnitListCard(
                  selectedLevelCode: _selectedLevelCode,
                  selectedUnitId: _selectedUnitId,
                  onUnitSelected: _selectUnit,
                ),
                if (_selectedUnitId != null) ...[
                  const SizedBox(height: 16),
                  LessonListCard(
                    selectedUnitId: _selectedUnitId!,
                    selectedLessonId: _selectedLessonId,
                    onLessonSelected: _selectLesson,
                  ),
                ],
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