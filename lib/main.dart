import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/a1_v4_visible_demo_screen.dart';
import 'theme/loguic_theme.dart';

void main() {
  runApp(const AppIngles());
}

/// Root widget of the English learning application.
/// Widget raíz de la aplicación de aprendizaje de inglés.
class AppIngles extends StatefulWidget {
  const AppIngles({super.key});

  @override
  State<AppIngles> createState() => _AppInglesState();
}

class _AppInglesState extends State<AppIngles> {
  static const _themePreferenceKey = 'a1-theme-mode';
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _restoreTheme();
  }

  Future<void> _restoreTheme() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_themePreferenceKey);
    if (mounted && saved == ThemeMode.light.name) {
      setState(() => _themeMode = ThemeMode.light);
    }
  }

  Future<void> _setTheme(ThemeMode themeMode) async {
    setState(() => _themeMode = themeMode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, themeMode.name);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOGUIC English',
      debugShowCheckedModeBanner: false,
      theme: LoguicTheme.light,
      darkTheme: LoguicTheme.dark,
      themeMode: _themeMode,
      themeAnimationDuration: Duration.zero,
      // A1 currently has one complete learner journey. Enter it directly
      // instead of routing learners through the retired demo map.
      home: A1V4VisibleDemoScreen(
        isDarkTheme: _themeMode == ThemeMode.dark,
        onThemeChanged: _setTheme,
      ),
    );
  }
}
