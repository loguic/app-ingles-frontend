import 'dart:async';

import 'package:flutter/material.dart';

import '../models/visual_demo_content.dart';
import '../services/pronunciation_audio_service.dart';
import '../theme/loguic_theme.dart';
import '../widgets/lesson_conversation_card.dart';
import '../widgets/lesson_pronunciation_controls.dart';

class VisualDemoNotice extends StatelessWidget {
  const VisualDemoNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E5FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: LoguicTheme.indigo, size: 20),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              visualDemoNotice,
              style: TextStyle(
                color: LoguicTheme.deepNavy,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class VisualLevelMap extends StatelessWidget {
  const VisualLevelMap({
    required this.onOpenDemo,
    required this.onBackToHome,
    super.key,
  });

  final VoidCallback onOpenDemo;
  final VoidCallback onBackToHome;

  @override
  Widget build(BuildContext context) {
    const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const VisualDemoNotice(),
        const SizedBox(height: 20),
        Text(
          'Tu horizonte en inglés',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: LoguicTheme.deepNavy,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Explora una muestra de A1. Los demás niveles solo presentan el '
          'horizonte del producto.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth >= 620
                ? (constraints.maxWidth - 24) / 3
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: levels.map((level) {
                final isDemo = level == 'A1';

                return SizedBox(
                  width: cardWidth,
                  child: Card(
                    color: isDemo ? const Color(0xFFE8E5FF) : Colors.white,
                    child: InkWell(
                      key: Key('visual-level-$level'),
                      borderRadius: BorderRadius.circular(
                        LoguicTheme.cardRadius,
                      ),
                      onTap: isDemo ? onOpenDemo : null,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: isDemo
                                        ? LoguicTheme.indigo
                                        : LoguicTheme.navy,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isDemo
                                  ? 'Demostración disponible'
                                  : 'Horizonte del producto',
                              style: TextStyle(
                                color: LoguicTheme.navy.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isDemo) ...[
                              const SizedBox(height: 12),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: LoguicTheme.indigo,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onBackToHome,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a Inicio'),
          ),
        ),
      ],
    );
  }
}

class VisualDemoLessonScreen extends StatefulWidget {
  const VisualDemoLessonScreen({this.audioController, super.key});

  final PronunciationAudioController? audioController;

  @override
  State<VisualDemoLessonScreen> createState() => _VisualDemoLessonScreenState();
}

class _VisualDemoLessonScreenState extends State<VisualDemoLessonScreen> {
  late final PronunciationAudioController _audioController;
  late final bool _ownsAudioController;

  @override
  void initState() {
    super.initState();
    _ownsAudioController = widget.audioController == null;
    _audioController = widget.audioController ?? PronunciationAudioService();
  }

  @override
  void dispose() {
    if (_ownsAudioController) {
      unawaited(_audioController.dispose());
    }
    super.dispose();
  }

  Future<void> _openListening() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            VisualDemoListeningScreen(audioController: _audioController),
      ),
    );
  }

  Future<void> _openConversation() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            VisualDemoConversationScreen(audioController: _audioController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Demostración A1',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VisualDemoNotice(),
          const SizedBox(height: 20),
          const _VisualContextCard(),
          const SizedBox(height: 20),
          Text(
            visualDemoContent.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: LoguicTheme.deepNavy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(visualDemoContent.situation),
          const SizedBox(height: 8),
          Text(
            visualDemoContent.objective,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          _DemoActionCard(
            icon: Icons.headphones_outlined,
            title: '1. Escucha y pronuncia',
            description: 'Escucha una pregunta y prueba tu propia voz.',
            buttonLabel: 'Abrir escucha y pronunciación',
            onPressed: _openListening,
          ),
          const SizedBox(height: 14),
          _DemoActionCard(
            icon: Icons.forum_outlined,
            title: '2. Conversación breve',
            description: 'Recorre una interacción sin evaluación ni guardado.',
            buttonLabel: 'Abrir conversación breve',
            onPressed: _openConversation,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver al mapa'),
            ),
          ),
        ],
      ),
    );
  }
}

class VisualDemoListeningScreen extends StatefulWidget {
  const VisualDemoListeningScreen({required this.audioController, super.key});

  final PronunciationAudioController audioController;

  @override
  State<VisualDemoListeningScreen> createState() =>
      _VisualDemoListeningScreenState();
}

class _VisualDemoListeningScreenState extends State<VisualDemoListeningScreen> {
  bool _hasListened = false;
  bool _showTranscript = false;
  bool _showTranslation = false;

  void _handleReferenceListened() {
    if (!_hasListened) {
      setState(() => _hasListened = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Escucha y pronunciación',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VisualDemoNotice(),
          const SizedBox(height: 18),
          const _VisualContextCard(compact: true),
          const SizedBox(height: 18),
          Text(
            'Escucha primero',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Elige una variante y reproduce la pregunta antes de pedir ayuda.',
          ),
          const SizedBox(height: 12),
          LessonPronunciationControls(
            exampleId: '${visualDemoContent.id}-listening',
            pronunciations: visualDemoContent.pronunciations,
            audioService: widget.audioController,
            demoMode: true,
            onReferenceListened: _handleReferenceListened,
          ),
          if (_hasListened) ...[
            const SizedBox(height: 20),
            _SupportCard(
              key: const Key('demo-listening-hint'),
              icon: Icons.lightbulb_outline,
              title: 'Pista breve',
              child: Text(visualDemoContent.hint),
            ),
            const SizedBox(height: 10),
            if (!_showTranscript)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showTranscript = true),
                  icon: const Icon(Icons.closed_caption_outlined),
                  label: const Text('Mostrar transcript'),
                ),
              ),
          ],
          if (_showTranscript) ...[
            _SupportCard(
              key: const Key('demo-listening-transcript'),
              icon: Icons.subtitles_outlined,
              title: 'Transcript',
              child: Text(visualDemoContent.transcript),
            ),
            const SizedBox(height: 8),
            if (!_showTranslation)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showTranslation = true),
                  icon: const Icon(Icons.translate),
                  label: const Text('Ver traducción de rescate'),
                ),
              ),
          ],
          if (_showTranslation)
            _SupportCard(
              key: const Key('demo-listening-translation'),
              icon: Icons.translate,
              title: 'Traducción opcional',
              child: Text(visualDemoContent.translation),
            ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a la portada demo'),
            ),
          ),
        ],
      ),
    );
  }
}

class VisualDemoConversationScreen extends StatelessWidget {
  const VisualDemoConversationScreen({
    required this.audioController,
    super.key,
  });

  final PronunciationAudioController audioController;

  @override
  Widget build(BuildContext context) {
    return _DemoScaffold(
      title: 'Conversación breve',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VisualDemoNotice(),
          const SizedBox(height: 18),
          const _VisualContextCard(compact: true),
          const SizedBox(height: 18),
          LessonConversationCard(
            conversation: visualDemoContent.conversation,
            levelId: 'demo-visual-a1',
            unitId: 'demo-visual-a1-situation',
            lessonId: visualDemoContent.id,
            userId: 'demo-visual-local-user',
            audioService: audioController,
            persistencePolicy: ConversationPersistencePolicy.disabled,
            demoMode: true,
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver a la portada demo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoScaffold extends StatelessWidget {
  const _DemoScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _VisualContextCard extends StatelessWidget {
  const _VisualContextCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('demo-visual-context'),
      padding: EdgeInsets.all(compact ? 18 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [LoguicTheme.deepNavy, LoguicTheme.indigo],
        ),
        borderRadius: BorderRadius.circular(LoguicTheme.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 58 : 72,
            height: compact ? 58 : 72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_cafe_outlined,
              color: LoguicTheme.indigo,
              size: compact ? 30 : 38,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contexto visual',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFD6DDF0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  visualDemoContent.situation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoActionCard extends StatelessWidget {
  const _DemoActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: LoguicTheme.indigo, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(description),
                  const SizedBox(height: 14),
                  FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LoguicTheme.sky,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: LoguicTheme.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
