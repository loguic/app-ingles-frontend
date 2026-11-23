import "dart:convert";

class A1V4PracticeSessionCredentials {
  const A1V4PracticeSessionCredentials({
    required this.sessionId,
    required this.token,
  });

  final String sessionId;
  final String token;

  factory A1V4PracticeSessionCredentials.fromJson(Map<String, dynamic> json) {
    final sessionId = json['session_id'];
    final token = json['token'];
    if (sessionId is! String ||
        sessionId.isEmpty ||
        token is! String ||
        token.length < 32 ||
        json['practice_session'] != true ||
        json['curricular_accreditation'] != false) {
      throw const FormatException('Invalid A1 v4 practice session response.');
    }
    return A1V4PracticeSessionCredentials(sessionId: sessionId, token: token);
  }
}

class A1V4PracticeSaveConfirmation {
  const A1V4PracticeSaveConfirmation({
    required this.sessionId,
    required this.saved,
    required this.productionCount,
  });

  static const activityIds = {
    'own-production',
    'lower-support-own-production',
    'nearby-transfer-food',
  };

  final String sessionId;
  final bool saved;
  final int productionCount;

  factory A1V4PracticeSaveConfirmation.fromJson(
    Map<String, dynamic> json, {
    required String expectedSessionId,
    required List<Map<String, dynamic>> expectedProductions,
  }) {
    final productions = json['productions'];
    if (json['session_id'] != expectedSessionId ||
        json['declared_user_id'] is! String ||
        (json['declared_user_id'] as String).isEmpty ||
        json['saved'] != true ||
        json['practice_completed'] is! bool ||
        json['practice_session'] != true ||
        json['curricular_accreditation'] != false ||
        !_isDateTime(json['created_at']) ||
        !_isDateTime(json['saved_at']) ||
        productions is! List ||
        productions.length != activityIds.length) {
      throw const FormatException('Invalid A1 v4 save confirmation.');
    }
    final validProductions = productions.whereType<Map<String, dynamic>>();
    if (validProductions.length != activityIds.length ||
        validProductions.any((item) {
          final evidence = item['backend_verified_evidence'];
          return item['activity_id'] is! String ||
              item['audio_reference'] is! String ||
              (item['audio_reference'] as String).isEmpty ||
              item['transcript'] is! String ||
              (item['transcript'] as String).isEmpty ||
              evidence is! Map<String, dynamic> ||
              evidence['audio_linked_to_session'] != true;
        })) {
      throw const FormatException('Invalid A1 v4 saved productions.');
    }
    final ids = validProductions
        .map((item) => item['activity_id'] as String)
        .toSet();
    if (ids.length != activityIds.length || !ids.containsAll(activityIds)) {
      throw const FormatException('Invalid A1 v4 saved productions.');
    }
    final submittedById = <String, Map<String, dynamic>>{};

    for (final item in expectedProductions) {
      final id = item["activity_id"];

      if (id is! String ||
          !activityIds.contains(id) ||
          submittedById.containsKey(id)) {
        throw const FormatException("Invalid submitted productions.");
      }

      submittedById[id] = item;
    }

    if (submittedById.length != activityIds.length ||
        validProductions.any((item) {
          final submitted = submittedById[item["activity_id"]];

          return submitted == null ||
              item["audio_reference"] != submitted["audio_reference"] ||
              item["transcript"] != submitted["transcript"] ||
              jsonEncode(_canonicalJson(item["client_evaluation"])) !=
                  jsonEncode(_canonicalJson(submitted["client_evaluation"]));
        })) {
      throw const FormatException(
        "Saved productions differ from submitted productions.",
      );
    }

    return A1V4PracticeSaveConfirmation(
      sessionId: expectedSessionId,
      saved: true,
      productionCount: productions.length,
    );
  }

  static Object? _canonicalJson(Object? value) {
    if (value is Map) {
      if (value.keys.any((key) => key is! String)) {
        throw const FormatException("Invalid evaluation keys.");
      }

      final keys = value.keys.cast<String>().toList()..sort();

      return {for (final key in keys) key: _canonicalJson(value[key])};
    }

    if (value is List) {
      return value.map(_canonicalJson).toList();
    }

    return value;
  }

  static bool _isDateTime(Object? value) =>
      value is String && DateTime.tryParse(value) != null;
}

enum A1V4PracticeErrorKind {
  authorization,
  contract,
  conflict,
  serviceUnavailable,
  network,
  unexpectedResponse,
}

class A1V4PracticeSessionException implements Exception {
  const A1V4PracticeSessionException({
    required this.kind,
    required this.detail,
    this.statusCode,
  });

  final A1V4PracticeErrorKind kind;
  final int? statusCode;
  final String detail;
}
