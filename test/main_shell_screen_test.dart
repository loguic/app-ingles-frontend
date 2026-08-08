import 'package:app_ingles/screens/main_shell_screen.dart';
import 'package:app_ingles/theme/loguic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp({
  LearnDestinationBuilder? learnDestinationBuilder,
  LessonScreenBuilder? lessonScreenBuilder,
}) {
  return MaterialApp(
    theme: LoguicTheme.light,
    home: MainShellScreen(
      learnDestinationBuilder: learnDestinationBuilder,
      lessonScreenBuilder: lessonScreenBuilder,
    ),
  );
}

void _setViewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  testWidgets('shows the LOGUIC brand and five compact destinations', (
    tester,
  ) async {
    _setViewport(tester, const Size(600, 900));

    await tester.pumpWidget(_testApp());

    expect(find.text('LOGUIC English'), findsOneWidget);
    expect(find.text('Escucha. Habla. Lee. Avanza.'), findsNWidgets(2));
    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Inicio', 'Niveles', 'Aprender', 'Repaso', 'Perfil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Bienvenido a LOGUIC English'), findsOneWidget);
    expect(find.text('Estado del backend'), findsNothing);
  });

  testWidgets('uses one lateral navigation on a wide desktop', (tester) async {
    _setViewport(tester, const Size(1280, 900));

    await tester.pumpWidget(_testApp());

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('LOGUIC English'), findsOneWidget);
    final sidebar = tester.widget<Container>(
      find.byKey(const Key('desktop-brand-sidebar')),
    );
    final decoration = sidebar.decoration! as BoxDecoration;
    expect(decoration.color, LoguicTheme.deepNavy);
    expect(find.byKey(const Key('home-progress-highlight')), findsOneWidget);
  });

  testWidgets('switches to neutral review and profile destinations', (
    tester,
  ) async {
    _setViewport(tester, const Size(600, 900));

    await tester.pumpWidget(_testApp());
    await tester.tap(find.text('Repaso'));
    await tester.pump();

    expect(
      find.text('El repaso adaptativo todavía no está disponible.'),
      findsNWidgets(2),
    );

    await tester.tap(find.text('Perfil'));
    await tester.pump();

    expect(
      find.text(
        'El perfil y el progreso familiar todavía no están disponibles.',
      ),
      findsNWidgets(2),
    );
    expect(find.textContaining('demo-user'), findsNothing);
  });

  testWidgets('keeps Navigator-based lesson opening from Learn', (
    tester,
  ) async {
    _setViewport(tester, const Size(600, 900));

    await tester.pumpWidget(
      _testApp(
        learnDestinationBuilder: (context, openLesson) => Center(
          child: FilledButton(
            onPressed: () => openLesson('a1-u1-l2'),
            child: const Text('Abrir lección existente'),
          ),
        ),
        lessonScreenBuilder: (lessonId) => Scaffold(body: Text(lessonId)),
      ),
    );

    await tester.tap(find.text('Aprender'));
    await tester.pump();
    await tester.tap(find.text('Abrir lección existente'));
    await tester.pumpAndSettle();

    expect(find.text('a1-u1-l2'), findsOneWidget);
  });
}
