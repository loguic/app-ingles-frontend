import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_ingles/main.dart';

void main() {
  testWidgets('app opens the A1 speaking journey directly', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AppIngles());

    expect(find.text('LOGUIC English'), findsOneWidget);
    expect(find.text('You are thirsty. Ask for water.'), findsOneWidget);
    expect(find.text('Speech model not configured'), findsNothing);
    expect(find.byKey(const Key('a1-theme-toggle')), findsOneWidget);
    expect(find.byKey(const Key('a1-theme-light')), findsOneWidget);
    expect(find.byKey(const Key('a1-theme-dark')), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('restores and persists the learner theme choice', (tester) async {
    SharedPreferences.setMockInitialValues({'a1-theme-mode': 'light'});
    await tester.pumpWidget(const AppIngles());
    await tester.pumpAndSettle();

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
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
