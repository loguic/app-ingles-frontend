import 'package:app_ingles/screens/home_screen.dart';
import 'package:app_ingles/theme/loguic_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final first = a.computeLuminance();
  final second = b.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('dashboard theme text colors meet normal text contrast', () {
    for (final theme in [LoguicTheme.light, LoguicTheme.dark]) {
      expect(
        contrast(theme.colorScheme.onSurface, theme.scaffoldBackgroundColor),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(theme.colorScheme.onSurface, theme.cardTheme.color!),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
  for (final theme in [LoguicTheme.light, LoguicTheme.dark]) {
    testWidgets('home shows learning path and modules in ${theme.brightness}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: HomeScreen(onExploreDemo: () {}, onOpenStation: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Bienvenido a LOGUIC English'), findsOneWidget);
      expect(find.byKey(const Key('home-station-hero')), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Ruta de aprendizaje'), 300);
      expect(find.text('Ruta de aprendizaje'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Listening'), 300);
      expect(find.text('Listening'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
