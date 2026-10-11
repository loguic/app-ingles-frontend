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
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
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

  static ThemeData get dark {
    const midnight = Color(0xFF090D1C);
    const deepSurface = Color(0xFF121A32);
    const raisedSurface = Color(0xFF1A2542);
    const electricBlue = Color(0xFF5E8CFF);
    const electricViolet = Color(0xFF9A7CFF);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: electricBlue,
          brightness: Brightness.dark,
          surface: deepSurface,
        ).copyWith(
          primary: electricBlue,
          onPrimary: midnight,
          secondary: electricViolet,
          tertiary: const Color(0xFF6BE5B2),
          surfaceContainerLowest: midnight,
          surfaceContainerLow: deepSurface,
          surfaceContainer: raisedSurface,
          outlineVariant: const Color(0xFF303E62),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: midnight,
      textTheme: Typography.material2021().white.apply(
        bodyColor: const Color(0xFFF1F5FF),
        displayColor: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: deepSurface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: midnight,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
