import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/station_journey.dart';

abstract interface class StationJourneyStore {
  Future<StationJourney?> load();

  Future<void> save(StationJourney journey);
}

/// Stores exactly one non-sensitive internal-demo checkpoint in app storage.
/// It intentionally accepts no user identifier and never stores audio paths.
class SharedPreferencesStationJourneyStore implements StationJourneyStore {
  SharedPreferencesStationJourneyStore({required SharedPreferences preferences})
    : _preferences = preferences;

  static const _key = 'internal-demo.station-journey.v1';
  final SharedPreferences _preferences;

  @override
  Future<StationJourney?> load() async {
    final encoded = _preferences.getString(_key);
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) return null;
      return StationJourney.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(StationJourney journey) async {
    await _preferences.setString(_key, jsonEncode(journey.toJson()));
  }
}
