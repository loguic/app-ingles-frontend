import 'package:flutter_test/flutter_test.dart';

import 'package:app_ingles/main.dart';

void main() {
  testWidgets('Home screen shows app title and welcome message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AppIngles());

    expect(find.text('App Inglés'), findsOneWidget);
    expect(find.text('Bienvenido a App Inglés'), findsOneWidget);
  });
}
