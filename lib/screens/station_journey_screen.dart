import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station_journey.dart';
import '../models/station_situation.dart';
import '../services/pronunciation_audio_service.dart';
import '../services/station_journey_store.dart';

class StationJourneyScreen extends StatefulWidget {
  const StationJourneyScreen({
    this.audioController,
    this.journeyStore,
    this.isDarkTheme = true,
    this.onThemeChanged,
    super.key,
  });

  final PronunciationAudioController? audioController;
  final StationJourneyStore? journeyStore;
  final bool isDarkTheme;
  final ValueChanged<ThemeMode>? onThemeChanged;

  @override
  State<StationJourneyScreen> createState() => _StationJourneyScreenState();
}

class _StationJourneyScreenState extends State<StationJourneyScreen> {
  late final PronunciationAudioController _audio;
  late final bool _ownsAudio;
  StationJourneyStore? _store;
  StationJourneyPhase _phase = StationJourneyPhase.listen;
  int _situationIndex = 0;
  String? _initialRecording;
  String? _retryRecording;
  bool _loading = true;
  bool _referenceRequested = false;

  StationSituation get _situation => stationSituations[_situationIndex];

  @override
  void initState() {
    super.initState();
    _ownsAudio = widget.audioController == null;
    _audio = widget.audioController ?? PronunciationAudioService();
    _restore();
  }

  Future<void> _restore() async {
    final store =
        widget.journeyStore ??
        SharedPreferencesStationJourneyStore(
          preferences: await SharedPreferences.getInstance(),
        );
    final saved = await store.load();
    if (!mounted) return;
    setState(() {
      _store = store;
      if (saved != null) {
        final index = stationSituations.indexWhere(
          (item) => item.id == saved.situationId,
        );
        _situationIndex = index < 0 ? 0 : index;
        _phase = saved.phase;
        // Recordings are private temporary files and are never recovered as
        // durable state. A restored journey asks for a new recording.
        if (saved.hasInitialRecording &&
            _phase == StationJourneyPhase.initialResponse) {
          _phase = StationJourneyPhase.orientation;
        }
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    final store = _store;
    if (store == null) return;
    await store.save(
      StationJourney(
        situationId: _situation.id,
        phase: _phase,
        hasInitialRecording: _initialRecording != null,
        hasRetryRecording: _retryRecording != null,
      ),
    );
  }

  Future<void> _playReference() async {
    await _audio.playReference(
      _situation.referenceAudioAsset,
      playbackId: 'station-reference-${_situation.id}',
    );
    if (mounted) setState(() => _referenceRequested = true);
  }

  Future<void> _record({required bool retry}) async {
    final allowed = await _audio.hasMicrophonePermission();
    if (!allowed || !mounted) return;
    await _audio.startRecording(
      'station-${_situation.id}-${retry ? 'retry' : 'initial'}',
    );
    if (mounted) setState(() {});
  }

  Future<void> _stop({required bool retry}) async {
    final path = await _audio.stopRecording();
    if (!mounted || path == null) return;
    setState(() {
      if (retry) {
        _retryRecording = path;
        _phase = StationJourneyPhase.complete;
      } else {
        _initialRecording = path;
        _phase = StationJourneyPhase.orientation;
      }
    });
    await _save();
  }

  Future<void> _startRetry() async {
    setState(() => _phase = StationJourneyPhase.retry);
    await _save();
  }

  Future<void> _nextSituation() async {
    setState(() {
      _situationIndex = (_situationIndex + 1) % stationSituations.length;
      _phase = StationJourneyPhase.listen;
      _initialRecording = null;
      _retryRecording = null;
      _referenceRequested = false;
    });
    await _save();
  }

  @override
  void dispose() {
    if (_ownsAudio) unawaited(_audio.dispose());
    super.dispose();
  }

  Widget _responsiveAction(Widget action) => Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(width: 360, child: action),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final recording = _phase == StationJourneyPhase.retry
        ? _retryRecording
        : _initialRecording;
    final recordingActive = _audio.activeRecordingId != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Práctica oral en la estación'),
        actions: [
          TextButton(
            key: const Key('a1-theme-light'),
            onPressed: () => widget.onThemeChanged?.call(ThemeMode.light),
            child: const Text('Claro'),
          ),
          TextButton(
            key: const Key('a1-theme-dark'),
            onPressed: () => widget.onThemeChanged?.call(ThemeMode.dark),
            child: const Text('Oscuro'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Situación', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _situation.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(_situation.scenario),
              const SizedBox(height: 12),
              SizedBox(
                height: MediaQuery.sizeOf(context).width < 600 ? 130 : 160,
                child: Image.asset(
                  _situation.imageAsset,
                  fit: BoxFit.contain,
                  semanticLabel: 'Escena de una estación de tren',
                ),
              ),
              const SizedBox(height: 12),
              Text('Escuchar', style: Theme.of(context).textTheme.titleMedium),
              const Text(
                'Audio provisional para demostración interna',
                key: Key('station-provisional-audio-label'),
              ),
              _responsiveAction(
                FilledButton.icon(
                  key: const Key('station-play-reference'),
                  onPressed: _playReference,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Escuchar audio provisional'),
                ),
              ),
              const SizedBox(height: 12),
              if (_phase == StationJourneyPhase.orientation) ...[
                const Text(
                  'Orientación para el reintento',
                  key: Key('station-orientation'),
                ),
                Text(_situation.retryOrientation),
                if (_initialRecording != null)
                  OutlinedButton.icon(
                    key: const Key('station-play-initial-recording'),
                    onPressed: () => _audio.playRecording(
                      _initialRecording!,
                      playbackId: 'station-initial-recording-${_situation.id}',
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reproducir mi voz'),
                  ),
                FilledButton(
                  key: const Key('station-start-retry'),
                  onPressed: _startRetry,
                  child: const Text('Hacer un segundo intento'),
                ),
              ] else if (_phase == StationJourneyPhase.complete) ...[
                const Text(
                  'Recorrido guardado en este dispositivo.',
                  key: Key('station-saved'),
                ),
                if (_retryRecording != null)
                  OutlinedButton.icon(
                    key: const Key('station-play-retry-recording'),
                    onPressed: () => _audio.playRecording(
                      _retryRecording!,
                      playbackId: 'station-retry-recording-${_situation.id}',
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Reproducir mi voz'),
                  ),
                OutlinedButton(
                  key: const Key('station-next-situation'),
                  onPressed: _nextSituation,
                  child: const Text('Probar la segunda situación'),
                ),
              ] else ...[
                Text(
                  'Comprender',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Escucha la situación e identifica qué lugar necesita encontrar la persona.',
                  key: Key('station-comprehension-instruction'),
                ),
                const SizedBox(height: 12),
                Text('Hablar', style: Theme.of(context).textTheme.titleMedium),
                if (_referenceRequested || _phase == StationJourneyPhase.retry)
                  Text(
                    _situation.initialPrompt,
                    key: const Key('station-prompt'),
                  )
                else
                  const Text(
                    'Primero escucha el audio; después practica cómo pedir ayuda.',
                    key: Key('station-prompt-hidden'),
                  ),
                if (recording == null)
                  _responsiveAction(
                    FilledButton.icon(
                      style: recordingActive
                          ? FilledButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onError,
                            )
                          : null,
                      key: const Key('station-record'),
                      onPressed: recordingActive
                          ? () => _stop(
                              retry: _phase == StationJourneyPhase.retry,
                            )
                          : () => _record(
                              retry: _phase == StationJourneyPhase.retry,
                            ),
                      icon: Icon(recordingActive ? Icons.stop : Icons.mic),
                      label: Text(
                        recordingActive ? 'Detener grabación' : 'Grabar mi voz',
                      ),
                    ),
                  )
                else
                  _responsiveAction(
                    OutlinedButton.icon(
                      key: const Key('station-play-recording'),
                      onPressed: () => _audio.playRecording(
                        recording,
                        playbackId: 'station-recording-${_situation.id}',
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Reproducir mi voz'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
