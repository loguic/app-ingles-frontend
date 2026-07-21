import "package:app_ingles/controllers/conversation_flow_controller.dart";
import "package:app_ingles/models/lesson.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("starts a guided conversation at its first turn", () {
    const conversation = Conversation(
      id: "guided-test",
      title: "Guided test",
      turns: [
        ConversationTurn(id: "partner-start", speaker: "partner", en: "Hello."),
        ConversationTurn(id: "learner-end", speaker: "learner", en: "Hello."),
      ],
    );

    final controller = ConversationFlowController(conversation);

    expect(controller.currentTurnId, "partner-start");
    expect(controller.currentTurn?.id, "partner-start");
    expect(controller.visitedTurnIds, ["partner-start"]);
    expect(controller.selectedChoiceIds, isEmpty);
    expect(controller.isCompleted, isFalse);
  });

  test("advances and resets a guided conversation", () {
    const conversation = Conversation(
      id: "guided-flow",
      title: "Guided flow",
      turns: [
        ConversationTurn(id: "turn-1", speaker: "partner", en: "Hello."),
        ConversationTurn(id: "turn-2", speaker: "learner", en: "Hello."),
      ],
    );

    final controller = ConversationFlowController(conversation);

    expect(controller.advance(), isTrue);
    expect(controller.currentTurnId, "turn-2");
    expect(controller.visitedTurnIds, ["turn-1", "turn-2"]);

    expect(controller.advance(), isTrue);
    expect(controller.isCompleted, isTrue);
    expect(controller.currentTurn, isNull);

    controller.reset();

    expect(controller.currentTurnId, "turn-1");
    expect(controller.visitedTurnIds, ["turn-1"]);
    expect(controller.isCompleted, isFalse);
  });

  test("requires a choice and follows the selected branch", () {
    const conversation = Conversation(
      id: "branching-flow",
      title: "Branching flow",
      mode: "branching",
      startTurnId: "partner-start",
      turns: [
        ConversationTurn(
          id: "partner-start",
          speaker: "partner",
          en: "How are you?",
          nextTurnId: "learner-choice",
        ),
        ConversationTurn(
          id: "learner-choice",
          speaker: "learner",
          en: "Choose an answer.",
          choices: [
            ConversationChoice(
              id: "choice-fine",
              en: "I am fine.",
              nextTurnId: "partner-fine",
            ),
            ConversationChoice(
              id: "choice-tired",
              en: "I am tired.",
              nextTurnId: "partner-tired",
            ),
          ],
        ),
        ConversationTurn(id: "partner-fine", speaker: "partner", en: "Great."),
        ConversationTurn(
          id: "partner-tired",
          speaker: "partner",
          en: "I hope you rest.",
        ),
      ],
    );

    final controller = ConversationFlowController(conversation);

    expect(controller.advance(), isTrue);
    expect(controller.currentTurnId, "learner-choice");

    expect(controller.advance(), isFalse);
    expect(controller.currentTurnId, "learner-choice");

    expect(controller.selectChoice("choice-tired"), isTrue);
    expect(controller.selectedChoice?.id, "choice-tired");

    expect(controller.advance(), isTrue);
    expect(controller.currentTurnId, "partner-tired");
    expect(controller.visitedTurnIds, [
      "partner-start",
      "learner-choice",
      "partner-tired",
    ]);
    expect(controller.visitedTurnIds, isNot(contains("partner-fine")));
    expect(controller.selectedChoiceIds, ["choice-tired"]);

    controller.reset();

    expect(controller.currentTurnId, "partner-start");
    expect(controller.selectedChoiceIds, isEmpty);
  });
}
