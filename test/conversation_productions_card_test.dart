import "package:app_ingles/models/conversation_production_record.dart";
import "package:app_ingles/services/api_service.dart";
import "package:app_ingles/widgets/conversation_productions_card.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

class FakeConversationProductionsApiService extends ApiService {
  FakeConversationProductionsApiService({
    this.records = const [],
    this.throwOnLoad = false,
  });

  final List<ConversationProductionSubmissionRecord> records;
  final bool throwOnLoad;

  @override
  Future<List<ConversationProductionSubmissionRecord>>
  getConversationProductions(String userId) async {
    if (throwOnLoad) {
      throw Exception("Simulated production history failure");
    }

    return records;
  }
}

ConversationProductionSubmissionRecord testRecord() {
  return ConversationProductionSubmissionRecord(
    userId: "demo-user",
    levelId: "A1",
    unitId: "a1-u1",
    lessonId: "a1-u1-l1",
    conversationId: "a1-u1-l1-c1",
    submissionId: 7,
    submittedAt: DateTime(2026, 7, 26, 10, 15),
    productions: const [
      LearnerProductionRecord(
        promptId: "prompt-text",
        turnId: "turn-text",
        modality: "text",
        responseText: "My name is John.",
        productionId: 11,
      ),
      LearnerProductionRecord(
        promptId: "prompt-voice",
        turnId: "turn-voice",
        modality: "voice",
        audioReference: "stored-audio-reference",
        productionId: 12,
      ),
    ],
  );
}

Widget testApp(ApiService apiService) {
  return MaterialApp(
    home: Scaffold(
      body: ConversationProductionsCard(apiService: apiService),
    ),
  );
}

void main() {
  testWidgets("shows persisted personal productions", (tester) async {
    await tester.pumpWidget(
      testApp(FakeConversationProductionsApiService(records: [testRecord()])),
    );
    await tester.pumpAndSettle();

    expect(find.text("Producciones personales"), findsOneWidget);
    expect(find.text("Entregas guardadas: 1"), findsOneWidget);
    expect(find.text("Producciones: 2"), findsOneWidget);
    expect(find.text("My name is John."), findsOneWidget);
    expect(find.text("Producción de voz registrada."), findsOneWidget);
    expect(find.text("Última entrega: 26/07/2026 10:15"), findsOneWidget);
    expect(find.text("stored-audio-reference"), findsNothing);
  });

  testWidgets("shows an empty production history", (tester) async {
    await tester.pumpWidget(
      testApp(FakeConversationProductionsApiService()),
    );
    await tester.pumpAndSettle();

    expect(find.text("Aún no hay producciones personales guardadas."), findsOneWidget);
  });

  testWidgets("shows a controlled message when loading fails", (tester) async {
    await tester.pumpWidget(
      testApp(FakeConversationProductionsApiService(throwOnLoad: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("No se pudieron cargar las producciones personales."),
      findsOneWidget,
    );
  });
}
