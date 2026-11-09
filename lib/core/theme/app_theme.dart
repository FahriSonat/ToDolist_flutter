import 'package:flutter/material.dart';

/// Priority Todo tasarım tokenları ve tema kuralları (design.md & architucture.md)
class AppTheme {
  AppTheme._();

  // Tasarım Tokenları
  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceRaised = Color(0xFF1C1C1E);
  static const Color divider = Color(0xFF2C2C2E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B5);
  static const Color textDone = Color(0xFF929297);

  static const Color priorityLow = Color(0xFF64B5F6);
  static const Color priorityNormal = Color(0xFFE0E0E0);
  static const Color priorityHigh = Color(0xFFFFB74D);
  static const Color priorityCritical = Color(0xFFFF5252);

  static const double pagePadding = 16.0;
  static const double cardPadding = 16.0;
  static const double borderRadius = 12.0;
  static const double minTouchTarget = 48.0;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: surface,
        primary: textPrimary,
        onPrimary: background,
        secondary: surfaceRaised,
        onSecondary: textPrimary,
        error: priorityCritical,
        outline: divider,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: divider, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return textPrimary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(background),
        side: const BorderSide(color: textSecondary, width: 1.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: divider),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: textPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: priorityCritical),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 15),
        labelStyle: const TextStyle(color: textSecondary),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 15),
        bodySmall: TextStyle(color: textSecondary, fontSize: 13),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: textPrimary,
          foregroundColor: background,
          elevation: 0,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: textPrimary,
        foregroundColor: background,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }
}
