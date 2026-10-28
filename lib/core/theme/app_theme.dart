import 'package:flutter/material.dart';

/// Sistema de diseño centralizado para ONTA MY MONEY.
/// Gestiona paletas semánticas, tipografía WCAG AA, superficies adaptativas y componentes para modo Claro y Oscuro.
class AppTheme {
  // =========================================================
  // PALETA SEMÁNTICA - MODO CLARO
  // =========================================================
  static const primary = Color(0xFF0A55F4);
  static const primaryDark = Color(0xFF061747);

  static const success = Color(0xFF059669);
  static const successDark = Color(0xFF047857);

  static const warning = Color(0xFFD97706);
  static const warningDark = Color(0xFFB45309);

  static const error = Color(0xFFDC2626);
  static const errorDark = Color(0xFF991B1B);

  static const background = Color(0xFFF8FAFE);
  static const surface = Colors.white;
  static const surfaceElevated = Color(0xFFF1F5F9);

  static const border = Color(0xFFD9E4F5);

  static const text = Color(0xFF07152F);
  // Color muted con contraste >= 4.5:1 sobre fondo claro (#F8FAFE) y blanco (#FFFFFF)
  static const muted = Color(0xFF4A5568);

  static const lightBlue = Color(0xFFEAF3FF);
  static const lightGreen = Color(0xFFF0FFF6);

  static const focus = Color(0xFF061747);

  // =========================================================
  // PALETA SEMÁNTICA - MODO OSCURO
  // =========================================================
  static const backgroundDark = Color(0xFF0B132B);
  static const surfaceDark = Color(0xFF14213D);
  static const surfaceElevatedDark = Color(0xFF1B2C52);

  static const borderDark = Color(0xFF263859);

  static const textDark = Color(0xFFF8FAFC);
  // Color mutedDark con contraste >= 4.5:1 sobre surfaceDark (#14213D) y backgroundDark (#0B132B)
  static const mutedDark = Color(0xFF94A3B8);

  static const primaryDarkTheme = Color(0xFF3B82F6);
  static const successDarkTheme = Color(0xFF34D399);
  static const warningDarkTheme = Color(0xFFFBBF24);
  static const errorDarkTheme = Color(0xFFF87171);

  static const focusDark = Color(0xFF93C5FD);

  // =========================================================
  // HELPERS DE ACCESO SEMÁNTICO SEGÚN CONTEXTO
  // =========================================================
  static bool isDarkMode(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDarkMode(context) ? backgroundDark : background;

  static Color cardBg(BuildContext context) =>
      isDarkMode(context) ? surfaceDark : surface;

  static Color elevatedCardBg(BuildContext context) =>
      isDarkMode(context) ? surfaceElevatedDark : surfaceElevated;

  static Color borderColor(BuildContext context) =>
      isDarkMode(context) ? borderDark : border;

  static Color textColor(BuildContext context) =>
      isDarkMode(context) ? textDark : text;

  static Color mutedColor(BuildContext context) =>
      isDarkMode(context) ? mutedDark : muted;

  static Color primaryColor(BuildContext context) =>
      isDarkMode(context) ? primaryDarkTheme : primary;

  static Color successColor(BuildContext context) =>
      isDarkMode(context) ? successDarkTheme : success;

  static Color warningColor(BuildContext context) =>
      isDarkMode(context) ? warningDarkTheme : warning;

  static Color errorColor(BuildContext context) =>
      isDarkMode(context) ? errorDarkTheme : error;

  static Color focusRingColor(BuildContext context) =>
      isDarkMode(context) ? focusDark : focus;

  // Tonalidades suaves para badges / fondos de íconos
  static Color tintPrimary(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF1E3A8A) : const Color(0xFFEAF3FF);

  static Color tintSuccess(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF0F3A2A) : const Color(0xFFE9FFF2);

  static Color tintWarning(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF3E2703) : const Color(0xFFFFFBEB);

  static Color tintError(BuildContext context) =>
      isDarkMode(context) ? const Color(0xFF3F1218) : const Color(0xFFFEF2F2);

  // =========================================================
  // THEME DATA - LIGHT
  // =========================================================
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: lightBlue,
      onPrimaryContainer: primaryDark,
      secondary: primaryDark,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outline: const Color(0xFF9FB2C8),
      outlineVariant: border,
      error: error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      dividerColor: border,
      fontFamily: 'Arial',
      splashColor: primary.withOpacity(.08),
      highlightColor: primary.withOpacity(.06),
      focusColor: primary.withOpacity(.20),
      hoverColor: primary.withOpacity(.06),
      dividerTheme: const DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1.15),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titleTextStyle: const TextStyle(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: text,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge:
            TextStyle(color: text, fontSize: 28, fontWeight: FontWeight.w900),
        headlineMedium:
            TextStyle(color: text, fontSize: 24, fontWeight: FontWeight.w900),
        headlineSmall:
            TextStyle(color: text, fontSize: 20, fontWeight: FontWeight.w900),
        titleLarge:
            TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w800),
        titleMedium:
            TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w800),
        titleSmall:
            TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: text, fontSize: 16),
        bodyMedium: TextStyle(color: text, fontSize: 14),
        bodySmall: TextStyle(color: muted, fontSize: 12.5),
        labelLarge:
            TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w800),
        labelMedium:
            TextStyle(color: text, fontSize: 12.5, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(
            color: muted, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return primary.withOpacity(.45);
            }
            return primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: focus, width: 3);
            }
            return BorderSide.none;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(primary),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: focus, width: 3);
            }
            return const BorderSide(color: primary, width: 1.5);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(primary),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(text),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: muted, fontSize: 14),
        labelStyle: const TextStyle(color: muted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border, width: 1.15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: focus, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorDark, width: 3),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0xFFE7F0FF),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: text),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: Color(0xFFE7F0FF),
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: muted),
        selectedLabelTextStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: primary),
        unselectedLabelTextStyle:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted),
      ),
    );
  }

  // =========================================================
  // THEME DATA - DARK
  // =========================================================
  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      primary: primaryDarkTheme,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF1E3A8A),
      onPrimaryContainer: const Color(0xFFDBEAFE),
      secondary: const Color(0xFF93C5FD),
      onSecondary: backgroundDark,
      surface: surfaceDark,
      onSurface: textDark,
      onSurfaceVariant: mutedDark,
      outline: const Color(0xFF475569),
      outlineVariant: borderDark,
      error: errorDarkTheme,
      onError: const Color(0xFF450A0A),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundDark,
      cardColor: surfaceDark,
      dividerColor: borderDark,
      fontFamily: 'Arial',
      splashColor: primaryDarkTheme.withOpacity(.12),
      highlightColor: primaryDarkTheme.withOpacity(.08),
      focusColor: primaryDarkTheme.withOpacity(.25),
      hoverColor: primaryDarkTheme.withOpacity(.08),
      dividerTheme: const DividerThemeData(
        color: borderDark,
        space: 1,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1.15),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titleTextStyle: const TextStyle(
          color: textDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          color: textDark,
          fontSize: 14,
          height: 1.45,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            color: textDark, fontSize: 28, fontWeight: FontWeight.w900),
        headlineMedium: TextStyle(
            color: textDark, fontSize: 24, fontWeight: FontWeight.w900),
        headlineSmall: TextStyle(
            color: textDark, fontSize: 20, fontWeight: FontWeight.w900),
        titleLarge: TextStyle(
            color: textDark, fontSize: 18, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(
            color: textDark, fontSize: 16, fontWeight: FontWeight.w800),
        titleSmall: TextStyle(
            color: textDark, fontSize: 14, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: textDark, fontSize: 16),
        bodyMedium: TextStyle(color: textDark, fontSize: 14),
        bodySmall: TextStyle(color: mutedDark, fontSize: 12.5),
        labelLarge: TextStyle(
            color: textDark, fontSize: 14, fontWeight: FontWeight.w800),
        labelMedium: TextStyle(
            color: textDark, fontSize: 12.5, fontWeight: FontWeight.w700),
        labelSmall: TextStyle(
            color: mutedDark, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.disabled)) {
              return primaryDarkTheme.withOpacity(.45);
            }
            return primaryDarkTheme;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: focusDark, width: 3);
            }
            return BorderSide.none;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(primaryDarkTheme),
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(50)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
            if (states.contains(WidgetState.focused)) {
              return const BorderSide(color: focusDark, width: 3);
            }
            return const BorderSide(color: primaryDarkTheme, width: 1.5);
          }),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(primaryDarkTheme),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(textDark),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        hintStyle: const TextStyle(color: mutedDark, fontSize: 14),
        labelStyle: const TextStyle(color: mutedDark, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderDark, width: 1.15),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: focusDark, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorDarkTheme, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFCA5A5), width: 3),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: Color(0xFF1E3A8A),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textDark),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceDark,
        indicatorColor: Color(0xFF1E3A8A),
        selectedIconTheme: IconThemeData(color: primaryDarkTheme),
        unselectedIconTheme: IconThemeData(color: mutedDark),
        selectedLabelTextStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: primaryDarkTheme),
        unselectedLabelTextStyle: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: mutedDark),
      ),
    );
  }
}
