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

  // =========================================================
  // ACCESIBILIDAD - FOCO
  // =========================================================

  static const focus = Color(0xFF061747);

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

      // =======================================================
      // ESTADOS GENERALES
      // =======================================================

      splashColor: primary.withOpacity(.08),

      highlightColor: primary.withOpacity(.06),

      // Foco más perceptible para navegación mediante teclado.
      focusColor: primary.withOpacity(.22),

      hoverColor: primary.withOpacity(.08),

      // =======================================================
      // TEXTOS
      // =======================================================

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

      // =======================================================
      // APP BAR
      // =======================================================

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      // =======================================================
      // BOTONES PRINCIPALES
      // =======================================================

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.disabled,
              )) {
                return primary.withOpacity(.45);
              }

              return primary;
            },
          ),

          foregroundColor:
              const WidgetStatePropertyAll(
            Colors.white,
          ),

          minimumSize:
              const WidgetStatePropertyAll(
            Size.fromHeight(54),
          ),

          elevation:
              const WidgetStatePropertyAll(0),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),

          textStyle:
              const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Foco claramente visible.
          side:
              WidgetStateProperty.resolveWith<
                  BorderSide?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return const BorderSide(
                  color: focus,
                  width: 3,
                );
              }

              return BorderSide.none;
            },
          ),

          overlayColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return Colors.white.withOpacity(.18);
              }

              if (states.contains(
                WidgetState.hovered,
              )) {
                return Colors.white.withOpacity(.08);
              }

              if (states.contains(
                WidgetState.pressed,
              )) {
                return Colors.white.withOpacity(.12);
              }

              return null;
            },
          ),
        ),
      ),

      // =======================================================
      // BOTONES OUTLINED
      // =======================================================

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(
            primary,
          ),

          minimumSize:
              const WidgetStatePropertyAll(
            Size.fromHeight(52),
          ),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),

          textStyle:
              const WidgetStatePropertyAll(
            TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          side:
              WidgetStateProperty.resolveWith<
                  BorderSide?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return const BorderSide(
                  color: focus,
                  width: 3,
                );
              }

              return const BorderSide(
                color: primary,
                width: 1.5,
              );
            },
          ),

          overlayColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return primary.withOpacity(.15);
              }

              if (states.contains(
                WidgetState.hovered,
              )) {
                return primary.withOpacity(.07);
              }

              return null;
            },
          ),
        ),
      ),

      // =======================================================
      // TEXT BUTTONS
      // =======================================================

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(
            primary,
          ),

          overlayColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return primary.withOpacity(.18);
              }

              if (states.contains(
                WidgetState.hovered,
              )) {
                return primary.withOpacity(.08);
              }

              return null;
            },
          ),

          side:
              WidgetStateProperty.resolveWith<
                  BorderSide?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return const BorderSide(
                  color: focus,
                  width: 2,
                );
              }

              return BorderSide.none;
            },
          ),

          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(10),
            ),
          ),
        ),
      ),

      // =======================================================
      // ICON BUTTONS
      // =======================================================

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor:
              const WidgetStatePropertyAll(
            text,
          ),

          overlayColor:
              WidgetStateProperty.resolveWith<Color?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return primary.withOpacity(.20);
              }

              if (states.contains(
                WidgetState.hovered,
              )) {
                return primary.withOpacity(.08);
              }

              return null;
            },
          ),

          side:
              WidgetStateProperty.resolveWith<
                  BorderSide?>(
            (states) {
              if (states.contains(
                WidgetState.focused,
              )) {
                return const BorderSide(
                  color: focus,
                  width: 2.5,
                );
              }

              return BorderSide.none;
            },
          ),

          shape:
              const WidgetStatePropertyAll(
            CircleBorder(),
          ),
        ),
      ),

      // =======================================================
      // CAMPOS DE TEXTO
      // =======================================================

      inputDecorationTheme: InputDecorationTheme(
        filled: true,

        fillColor: Colors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: border,
            width: 1,
          ),
        ),

        // El campo enfocado ahora tiene un borde
        // considerablemente más visible.
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: focus,
            width: 3,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade700,
            width: 1.5,
          ),
        ),

        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.red.shade900,
            width: 3,
          ),
        ),
      ),

      // =======================================================
      // NAVEGACIÓN INFERIOR
      // =======================================================

      navigationBarTheme:
          const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor:
            Color(0xFFE7F0FF),
        elevation: 0,
        height: 68,
        labelTextStyle:
            WidgetStatePropertyAll(
          TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}