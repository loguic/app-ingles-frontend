import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service responsible for communicating with the backend API.
/// Servicio responsable de comunicarse con la API del backend.
class ApiService {
  /// Base URL of the FastAPI backend exposed from WSL2 through Windows.
  /// URL base del backend FastAPI expuesto desde WSL2 a través de Windows.
  static const String baseUrl = 'http://192.168.1.33:8000/api/v1';

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
}
