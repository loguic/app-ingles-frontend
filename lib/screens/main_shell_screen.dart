import 'package:flutter/material.dart';

import '../services/pronunciation_audio_service.dart';
import '../theme/loguic_theme.dart';
import '../widgets/info_card.dart';
import '../widgets/lesson_list_card.dart';
import '../widgets/unit_list_card.dart';
import 'home_screen.dart';
import 'lesson_detail_screen.dart';
import 'visual_demo_screens.dart';
import 'station_journey_screen.dart';

typedef LearnDestinationBuilder =
    Widget Function(BuildContext context, ValueChanged<String> openLesson);

typedef LessonScreenBuilder = Widget Function(String lessonId);

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    this.learnDestinationBuilder,
    this.lessonScreenBuilder,
    this.demoAudioController,
    this.isDarkTheme = false,
    this.onThemeChanged,
    super.key,
  });

  final LearnDestinationBuilder? learnDestinationBuilder;
  final LessonScreenBuilder? lessonScreenBuilder;
  final PronunciationAudioController? demoAudioController;
  final bool isDarkTheme;
  final ValueChanged<ThemeMode>? onThemeChanged;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  static const double _desktopBreakpoint = 900;

  int _selectedDestination = 0;
  final String _selectedLevelCode = 'A1';
  String? _selectedUnitId;
  String? _selectedLessonId;
  int _homeRefreshCounter = 0;

  void _showVisualMap() {
    setState(() => _selectedDestination = 1);
  }

  void _showHome() {
    setState(() => _selectedDestination = 0);
  }

  Future<void> _openVisualDemo() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            VisualDemoLessonScreen(audioController: widget.demoAudioController),
      ),
    );
  }

  void _selectUnit(String unitId) {
    setState(() {
      _selectedUnitId = unitId;
      _selectedLessonId = null;
    });
  }

  Future<void> _openLesson(String lessonId) async {
    final unitId = _selectedUnitId;
    if (unitId == null && widget.learnDestinationBuilder == null) {
      return;
    }

    setState(() {
      _selectedLessonId = lessonId;
    });

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            widget.lessonScreenBuilder?.call(lessonId) ??
            LessonDetailScreen(
              lessonId: lessonId,
              levelId: _selectedLevelCode,
              unitId: unitId!,
            ),
      ),
    );

    if (mounted) {
      setState(() => _homeRefreshCounter++);
    }
  }

  List<Widget> _destinations() {
    return [
      HomeScreen(
        refreshCounter: _homeRefreshCounter,
        onExploreDemo: _showVisualMap,
        onOpenLearn: () => setState(() => _selectedDestination = 2),
        onOpenStation: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StationJourneyScreen(
              audioController: widget.demoAudioController,
              isDarkTheme: widget.isDarkTheme,
              onThemeChanged: widget.onThemeChanged,
            ),
          ),
        ),
      ),
      _ShellDestination(
        title: 'Niveles',
        description: 'Explora el horizonte de LOGUIC English.',
        child: VisualLevelMap(
          onOpenDemo: _openVisualDemo,
          onBackToHome: _showHome,
        ),
      ),
      widget.learnDestinationBuilder?.call(context, _openLesson) ??
          _ShellDestination(
            title: 'Aprender',
            description: 'Explora unidades y abre una lección para practicar.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UnitListCard(
                  selectedLevelCode: _selectedLevelCode,
                  selectedUnitId: _selectedUnitId,
                  onUnitSelected: _selectUnit,
                ),
                const SizedBox(height: LoguicTheme.contentSpacing),
                const _LearningAreas(),
                if (_selectedUnitId != null) ...[
                  const SizedBox(height: LoguicTheme.contentSpacing),
                  LessonListCard(
                    selectedUnitId: _selectedUnitId!,
                    selectedLessonId: _selectedLessonId,
                    onLessonSelected: _openLesson,
                  ),
                ],
              ],
            ),
          ),
      const _UnavailableDestination(
        title: 'Repaso',
        message: 'El repaso adaptativo todavía no está disponible.',
      ),
      _ShellDestination(
        title: 'Perfil y ajustes',
        description: 'Personaliza la apariencia de la aplicación.',
        child: Column(
          children: [
            InfoCard(
              title: 'Apariencia',
              child: Wrap(
                spacing: 12,
                children: [
                  TextButton(
                    key: const Key('a1-theme-light'),
                    onPressed: () =>
                        widget.onThemeChanged?.call(ThemeMode.light),
                    child: const Text('Light'),
                  ),
                  TextButton(
                    key: const Key('a1-theme-dark'),
                    onPressed: () =>
                        widget.onThemeChanged?.call(ThemeMode.dark),
                    child: const Text('Dark'),
                  ),
                ],
              ),
            ),
            const _PendingCard(title: 'Perfil y logros'),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations();

    return LayoutBuilder(
      builder: (context, constraints) {
        final useNavigationRail = constraints.maxWidth >= _desktopBreakpoint;
        final content = SafeArea(
          child: IndexedStack(
            index: _selectedDestination,
            children: destinations,
          ),
        );

        return Scaffold(
          appBar: useNavigationRail
              ? null
              : AppBar(
                  toolbarHeight: 72,
                  title: const _BrandLockup(compact: true),
                  centerTitle: true,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                ),
          body: useNavigationRail
              ? Row(
                  children: [
                    _DesktopNavigation(
                      selectedIndex: _selectedDestination,
                      onDestinationSelected: (index) {
                        setState(() => _selectedDestination = index);
                      },
                    ),
                    Expanded(child: content),
                  ],
                )
              : content,
          bottomNavigationBar: useNavigationRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedDestination,
                  onDestinationSelected: (index) {
                    setState(() => _selectedDestination = index);
                  },
                  destinations: _navigationDestinations
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }
}

class _DesktopNavigation extends StatelessWidget {
  const _DesktopNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('desktop-brand-sidebar'),
      width: 264,
      decoration: const BoxDecoration(
        color: LoguicTheme.deepNavy,
        boxShadow: [
          BoxShadow(
            color: Color(0x24111E3B),
            blurRadius: 24,
            offset: Offset(8, 0),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 22),
            child: _BrandLockup(compact: false),
          ),
          const SizedBox(height: 34),
          Expanded(
            child: NavigationRail(
              extended: true,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: _navigationDestinations
                  .map(
                    (item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = compact ? LoguicTheme.navy : Colors.white;
    final secondary = compact ? LoguicTheme.blue : const Color(0xFFB9C4DC);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: LoguicTheme.indigo,
            borderRadius: BorderRadius.circular(compact ? 11 : 13),
          ),
          child: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOGUIC English',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: foreground,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Escucha. Habla. Lee. Avanza.',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: secondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShellDestination extends StatelessWidget {
  const _ShellDestination({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: LoguicTheme.contentSpacing,
        vertical: 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(description),
              const SizedBox(height: LoguicTheme.contentSpacing),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _UnavailableDestination extends StatelessWidget {
  const _UnavailableDestination({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _ShellDestination(
      title: title,
      description: message,
      child: InfoCard(title: 'En preparación', child: Text(message)),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _navigationDestinations = [
  _NavigationItem('Inicio', Icons.home_outlined, Icons.home),
  _NavigationItem('Niveles', Icons.map_outlined, Icons.map),
  _NavigationItem('Aprender', Icons.school_outlined, Icons.school),
  _NavigationItem('Repaso', Icons.replay_outlined, Icons.replay),
  _NavigationItem('Perfil', Icons.person_outline, Icons.person),
];

class _LearningAreas extends StatelessWidget {
  const _LearningAreas();

  @override
  Widget build(BuildContext context) {
    const areas = [
      'Portada de lección',
      'Listening',
      'Speaking y conversación',
      'Pronunciación',
      'Reading',
      'Vocabulario',
      'Gramática',
      'Progreso y logros',
    ];
    return InfoCard(
      title: 'Áreas de aprendizaje',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: areas
            .map(
              (area) => OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(area)),
                      body: _ShellDestination(
                        title: area,
                        description: 'Explora esta sección de LOGUIC English.',
                        child: _PendingCard(title: area),
                      ),
                    ),
                  ),
                ),
                child: Text(area),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => InfoCard(
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('En preparación'),
        const SizedBox(height: 8),
        FilledButton(onPressed: null, child: const Text('En preparación')),
      ],
    ),
  );
}
