import "package:flutter/material.dart";

import "../models/conversation_attempt_record.dart";
import "../services/api_service.dart";
import "info_card.dart";

/// Shows a summary of the persisted conversation attempts.
/// Muestra un resumen de los intentos conversacionales persistidos.
class ConversationHistoryCard extends StatelessWidget {
  const ConversationHistoryCard({
    this.userId = "demo-user",
    this.apiService,
    super.key,
  });

  final String userId;

  /// Optional service used to keep widget tests independent from the backend.
  /// Servicio opcional para mantener las pruebas separadas del backend.
  final ApiService? apiService;

  static final ApiService _defaultApiService = ApiService();

  ApiService get _apiService => apiService ?? _defaultApiService;

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, "0");
    final month = local.month.toString().padLeft(2, "0");
    final hour = local.hour.toString().padLeft(2, "0");
    final minute = local.minute.toString().padLeft(2, "0");

    return "$day/$month/${local.year} $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConversationAttemptRecord>>(
      future: _apiService.getConversationAttempts(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InfoCard(
            title: "Práctica conversacional",
            child: Text("Cargando historial conversacional..."),
          );
        }

        if (snapshot.hasError) {
          return const InfoCard(
            title: "Práctica conversacional",
            child: Text("No se pudo cargar el historial conversacional."),
          );
        }

        final attempts = List<ConversationAttemptRecord>.from(
          snapshot.data ?? const [],
        )..sort((a, b) => b.completedAt.compareTo(a.completedAt));

        if (attempts.isEmpty) {
          return const InfoCard(
            title: "Práctica conversacional",
            child: Text("Aún no hay conversaciones completadas."),
          );
        }

        final guidedCount = attempts
            .where((attempt) => attempt.mode == "guided")
            .length;
        final branchingCount = attempts
            .where((attempt) => attempt.mode == "branching")
            .length;
        final latestAttempt = attempts.first;

        return InfoCard(
          title: "Práctica conversacional",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Intentos completados: ${attempts.length}"),
              Text("Guiados: $guidedCount"),
              Text("Ramificados: $branchingCount"),
              const SizedBox(height: 8),
              Text(
                "Última práctica: ${_formatDate(latestAttempt.completedAt)}",
              ),
            ],
          ),
        );
      },
    );
  }
}
