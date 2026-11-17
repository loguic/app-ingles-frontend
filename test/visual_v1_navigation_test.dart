import 'package:app_ingles/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('starts in the shell and opens the internal station activity', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AppIngles());
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a LOGUIC English'), findsOneWidget);
    expect(find.text('Estación de tren'), findsOneWidget);
    await tester.tap(find.text('Estación de tren'));
    await tester.pumpAndSettle();
    expect(find.text('Práctica oral en la estación'), findsOneWidget);
  });
}
