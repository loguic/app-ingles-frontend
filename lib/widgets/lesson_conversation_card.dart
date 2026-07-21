import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/conversation_flow_controller.dart';
import '../models/lesson.dart';
import '../services/api_service.dart';
import '../services/pronunciation_audio_service.dart';

/// Represents the local stage of one guided conversation.
/// Representa la etapa local de una conversación guiada.
enum _ConversationPracticeStep {
  listenPartner,
  understandPartner,
  prepareLearner,
  recordLearner,
  reviewLearner,
  completed,
}

/// Runs one conversation and persists each completed attempt.
/// Ejecuta una conversación y persiste cada intento completado.
class LessonConversationCard extends StatefulWidget {
  const LessonConversationCard({
    required this.conversation,
    required this.levelId,
    required this.unitId,
    required this.lessonId,
    required this.userId,
    required this.audioService,
    this.apiService,
    super.key,
  });

  final Conversation conversation;
  final String levelId;
  final String unitId;
  final String lessonId;
  final String userId;
  final PronunciationAudioController audioService;

  /// Optional API service used to keep widget tests independent from the backend.
  /// Servicio API opcional para mantener las pruebas separadas del backend.
  final ApiService? apiService;

  @override
  State<LessonConversationCard> createState() => _LessonConversationCardState();
}

class _LessonConversationCardState extends State<LessonConversationCard> {
  static final ApiService _defaultApiService = ApiService();

  ApiService get _apiService => widget.apiService ?? _defaultApiService;

  StreamSubscription<String?>? _playbackSubscription;
  StreamSubscription<String?>? _recordingSubscription;

  late final ConversationFlowController _flowController;
  int _currentTurnIndex = 0;
  String? _activePlaybackId;
  String? _activeRecordingId;
  String? _activeLocale;
  String? _recordingPath;
  String? _errorMessage;
  bool _isBusy = false;
  bool _hasReviewedRecording = false;
  bool _isSavingAttempt = false;
  bool _attemptSaved = false;
  String? _persistenceMessage;
  int _attemptSequence = 0;
  late _ConversationPracticeStep _step;

  ConversationTurn get _currentTurn =>
      widget.conversation.turns[_currentTurnIndex];

  bool get _isRecording => _activeRecordingId == _currentTurn.id;

  String get _learnerText =>
      _flowController.selectedChoice?.en ?? _currentTurn.en;

  String? get _learnerTranslation =>
      _flowController.selectedChoice?.es ?? _currentTurn.es;

  LessonPronunciation? get _activePronunciation {
    final pronunciations = _currentTurn.pronunciations;

    if (pronunciations.isEmpty) {
      return null;
    }

    return pronunciations.firstWhere(
      (pronunciation) => pronunciation.locale == _activeLocale,
      orElse: () => pronunciations.first,
    );
  }

  @override
  void initState() {
    super.initState();

    _flowController = ConversationFlowController(widget.conversation);
    _activePlaybackId = widget.audioService.activePlaybackId;
    _activeRecordingId = widget.audioService.activeRecordingId;

    final initialTurn = _flowController.currentTurn;

    if (initialTurn == null) {
      _step = _ConversationPracticeStep.completed;
    } else {
      _currentTurnIndex = widget.conversation.turns.indexWhere(
        (turn) => turn.id == initialTurn.id,
      );
      _selectAvailableLocale(initialTurn);
      _step = _initialStep(initialTurn);
    }

    _playbackSubscription = widget.audioService.onPlaybackChanged.listen((
      playbackId,
    ) {
      if (!mounted || widget.conversation.turns.isEmpty) {
        return;
      }

      final completedPlaybackId = _activePlaybackId;
      final turn = _currentTurn;
      final pronunciation = _activePronunciation;

      setState(() {
        _activePlaybackId = playbackId;

        if (playbackId != null || completedPlaybackId == null) {
          return;
        }

        if (_step == _ConversationPracticeStep.listenPartner &&
            pronunciation != null &&
            completedPlaybackId == _referencePlaybackId(turn, pronunciation)) {
          _step = _ConversationPracticeStep.understandPartner;
        }

        if (_step == _ConversationPracticeStep.reviewLearner &&
            completedPlaybackId == _recordingPlaybackId(turn)) {
          _hasReviewedRecording = true;
        }
      });
    });

    _recordingSubscription = widget.audioService.onRecordingChanged.listen((
      recordingId,
    ) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeRecordingId = recordingId;
      });
    });
  }

  _ConversationPracticeStep _initialStep(ConversationTurn turn) {
    return turn.isPartner
        ? _ConversationPracticeStep.listenPartner
        : _ConversationPracticeStep.prepareLearner;
  }

  void _selectChoice(ConversationChoice choice) {
    if (_isBusy ||
        _activePlaybackId != null ||
        _activeRecordingId != null ||
        _step != _ConversationPracticeStep.prepareLearner) {
      return;
    }

    final selected = _flowController.selectChoice(choice.id);

    if (!selected) {
      setState(() {
        _errorMessage = "No se pudo seleccionar esta respuesta.";
      });
      return;
    }

    setState(() {
      _recordingPath = null;
      _hasReviewedRecording = false;
      _errorMessage = null;
    });
  }

  void _selectAvailableLocale(ConversationTurn turn) {
    if (turn.pronunciations.isEmpty) {
      _activeLocale = null;
      return;
    }

    final keepsCurrentLocale = turn.pronunciations.any(
      (pronunciation) => pronunciation.locale == _activeLocale,
    );

    if (!keepsCurrentLocale) {
      _activeLocale = turn.pronunciations.first.locale;
    }
  }

  String _localeLabel(String locale) {
    return switch (locale) {
      'en-US' => 'Estados Unidos',
      'en-GB' => 'Reino Unido',
      _ => locale,
    };
  }

  String _referencePlaybackId(
    ConversationTurn turn,
    LessonPronunciation pronunciation,
  ) {
    return 'conversation-reference:${widget.conversation.id}:'
        '${turn.id}:${pronunciation.locale}';
  }

  String _recordingPlaybackId(ConversationTurn turn) {
    return 'conversation-recording:${widget.conversation.id}:${turn.id}';
  }

  Future<void> _playPartnerReference() async {
    final pronunciation = _activePronunciation;

    if (pronunciation == null ||
        _isBusy ||
        _activePlaybackId != null ||
        _activeRecordingId != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.audioService.playReference(
        pronunciation.audioAsset,
        playbackId: _referencePlaybackId(_currentTurn, pronunciation),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'No se pudo reproducir al interlocutor. Inténtalo nuevamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _startRecording() async {
    if (_isBusy || _activeRecordingId != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final hasPermission = await widget.audioService.hasMicrophonePermission();

      if (!hasPermission) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'No se concedió permiso para utilizar el micrófono.';
          });
        }
        return;
      }

      final previousPath = _recordingPath;

      if (previousPath != null) {
        await widget.audioService.stopPlayback();
        await widget.audioService.deleteRecording(previousPath);
      }

      await widget.audioService.startRecording(_currentTurn.id);

      if (mounted) {
        setState(() {
          _recordingPath = null;
          _hasReviewedRecording = false;
          _step = _ConversationPracticeStep.recordLearner;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la grabación.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_isBusy || !_isRecording) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final path = await widget.audioService.stopRecording();

      if (!mounted) {
        return;
      }

      setState(() {
        _recordingPath = path;
        _hasReviewedRecording = false;

        if (path == null) {
          _errorMessage = 'No se pudo crear una grabación utilizable.';
        } else {
          _step = _ConversationPracticeStep.reviewLearner;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo detener correctamente la grabación.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _playLearnerRecording() async {
    final path = _recordingPath;

    if (path == null ||
        _isBusy ||
        _activePlaybackId != null ||
        _activeRecordingId != null) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.audioService.playRecording(
        path,
        playbackId: _recordingPlaybackId(_currentTurn),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo reproducir tu respuesta.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _continueAfterPartner() {
    if (_step != _ConversationPracticeStep.understandPartner) {
      return;
    }

    _moveToNextTurn();
  }

  Future<void> _continueAfterLearner() async {
    if (_step != _ConversationPracticeStep.reviewLearner ||
        !_hasReviewedRecording ||
        _isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final path = _recordingPath;

      await widget.audioService.stopPlayback();

      if (path != null) {
        await widget.audioService.deleteRecording(path);
      }

      if (mounted) {
        setState(() {
          _recordingPath = null;
          _hasReviewedRecording = false;
          _moveToNextTurn(updateState: false);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo avanzar al siguiente turno.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _saveCompletedAttempt(int attemptSequence) async {
    if (!mounted || _isSavingAttempt || _attemptSaved) {
      return;
    }

    setState(() {
      _isSavingAttempt = true;
      _persistenceMessage = "Guardando progreso conversacional...";
    });

    try {
      final saved = await _apiService.saveConversationAttempt(
        userId: widget.userId,
        levelId: widget.levelId,
        unitId: widget.unitId,
        lessonId: widget.lessonId,
        conversationId: widget.conversation.id,
        mode: widget.conversation.mode,
        visitedTurnIds: _flowController.visitedTurnIds,
        selectedChoiceIds: _flowController.selectedChoiceIds,
      );

      if (!mounted || attemptSequence != _attemptSequence) {
        return;
      }

      setState(() {
        _attemptSaved = saved;
        _persistenceMessage = saved
            ? "Progreso conversacional guardado."
            : "La conversación terminó, pero no se pudo guardar el progreso.";
      });
    } catch (_) {
      if (!mounted || attemptSequence != _attemptSequence) {
        return;
      }

      setState(() {
        _persistenceMessage =
            "La conversación terminó, pero no se pudo guardar el progreso.";
      });
    } finally {
      if (mounted && attemptSequence == _attemptSequence) {
        setState(() {
          _isSavingAttempt = false;
        });
      }
    }
  }

  void _moveToNextTurn({bool updateState = true}) {
    var completedNow = false;
    void move() {
      final advanced = _flowController.advance();

      if (!advanced) {
        _errorMessage = "No se pudo avanzar al siguiente turno.";
        return;
      }

      if (_flowController.isCompleted) {
        _step = _ConversationPracticeStep.completed;
        completedNow = true;
        return;
      }

      final nextTurn = _flowController.currentTurn;

      if (nextTurn == null) {
        _errorMessage = "No se pudo encontrar el siguiente turno.";
        return;
      }

      _currentTurnIndex = widget.conversation.turns.indexWhere(
        (turn) => turn.id == nextTurn.id,
      );

      _selectAvailableLocale(nextTurn);
      _step = _initialStep(nextTurn);
      _errorMessage = null;
    }

    if (updateState) {
      setState(move);
    } else {
      move();
    }

    if (completedNow) {
      unawaited(_saveCompletedAttempt(_attemptSequence));
    }
  }

  Future<void> _restartConversation() async {
    if (_isBusy) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      await widget.audioService.stopPlayback();

      final path = _recordingPath;
      if (path != null) {
        await widget.audioService.deleteRecording(path);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _flowController.reset();

        final initialTurn = _flowController.currentTurn;

        _recordingPath = null;
        _hasReviewedRecording = false;
        _attemptSequence += 1;
        _isSavingAttempt = false;
        _attemptSaved = false;
        _persistenceMessage = null;

        if (initialTurn == null) {
          _currentTurnIndex = 0;
          _step = _ConversationPracticeStep.completed;
        } else {
          _currentTurnIndex = widget.conversation.turns.indexWhere(
            (turn) => turn.id == initialTurn.id,
          );
          _selectAvailableLocale(initialTurn);
          _step = _initialStep(initialTurn);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo reiniciar la conversación.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Widget _buildLocaleSelector() {
    final pronunciations = _currentTurn.pronunciations;

    if (pronunciations.length < 2) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pronunciations
          .map(
            (pronunciation) => ChoiceChip(
              label: Text(_localeLabel(pronunciation.locale)),
              selected: pronunciation.locale == _activeLocale,
              onSelected:
                  !_isBusy &&
                      _activePlaybackId == null &&
                      _activeRecordingId == null
                  ? (selected) {
                      if (selected) {
                        setState(() {
                          _activeLocale = pronunciation.locale;
                        });
                      }
                    }
                  : null,
            ),
          )
          .toList(),
    );
  }

  Widget _buildPartnerControls() {
    final pronunciation = _activePronunciation;
    final canPlay =
        pronunciation != null &&
        !_isBusy &&
        _activePlaybackId == null &&
        _activeRecordingId == null;

    if (_step == _ConversationPracticeStep.listenPartner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocaleSelector(),
          if (_currentTurn.pronunciations.length > 1)
            const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: canPlay ? _playPartnerReference : null,
            icon: const Icon(Icons.volume_up_outlined),
            label: const Text('Escuchar al interlocutor'),
          ),
          if (pronunciation == null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isBusy
                  ? null
                  : () {
                      setState(() {
                        _step = _ConversationPracticeStep.understandPartner;
                      });
                    },
              child: const Text('Continuar sin audio'),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentTurn.es != null) ...[
          Text(_currentTurn.es!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          onPressed: _isBusy ? null : _continueAfterPartner,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Entendí, continuar'),
        ),
      ],
    );
  }

  Widget _buildChoiceSelector() {
    final canSelect =
        !_isBusy &&
        _activePlaybackId == null &&
        _activeRecordingId == null &&
        _step == _ConversationPracticeStep.prepareLearner;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Elige la respuesta que quieres practicar:",
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currentTurn.choices
              .map(
                (choice) => ChoiceChip(
                  label: Text(choice.en),
                  selected: _flowController.selectedChoice?.id == choice.id,
                  onSelected: canSelect ? (_) => _selectChoice(choice) : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLearnerControls() {
    final hasChoices = _currentTurn.hasChoices;

    if (hasChoices && _flowController.selectedChoice == null) {
      return _buildChoiceSelector();
    }

    final choiceSelector = hasChoices
        ? <Widget>[_buildChoiceSelector(), const SizedBox(height: 14)]
        : const <Widget>[];

    if (_step == _ConversationPracticeStep.prepareLearner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...choiceSelector,
          FilledButton.icon(
            onPressed:
                !_isBusy &&
                    _activePlaybackId == null &&
                    _activeRecordingId == null
                ? _startRecording
                : null,
            icon: const Icon(Icons.mic_none),
            label: const Text('Grabar mi respuesta'),
          ),
        ],
      );
    }

    if (_step == _ConversationPracticeStep.recordLearner && _isRecording) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...choiceSelector,
          FilledButton.icon(
            onPressed: _isBusy ? null : _stopRecording,
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Detener grabación'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...choiceSelector,
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed:
                  !_isBusy &&
                      _activePlaybackId == null &&
                      _activeRecordingId == null
                  ? _playLearnerRecording
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Reproducir mi voz'),
            ),
            TextButton.icon(
              onPressed:
                  !_isBusy &&
                      _activePlaybackId == null &&
                      _activeRecordingId == null
                  ? _startRecording
                  : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Volver a grabar'),
            ),
          ],
        ),
        if (_hasReviewedRecording) ...[
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isBusy ? null : _continueAfterLearner,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Avanzar al siguiente turno'),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text('Escucha tu voz antes de avanzar.'),
        ],
      ],
    );
  }

  Widget _buildCompletedState(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 40,
            color: colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 8),
          Text(
            'Conversación completada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.conversation.mode == 'branching'
                ? 'Has completado la ruta conversacional elegida.'
                : 'Has escuchado y respondido todos los turnos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onPrimaryContainer),
          ),
          if (_persistenceMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isSavingAttempt) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    _persistenceMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onPrimaryContainer),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isBusy ? null : _restartConversation,
            icon: const Icon(Icons.replay),
            label: const Text('Repetir conversación'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _recordingSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.conversation.turns.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.conversation.context != null)
                        Text(widget.conversation.context!),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_step == _ConversationPracticeStep.completed)
              _buildCompletedState(colorScheme)
            else ...[
              Text(
                widget.conversation.mode == "branching"
                    ? "Turno ${_flowController.visitedTurnIds.length} de la ruta"
                    : "Turno ${_currentTurnIndex + 1} de "
                          "${widget.conversation.turns.length}",
                style: Theme.of(context).textTheme.labelLarge,
              ),
              if (widget.conversation.mode != "branching") ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value:
                      (_currentTurnIndex + 1) /
                      widget.conversation.turns.length,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _currentTurn.isPartner
                      ? colorScheme.secondaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _currentTurn.isPartner
                              ? Icons.record_voice_over_outlined
                              : Icons.person_outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentTurn.isPartner
                              ? 'Interlocutor'
                              : 'Tu respuesta',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentTurn.isLearner ? _learnerText : _currentTurn.en,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_currentTurn.isLearner &&
                        _learnerTranslation != null) ...[
                      const SizedBox(height: 6),
                      Text(_learnerTranslation!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_currentTurn.isPartner)
                _buildPartnerControls()
              else
                _buildLearnerControls(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(_errorMessage!, style: TextStyle(color: colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}
