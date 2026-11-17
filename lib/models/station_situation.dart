/// Pedagogical content for the internal station experience.
/// The screen consumes this data without situation-specific branches.
class StationSituation {
  const StationSituation({
    required this.id,
    required this.title,
    required this.scenario,
    required this.imageAsset,
    required this.referenceAudioAsset,
    required this.referenceAudioIsProvisional,
    required this.initialPrompt,
    required this.retryOrientation,
  });

  final String id;
  final String title;
  final String scenario;
  final String imageAsset;
  final String referenceAudioAsset;
  final bool referenceAudioIsProvisional;
  final String initialPrompt;
  final String retryOrientation;
}

const stationSituations = <StationSituation>[
  StationSituation(
    id: 'station-toilet',
    title: 'Find a place at the station',
    scenario: 'You are at a UK train station and need to find a place.',
    imageAsset: 'assets/mb1/visual/station-restroom-help.png',
    referenceAudioAsset: 'mb1/audio/where-is-the-toilet.en-gb.wav',
    referenceAudioIsProvisional: true,
    initialPrompt: 'Ask for the toilet in your own words.',
    retryOrientation:
        'Try again: begin with “Excuse me” and ask where the place is.',
  ),
  StationSituation(
    id: 'station-exit',
    title: 'Find the exit',
    scenario: 'You are in a nearby station passage and need to leave.',
    imageAsset: 'assets/mb1/visual/station-restroom-help.png',
    referenceAudioAsset: 'mb1/audio/where-is-the-exit.en-gb.wav',
    referenceAudioIsProvisional: true,
    initialPrompt: 'Ask for the exit in your own words.',
    retryOrientation: 'Try again: start politely, then ask where the exit is.',
  ),
];
