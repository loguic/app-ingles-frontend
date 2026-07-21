import "../models/lesson.dart";

/// Controls navigation through a conversation graph.
/// Controla la navegación por el grafo de una conversación.
class ConversationFlowController {
  ConversationFlowController(this.conversation) {
    reset();
  }

  final Conversation conversation;

  final List<String> _visitedTurnIds = [];
  String? _currentTurnId;
  ConversationChoice? _selectedChoice;

  String? get currentTurnId => _currentTurnId;

  ConversationTurn? get currentTurn => conversation.turnById(_currentTurnId);

  ConversationChoice? get selectedChoice => _selectedChoice;

  List<String> get visitedTurnIds => List<String>.unmodifiable(_visitedTurnIds);

  bool get isCompleted => _currentTurnId == null;

  /// Selects one choice from the active learner turn.
  /// Selecciona una opción del turno activo del estudiante.
  bool selectChoice(String choiceId) {
    final turn = currentTurn;

    if (turn == null || turn.isLearner == false) {
      return false;
    }

    for (final choice in turn.choices) {
      if (choice.id == choiceId) {
        _selectedChoice = choice;
        return true;
      }
    }

    return false;
  }

  /// Advances to the resolved destination or completes the conversation.
  /// Avanza al destino resuelto o completa la conversación.
  bool advance() {
    final turn = currentTurn;

    if (turn == null) {
      return false;
    }

    if (turn.hasChoices && _selectedChoice == null) {
      return false;
    }

    final nextTurnId = _resolveNextTurnId(turn);

    if (nextTurnId == null) {
      _currentTurnId = null;
      _selectedChoice = null;
      return true;
    }

    final nextTurn = conversation.turnById(nextTurnId);

    if (nextTurn == null) {
      return false;
    }

    _currentTurnId = nextTurn.id;
    _selectedChoice = null;
    _visitedTurnIds.add(nextTurn.id);
    return true;
  }

  String? _resolveNextTurnId(ConversationTurn turn) {
    if (turn.hasChoices) {
      return _selectedChoice?.nextTurnId;
    }

    if (turn.nextTurnId != null) {
      return turn.nextTurnId;
    }

    if (conversation.mode == "branching") {
      return null;
    }

    final currentIndex = conversation.turns.indexWhere(
      (candidate) => candidate.id == turn.id,
    );
    final nextIndex = currentIndex + 1;

    if (currentIndex < 0 || nextIndex >= conversation.turns.length) {
      return null;
    }

    return conversation.turns[nextIndex].id;
  }

  /// Restores the declared initial turn and clears the selected route.
  /// Restaura el turno inicial declarado y limpia la ruta seleccionada.
  void reset() {
    final initialTurn = conversation.initialTurn;

    _currentTurnId = initialTurn?.id;
    _selectedChoice = null;
    _visitedTurnIds.clear();

    if (initialTurn != null) {
      _visitedTurnIds.add(initialTurn.id);
    }
  }
}
