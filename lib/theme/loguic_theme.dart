import 'package:flutter/material.dart';

abstract final class LoguicTheme {
  static const Color navy = Color(0xFF183153);
  static const Color deepNavy = Color(0xFF111E3B);
  static const Color blue = Color(0xFF315FCE);
  static const Color indigo = Color(0xFF6558E8);
  static const Color sky = Color(0xFFEAF1FF);
  static const Color mint = Color(0xFFDDF5EA);
  static const Color canvas = Color(0xFFF3F6FC);
  static const double contentSpacing = 24;
  static const double cardRadius = 24;

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: blue,
          brightness: Brightness.light,
          surface: Colors.white,
        ).copyWith(
          primary: blue,
          onPrimary: Colors.white,
          secondary: navy,
          onSecondary: Colors.white,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: canvas,
          surfaceContainer: sky,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      textTheme: Typography.material2021().black.apply(
        bodyColor: navy,
        displayColor: navy,
      ),
      cardTheme: const CardThemeData(
        elevation: 1,
        shadowColor: Color(0x1A183153),
        color: Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8E5FF),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? blue : navy,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: indigo,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        ),
        selectedIconTheme: IconThemeData(color: Colors.white),
        selectedLabelTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: IconThemeData(color: Color(0xFFB9C4DC)),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFFD6DDF0)),
      ),
    );
  }
}
