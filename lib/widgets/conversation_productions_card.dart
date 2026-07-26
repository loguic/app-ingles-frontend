import "package:flutter/material.dart";

import "../models/conversation_production_record.dart";
import "../services/api_service.dart";
import "info_card.dart";

/// Shows persisted personal productions without evaluating them.
/// Muestra producciones personales persistidas sin evaluarlas.
class ConversationProductionsCard extends StatelessWidget {
  const ConversationProductionsCard({
    this.userId = "demo-user",
    this.apiService,
    super.key,
  });

  final String userId;
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
    return FutureBuilder<List<ConversationProductionSubmissionRecord>>(
      future: _apiService.getConversationProductions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InfoCard(
            title: "Producciones personales",
            child: Text("Cargando producciones personales..."),
          );
        }

        if (snapshot.hasError) {
          return const InfoCard(
            title: "Producciones personales",
            child: Text(
              "No se pudieron cargar las producciones personales.",
            ),
          );
        }

        final records = List<ConversationProductionSubmissionRecord>.from(
          snapshot.data ?? const [],
        )..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

        if (records.isEmpty) {
          return const InfoCard(
            title: "Producciones personales",
            child: Text("Aún no hay producciones personales guardadas."),
          );
        }

        final productionCount = records.fold<int>(
          0,
          (total, record) => total + record.productions.length,
        );
        final latest = records.first;

        final productionWidgets = latest.productions.map((production) {
          if (production.modality == "text") {
            return Text(production.responseText ?? "");
          }

          if (production.modality == "voice") {
            return const Text("Producción de voz registrada.");
          }

          return Text("Producción registrada: ${production.modality}");
        }).toList();

        return InfoCard(
          title: "Producciones personales",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Entregas guardadas: ${records.length}"),
              Text("Producciones: $productionCount"),
              const SizedBox(height: 8),
              ...productionWidgets,
              const SizedBox(height: 8),
              Text("Última entrega: ${_formatDate(latest.submittedAt)}"),
            ],
          ),
        );
      },
    );
  }
}
