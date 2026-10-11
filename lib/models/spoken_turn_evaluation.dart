/// Non-authoritative coaching returned by the spoken-turn runtime.
///
/// This deliberately contains no mastery or completion state.
class SpokenTurnEvaluation {
  const SpokenTurnEvaluation({
    required this.semanticStatus,
    required this.contextRelevant,
    required this.rationale,
    required this.conversationalFeedback,
    required this.nextAction,
    required this.nextSupportLevel,
    required this.nextReason,
    required this.comparisonAvailable,
    required this.improvementTrend,
    required this.improvementEvidence,
    required this.provider,
    required this.model,
  });

  final String semanticStatus;
  final bool contextRelevant;
  final String rationale;
  final String conversationalFeedback;
  final String nextAction;
  final String nextSupportLevel;
  final String nextReason;
  final bool comparisonAvailable;
  final String improvementTrend;
  final String improvementEvidence;
  final String provider;
  final String model;

  factory SpokenTurnEvaluation.fromJson(Map<String, dynamic> json) {
    final semantic = json['semantic_evaluation'] as Map<String, dynamic>;
    final next = json['next_turn'] as Map<String, dynamic>;
    final improvement = json['cross_turn_improvement'] as Map<String, dynamic>;
    final provenance = json['provenance'] as Map<String, dynamic>;
    return SpokenTurnEvaluation(
      semanticStatus: semantic['status'] as String,
      contextRelevant: semantic['context_relevant'] as bool,
      rationale: semantic['rationale'] as String,
      conversationalFeedback: json['conversational_feedback'] as String,
      nextAction: next['action'] as String,
      nextSupportLevel: next['support_level'] as String,
      nextReason: next['reason'] as String,
      comparisonAvailable: improvement['comparison_available'] as bool,
      improvementTrend: improvement['trend'] as String,
      improvementEvidence: improvement['evidence'] as String,
      provider: provenance['provider'] as String,
      model: provenance['model'] as String,
    );
  }
}

class SpokenTurnEvaluationException implements Exception {
  const SpokenTurnEvaluationException(this.message);

  final String message;

  @override
  String toString() => message;
}
