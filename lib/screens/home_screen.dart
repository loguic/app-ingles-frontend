import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/conversation_history_card.dart';
import '../widgets/info_card.dart';
import '../widgets/lesson_list_card.dart';
import '../widgets/level_selector_card.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/unit_list_card.dart';
import 'lesson_detail_screen.dart';

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
  int _progressRefreshCounter = 0;

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

  Future<void> _selectLesson(String lessonId) async {
    setState(() {
      _selectedLessonId = lessonId;
    });

    final selectedUnitId = _selectedUnitId;

    if (selectedUnitId == null) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonDetailScreen(
          lessonId: lessonId,
          levelId: _selectedLevelCode,
          unitId: selectedUnitId,
        ),
      ),
    );

    setState(() {
      _progressRefreshCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LOGUIC English'),
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
                ProgressSummaryCard(key: ValueKey(_progressRefreshCounter)),
                const SizedBox(height: 16),
                ConversationHistoryCard(
                  key: ValueKey(
                    "conversation-history-$_progressRefreshCounter",
                  ),
                ),
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
                    key: ValueKey(
                      'lesson-list-${_selectedUnitId!}-$_progressRefreshCounter',
                    ),
                    selectedUnitId: _selectedUnitId!,
                    selectedLessonId: _selectedLessonId,
                    onLessonSelected: _selectLesson,
                  ),
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
          'Bienvenido a LOGUIC English',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Escucha. Habla. Lee. Avanza.',
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
}
