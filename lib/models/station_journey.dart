enum StationJourneyPhase {
  listen,
  initialResponse,
  orientation,
  retry,
  complete,
}

/// Non-sensitive, local state for the internal station demonstration.
/// Audio files are deliberately not persisted in this record.
class StationJourney {
  const StationJourney({
    required this.situationId,
    required this.phase,
    required this.hasInitialRecording,
    required this.hasRetryRecording,
  });

  final String situationId;
  final StationJourneyPhase phase;
  final bool hasInitialRecording;
  final bool hasRetryRecording;

  Map<String, Object> toJson() => {
    'situationId': situationId,
    'phase': phase.name,
    'hasInitialRecording': hasInitialRecording,
    'hasRetryRecording': hasRetryRecording,
  };

  static StationJourney? fromJson(Map<String, dynamic> json) {
    final situationId = json['situationId'];
    final phaseName = json['phase'];
    final hasInitialRecording = json['hasInitialRecording'];
    final hasRetryRecording = json['hasRetryRecording'];
    if (situationId is! String ||
        situationId.isEmpty ||
        situationId.length > 80 ||
        phaseName is! String ||
        hasInitialRecording is! bool ||
        hasRetryRecording is! bool) {
      return null;
    }
    final phase = StationJourneyPhase.values
        .where((candidate) => candidate.name == phaseName)
        .firstOrNull;
    if (phase == null) return null;
    return StationJourney(
      situationId: situationId,
      phase: phase,
      hasInitialRecording: hasInitialRecording,
      hasRetryRecording: hasRetryRecording,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StationJourney &&
      situationId == other.situationId &&
      phase == other.phase &&
      hasInitialRecording == other.hasInitialRecording &&
      hasRetryRecording == other.hasRetryRecording;

  @override
  int get hashCode =>
      Object.hash(situationId, phase, hasInitialRecording, hasRetryRecording);
}
