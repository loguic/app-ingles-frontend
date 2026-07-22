import "package:app_ingles/models/conversation_attempt_record.dart";
import "package:app_ingles/services/api_service.dart";
import "package:app_ingles/widgets/conversation_history_card.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

/// Simulates conversation history requests without using the backend.
/// Simula consultas del historial conversacional sin utilizar el backend.
class FakeConversationHistoryApiService extends ApiService {
  FakeConversationHistoryApiService({
    this.attempts = const [],
    this.throwOnLoad = false,
  });

  final List<ConversationAttemptRecord> attempts;
  final bool throwOnLoad;

  @override
  Future<List<ConversationAttemptRecord>> getConversationAttempts(
    String userId,
  ) async {
    if (throwOnLoad) {
      throw Exception("Simulated history failure");
    }

    return attempts;
  }
}

ConversationAttemptRecord testAttempt({
  required String id,
  required String mode,
  required DateTime completedAt,
}) {
  return ConversationAttemptRecord(
    userId: "demo-user",
    levelId: "A1",
    unitId: "a1-u1",
    lessonId: "a1-u1-l1",
    conversationId: id,
    mode: mode,
    visitedTurnIds: const ["turn-1", "turn-2"],
    selectedChoiceIds: mode == "branching" ? const ["choice-1"] : const [],
    completedAt: completedAt,
  );
}

Widget testApp(ApiService apiService) {
  return MaterialApp(
    home: Scaffold(body: ConversationHistoryCard(apiService: apiService)),
  );
}

void main() {
  testWidgets("shows the persisted conversation summary", (tester) async {
    final apiService = FakeConversationHistoryApiService(
      attempts: [
        testAttempt(
          id: "guided-1",
          mode: "guided",
          completedAt: DateTime(2026, 7, 20, 18, 30),
        ),
        testAttempt(
          id: "branching-1",
          mode: "branching",
          completedAt: DateTime(2026, 7, 21, 23, 53),
        ),
        testAttempt(
          id: "guided-2",
          mode: "guided",
          completedAt: DateTime(2026, 7, 19, 12),
        ),
      ],
    );

    await tester.pumpWidget(testApp(apiService));
    await tester.pumpAndSettle();

    expect(find.text("Práctica conversacional"), findsOneWidget);
    expect(find.text("Intentos completados: 3"), findsOneWidget);
    expect(find.text("Guiados: 2"), findsOneWidget);
    expect(find.text("Ramificados: 1"), findsOneWidget);
    expect(find.text("Última práctica: 21/07/2026 23:53"), findsOneWidget);
  });

  testWidgets("shows an empty conversation history", (tester) async {
    await tester.pumpWidget(testApp(FakeConversationHistoryApiService()));
    await tester.pumpAndSettle();

    expect(find.text("Aún no hay conversaciones completadas."), findsOneWidget);
  });

  testWidgets("shows a controlled message when loading fails", (tester) async {
    await tester.pumpWidget(
      testApp(FakeConversationHistoryApiService(throwOnLoad: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text("No se pudo cargar el historial conversacional."),
      findsOneWidget,
    );
  });
}
