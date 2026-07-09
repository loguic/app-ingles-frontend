import 'dart:convert';
import '../models/level.dart';
import '../models/unit.dart';
import '../models/lesson.dart';
import '../models/progress_record.dart';
import 'package:http/http.dart' as http;

/// Service responsible for communicating with the backend API.
/// Servicio responsable de comunicarse con la API del backend.
class ApiService {
  /// Base URL of the FastAPI backend running locally in Ubuntu VMware.
  /// URL base del backend FastAPI ejecutándose localmente en Ubuntu VMware.
  static const String baseUrl = 'http://127.0.0.1:8001/api/v1';

  /// Checks if the backend health endpoint is available.
  /// Verifica si el endpoint de salud del backend está disponible.
  Future<bool> checkHealth() async {
    final uri = Uri.parse('$baseUrl/health');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data['status'] == 'ok';
  }

  /// Gets the available English levels from the backend.
  /// Obtiene los niveles de inglés disponibles desde el backend.
  Future<List<Level>> getLevels() async {
    final uri = Uri.parse('$baseUrl/levels');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final levels = data['levels'] as List<dynamic>;

    return levels.cast<String>().map(Level.fromString).toList();
  }

  /// Gets the learning units for a specific English level.
  /// Obtiene las unidades de aprendizaje de un nivel específico.
  Future<List<Unit>> getUnits(String levelCode) async {
    final uri = Uri.parse('$baseUrl/content/levels/$levelCode/units');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data.cast<Map<String, dynamic>>().map(Unit.fromJson).toList();
  }

  /// Gets the lessons for a specific learning unit.
  /// Obtiene las lecciones de una unidad de aprendizaje específica.
  Future<List<Lesson>> getLessons(String unitId) async {
    final uri = Uri.parse('$baseUrl/content/units/$unitId/lessons');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data.cast<Map<String, dynamic>>().map(Lesson.fromJson).toList();
  }

  /// Gets the full detail of a specific lesson.
  /// Obtiene el detalle completo de una lección específica.
  Future<Lesson?> getLesson(String lessonId) async {
    final uri = Uri.parse('$baseUrl/content/lessons/$lessonId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return Lesson.fromJson(data);
  }

  /// Submits an exercise answer to the backend.
  /// Envía una respuesta de ejercicio al backend.
  Future<bool?> submitExerciseAnswer({
    required String exerciseId,
    required int selectedIndex,
  }) async {
    final uri = Uri.parse('$baseUrl/exercises/$exerciseId/submit');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'selected_index': selectedIndex}),
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return data['correct'] as bool;
  }

  /// Saves the user's exercise progress in the backend.
  /// Guarda el progreso del ejercicio del usuario en el backend.
  Future<bool> saveProgress({
    required String userId,
    required String levelId,
    required String unitId,
    required String lessonId,
    required String exerciseId,
    required int selectedIndex,
    required bool correct,
  }) async {
    final uri = Uri.parse('$baseUrl/progress');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'level_id': levelId,
        'unit_id': unitId,
        'lesson_id': lessonId,
        'exercise_id': exerciseId,
        'selected_index': selectedIndex,
        'correct': correct,
      }),
    );

    return response.statusCode == 200;
  }

    /// Gets the saved progress records for one user.
  /// Obtiene los registros de progreso guardados de un usuario.
  Future<List<ProgressRecord>> getProgress(String userId) async {
    final uri = Uri.parse('$baseUrl/progress/$userId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return [];
    }

    final data = jsonDecode(response.body) as List<dynamic>;

    return data
        .cast<Map<String, dynamic>>()
        .map(ProgressRecord.fromJson)
        .toList();
  }
}
