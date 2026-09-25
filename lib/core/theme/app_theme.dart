import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF0A55F4);
  static const primaryDark = Color(0xFF061747);

  static const success = Color(0xFF00A85A);
  static const successDark = Color(0xFF008643);

  static const background = Color(0xFFF8FAFE);
  static const surface = Colors.white;

  static const border = Color(0xFFD9E4F5);

  static const text = Color(0xFF07152F);
  static const muted = Color(0xFF60708B);

  static const lightBlue = Color(0xFFEAF3FF);
  static const lightGreen = Color(0xFFF0FFF6);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primary,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor: background,

      fontFamily: 'Arial',

      splashColor: primary.withOpacity(.06),

      highlightColor: primary.withOpacity(.03),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        headlineSmall: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        titleLarge: TextStyle(
          color: text,
          fontWeight: FontWeight.w900,
        ),
        titleMedium: TextStyle(
          color: text,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: text,
        ),
        bodyMedium: TextStyle(
          color: text,
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(
            color: primary,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE7F0FF),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}