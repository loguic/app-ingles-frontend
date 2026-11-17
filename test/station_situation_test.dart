import 'package:app_ingles/models/station_situation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'defines the toilet and exit situations through the same data contract',
    () {
      expect(stationSituations, hasLength(2));
      expect(stationSituations.map((item) => item.id), [
        'station-toilet',
        'station-exit',
      ]);
      expect(
        stationSituations.map((item) => item.referenceAudioAsset),
        [
          'mb1/audio/where-is-the-toilet.en-gb.wav',
          'mb1/audio/where-is-the-exit.en-gb.wav',
        ],
      );
      expect(
        stationSituations.every((item) => item.referenceAudioIsProvisional),
        isTrue,
      );
      expect(
        stationSituations.every((item) => item.retryOrientation.isNotEmpty),
        isTrue,
      );
    },
  );
}
