import 'dart:convert';
import '../models/level.dart';
import '../models/unit.dart';
import '../models/lesson.dart';
import 'package:http/http.dart' as http;

/// Service responsible for communicating with the backend API.
/// Servicio responsable de comunicarse con la API del backend.
class ApiService {
/// Base URL of the FastAPI backend running locally in Ubuntu VMware.
/// URL base del backend FastAPI ejecutándose localmente en Ubuntu VMware.
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1';

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

    return data
        .cast<Map<String, dynamic>>()
        .map(Unit.fromJson)
        .toList();
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

    return data
        .cast<Map<String, dynamic>>()
        .map(Lesson.fromJson)
        .toList();
  }




}