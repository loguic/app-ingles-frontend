import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_ingles/main.dart';

void main() {
  testWidgets('app opens the station activity from the shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AppIngles());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido a LOGUIC English'), findsOneWidget);
    await tester.tap(find.text('Estación de tren'));
    await tester.pumpAndSettle();
    expect(find.text('Práctica oral en la estación'), findsOneWidget);
    expect(
      find.text('You are at a UK train station and need to find a place.'),
      findsOneWidget,
    );
    expect(find.text('Speech model not configured'), findsNothing);
    expect(find.byKey(const Key('a1-theme-light')), findsOneWidget);
    expect(find.byKey(const Key('a1-theme-dark')), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
  });

  testWidgets('restores and persists the learner theme choice', (tester) async {
    SharedPreferences.setMockInitialValues({'a1-theme-mode': 'light'});
    await tester.pumpWidget(const AppIngles());
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('a1-theme-dark')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('a1-theme-mode'), 'dark');

    await tester.tap(find.byKey(const Key('a1-theme-light')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
    expect(preferences.getString('a1-theme-mode'), 'light');
  });
}
