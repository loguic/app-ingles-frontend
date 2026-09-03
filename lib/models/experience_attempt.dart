/// One required evidence item in the backend-authoritative effective state.
class ExperienceEvidenceStateRecord {
  const ExperienceEvidenceStateRecord({
    required this.evidenceDefinitionId,
    required this.evidenceType,
    required this.status,
  });

  static const allowedStatuses = <String>{
    'pending',
    'needs_review',
    'satisfied',
  };

  final String evidenceDefinitionId;
  final String evidenceType;
  final String status;

  factory ExperienceEvidenceStateRecord.fromJson(Map<String, dynamic> json) {
    final status = _requiredAllowedString(json, 'status', allowedStatuses);

    return ExperienceEvidenceStateRecord(
      evidenceDefinitionId: _requiredString(json, 'evidence_definition_id'),
      evidenceType: _requiredString(json, 'evidence_type'),
      status: status,
    );
  }
}

/// The authoritative lifecycle record returned for one lesson experience.
class ExperienceAttemptRecord {
  const ExperienceAttemptRecord({
    required this.attemptId,
    required this.userId,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.experienceContractVersion,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.evidenceStates,
    this.submittedComprehensionExerciseIds = const <String>{},
  });

  static const allowedStatuses = <String>{'in_progress', 'completed'};

  final String attemptId;
  final String userId;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String experienceContractVersion;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ExperienceEvidenceStateRecord> evidenceStates;
  final Set<String> submittedComprehensionExerciseIds;

  bool get isCompleted => status == 'completed';

  factory ExperienceAttemptRecord.fromJson(Map<String, dynamic> json) {
    final completedAt = json['completed_at'];
    final rawEvidenceStates = json['evidence_states'];
    final rawSubmittedExerciseIds =
        json['submitted_comprehension_exercise_ids'];
    if (rawEvidenceStates is! List<dynamic>) {
      throw const FormatException('evidence_states must be a list');
    }
    if (rawSubmittedExerciseIds != null && rawSubmittedExerciseIds is! List) {
      throw const FormatException(
        'submitted_comprehension_exercise_ids must be a list',
      );
    }

    return ExperienceAttemptRecord(
      attemptId: _requiredString(json, 'attempt_id'),
      userId: _requiredString(json, 'user_id'),
      levelId: _requiredString(json, 'level_id'),
      unitId: _requiredString(json, 'unit_id'),
      lessonId: _requiredString(json, 'lesson_id'),
      experienceContractVersion: _requiredString(
        json,
        'experience_contract_version',
      ),
      status: _requiredAllowedString(json, 'status', allowedStatuses),
      startedAt: _requiredDateTime(json, 'started_at'),
      completedAt: completedAt == null
          ? null
          : _parseDateTime(completedAt, 'completed_at'),
      evidenceStates: rawEvidenceStates
          .map(
            (item) => ExperienceEvidenceStateRecord.fromJson(
              _requiredMap(item, 'evidence_states item'),
            ),
          )
          .toList(),
      submittedComprehensionExerciseIds: rawSubmittedExerciseIds == null
          ? const <String>{}
          : rawSubmittedExerciseIds.cast<String>().toSet(),
    );
  }
}

/// Source-level facts returned after a comprehension submission.
class ExperienceComprehensionResponseRecord {
  const ExperienceComprehensionResponseRecord({
    required this.responseId,
    required this.experienceAttemptId,
    required this.evidenceDefinitionId,
    required this.activityId,
    required this.comprehensionExerciseId,
    required this.selectedIndex,
    required this.isCorrect,
    required this.submittedAt,
  });

  final String responseId;
  final String experienceAttemptId;
  final String evidenceDefinitionId;
  final String activityId;
  final String comprehensionExerciseId;
  final int selectedIndex;
  final bool isCorrect;
  final DateTime submittedAt;

  factory ExperienceComprehensionResponseRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    final selectedIndex = json['selected_index'];
    final isCorrect = json['is_correct'];
    if (selectedIndex is! int) {
      throw const FormatException('selected_index must be an integer');
    }
    if (isCorrect is! bool) {
      throw const FormatException('is_correct must be a boolean');
    }

    return ExperienceComprehensionResponseRecord(
      responseId: _requiredString(json, 'response_id'),
      experienceAttemptId: _requiredString(json, 'experience_attempt_id'),
      evidenceDefinitionId: _requiredString(json, 'evidence_definition_id'),
      activityId: _requiredString(json, 'activity_id'),
      comprehensionExerciseId: _requiredString(
        json,
        'comprehension_exercise_id',
      ),
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
      submittedAt: _requiredDateTime(json, 'submitted_at'),
    );
  }
}

/// Source-level lifecycle returned by the public Direct English adapter.
class DirectEnglishPublicSourceRecord {
  const DirectEnglishPublicSourceRecord({
    required this.directEnglishAttemptId,
    required this.experienceAttemptId,
    required this.status,
    required this.transferVariantId,
    required this.transferPrompt,
  });

  static const allowedStatuses = <String>{'started', 'finalized'};

  final String directEnglishAttemptId;
  final String experienceAttemptId;
  final String status;
  final String transferVariantId;
  final String transferPrompt;

  factory DirectEnglishPublicSourceRecord.fromJson(Map<String, dynamic> json) {
    return DirectEnglishPublicSourceRecord(
      directEnglishAttemptId: _requiredString(
        json,
        'direct_english_attempt_id',
      ),
      experienceAttemptId: _requiredString(json, 'experience_attempt_id'),
      status: _requiredAllowedString(json, 'status', allowedStatuses),
      transferVariantId: _requiredString(json, 'transfer_variant_id'),
      transferPrompt: _requiredString(json, 'transfer_prompt'),
    );
  }
}

/// One learner-authored capture accepted by the public Direct English route.
class DirectEnglishCapture {
  const DirectEnglishCapture._({
    required this.productionFunction,
    required this.modality,
    this.responseText,
    this.audioReference,
  });

  factory DirectEnglishCapture.text({
    required String productionFunction,
    required String responseText,
  }) {
    return DirectEnglishCapture._(
      productionFunction: productionFunction,
      modality: 'text',
      responseText: responseText,
    );
  }

  factory DirectEnglishCapture.voice({
    required String productionFunction,
    required String audioReference,
  }) {
    return DirectEnglishCapture._(
      productionFunction: productionFunction,
      modality: 'voice',
      audioReference: audioReference,
    );
  }

  final String productionFunction;
  final String modality;
  final String? responseText;
  final String? audioReference;

  Map<String, dynamic> toJson() {
    return {
      'production_function': productionFunction,
      'modality': modality,
      if (responseText != null) 'response_text': responseText,
      if (audioReference != null) 'audio_reference': audioReference,
    };
  }
}

Map<String, dynamic> _requiredMap(dynamic value, String fieldName) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$fieldName must be an object');
  }
  return value;
}

String _requiredString(Map<String, dynamic> json, String fieldName) {
  final value = json[fieldName];
  if (value is! String || value.isEmpty) {
    throw FormatException('$fieldName must be a non-empty string');
  }
  return value;
}

String _requiredAllowedString(
  Map<String, dynamic> json,
  String fieldName,
  Set<String> allowedValues,
) {
  final value = _requiredString(json, fieldName);
  if (!allowedValues.contains(value)) {
    throw FormatException('$fieldName contains unsupported value: $value');
  }
  return value;
}

DateTime _requiredDateTime(Map<String, dynamic> json, String fieldName) {
  return _parseDateTime(json[fieldName], fieldName);
}

DateTime _parseDateTime(dynamic value, String fieldName) {
  if (value is! String) {
    throw FormatException('$fieldName must be an ISO-8601 string');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$fieldName must be an ISO-8601 string');
  }
  return parsed;
}
