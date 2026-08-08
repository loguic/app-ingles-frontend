import 'package:flutter/material.dart';

import 'screens/main_shell_screen.dart';
import 'theme/loguic_theme.dart';

void main() {
  runApp(const AppIngles());
}

/// Root widget of the English learning application.
/// Widget raíz de la aplicación de aprendizaje de inglés.
class AppIngles extends StatelessWidget {
  const AppIngles({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOGUIC English',
      debugShowCheckedModeBanner: false,
      theme: LoguicTheme.light,
      home: const MainShellScreen(),
    );
  }
}
