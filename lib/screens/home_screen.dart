import 'package:flutter/material.dart';

import '../theme/loguic_theme.dart';
import '../widgets/conversation_history_card.dart';
import '../widgets/conversation_productions_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onExploreDemo,
    this.onOpenStation,
    this.onOpenLearn,
    this.refreshCounter = 0,
    super.key,
  });

  final VoidCallback onExploreDemo;
  final VoidCallback? onOpenStation;
  final VoidCallback? onOpenLearn;
  final int refreshCounter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: wide ? 36 : 20,
            vertical: 28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Bienvenido a LOGUIC English',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Escucha. Habla. Lee. Avanza.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _StationHero(onOpenStation: onOpenStation),
                  const SizedBox(height: 32),
                  _SectionHeader(
                    title: 'Ruta de aprendizaje',
                    action: TextButton(
                      key: const Key('explore-visual-demo'),
                      onPressed: onExploreDemo,
                      child: const Text('Explorar demostración'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
                        _LevelCard(
                          level: level,
                          onTap: level == 'A1' ? onExploreDemo : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: const Text('Unidades y lecciones'),
                      subtitle: const Text('Explora el contenido disponible'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: onOpenLearn,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'Practica a tu ritmo'),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, box) {
                      final columns = box.maxWidth >= 850
                          ? 3
                          : box.maxWidth >= 510
                          ? 2
                          : 1;
                      final width =
                          (box.maxWidth - (columns - 1) * 12) / columns;
                      const modules = [
                        (
                          Icons.headphones_rounded,
                          'Listening',
                          'Comprende el inglés en contexto',
                        ),
                        (
                          Icons.forum_outlined,
                          'Speaking',
                          'Practica conversaciones',
                        ),
                        (
                          Icons.menu_book_outlined,
                          'Reading',
                          'Lee y comprende',
                        ),
                        (
                          Icons.record_voice_over_outlined,
                          'Pronunciación',
                          'Practica sonidos y ritmo',
                        ),
                        (
                          Icons.translate_rounded,
                          'Vocabulario',
                          'Descubre palabras útiles',
                        ),
                        (
                          Icons.auto_stories_outlined,
                          'Gramática',
                          'Explora estructuras',
                        ),
                        (Icons.replay_rounded, 'Repaso', 'Vuelve a practicar'),
                      ];
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final (icon, title, subtitle) in modules)
                            SizedBox(
                              width: width,
                              child: _ModuleCard(
                                icon: icon,
                                title: title,
                                subtitle: subtitle,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  const _SectionHeader(title: 'Tu actividad'),
                  const SizedBox(height: 12),
                  Card(
                    key: const Key('home-progress-highlight'),
                    child: ListTile(
                      title: const Text('Progreso'),
                      subtitle: const Text('En preparación'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ConversationHistoryCard(
                            key: ValueKey(
                              'conversation-history-$refreshCounter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ConversationProductionsCard(
                            key: ValueKey(
                              'conversation-productions-$refreshCounter',
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    ConversationHistoryCard(
                      key: ValueKey('conversation-history-$refreshCounter'),
                    ),
                    const SizedBox(height: 12),
                    ConversationProductionsCard(
                      key: ValueKey('conversation-productions-$refreshCounter'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StationHero extends StatelessWidget {
  const _StationHero({required this.onOpenStation});
  final VoidCallback? onOpenStation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('home-station-hero'),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 650;
          final image = Image.asset(
            'assets/mb1/visual/station-restroom-help.png',
            fit: BoxFit.cover,
            height: wide ? 260 : 190,
            width: double.infinity,
            semanticLabel: 'Escena de una estación de tren',
          );
          final content = Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÁCTICA DISPONIBLE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tu misión en la estación',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Escucha y practica cómo pedir ayuda en inglés.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onOpenStation,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Estación de tren'),
                ),
              ],
            ),
          );
          if (wide) {
            return Row(
              children: [
                Expanded(child: content),
                Expanded(child: image),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [image, content],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      ?action,
    ],
  );
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level, required this.onTap});
  final String level;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(LoguicTheme.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  onTap == null ? 'En preparación' : 'Explorar',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.onSurface, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 10),
            Text(
              'En preparación',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
