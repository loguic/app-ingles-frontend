import 'package:app_ingles/models/station_journey.dart';
import 'package:app_ingles/services/station_journey_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'restores the bounded internal journey for its fixed demo identity',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesStationJourneyStore(
        preferences: await SharedPreferences.getInstance(),
      );
      const journey = StationJourney(
        situationId: 'station-toilet',
        phase: StationJourneyPhase.retry,
        hasInitialRecording: true,
        hasRetryRecording: false,
      );

      await store.save(journey);

      expect(await store.load(), journey);
    },
  );

  test(
    'keeps only one internal journey when the demonstration is restarted',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesStationJourneyStore(
        preferences: await SharedPreferences.getInstance(),
      );

      await store.save(
        const StationJourney(
          situationId: 'station-toilet',
          phase: StationJourneyPhase.initialResponse,
          hasInitialRecording: false,
          hasRetryRecording: false,
        ),
      );
      await store.save(
        const StationJourney(
          situationId: 'station-exit',
          phase: StationJourneyPhase.complete,
          hasInitialRecording: true,
          hasRetryRecording: true,
        ),
      );

      expect((await store.load())?.situationId, 'station-exit');
    },
  );
}
