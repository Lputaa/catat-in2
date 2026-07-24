import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'neo_brutal_colors.dart';
import '../constants/app_constants.dart';

/// Full ThemeData for Catat-In Neo-Brutalism
/// Matches Style Guide §3 (typography), §6 (border), §10 (UI patterns)
class NeoBrutalTheme {
  NeoBrutalTheme._();

  // ── Light Theme ──
  static ThemeData light() {
    final textTheme = _buildTextTheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: NeoBrutalColors.primary,
        secondary: NeoBrutalColors.secondary,
        surface: NeoBrutalColors.surface,
        error: NeoBrutalColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: NeoBrutalColors.ink,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: NeoBrutalColors.ink,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoBrutalColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: NeoBrutalColors.ink,
            width: AppConstants.borderPrimary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: NeoBrutalColors.ink,
            width: AppConstants.borderPrimary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: NeoBrutalColors.primary,
            width: AppConstants.borderPrimary,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NeoBrutalColors.ink,
        thickness: AppConstants.borderPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NeoBrutalColors.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSnackBar),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Dark Theme ──
  static ThemeData dark() {
    final textTheme = _buildTextTheme(Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: NeoBrutalColors.primary,
        secondary: NeoBrutalColors.secondary,
        surface: NeoBrutalColors.surfaceDark,
        error: NeoBrutalColors.danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: NeoBrutalColors.inkDark,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: NeoBrutalColors.bgDark,
        foregroundColor: NeoBrutalColors.inkDark,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NeoBrutalColors.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: NeoBrutalColors.darkLine,
            width: AppConstants.borderPrimary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: NeoBrutalColors.darkLine,
            width: AppConstants.borderPrimary,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: const BorderSide(
            color: NeoBrutalColors.primary,
            width: AppConstants.borderPrimary,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NeoBrutalColors.darkLine,
        thickness: AppConstants.borderPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NeoBrutalColors.surfaceDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: NeoBrutalColors.inkDark,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusSnackBar),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // ── Typography (Style Guide §3) ──
  static TextTheme _buildTextTheme(Brightness brightness) {
    final Color textColor = brightness == Brightness.light
        ? NeoBrutalColors.ink
        : NeoBrutalColors.inkDark;

    return TextTheme(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: 0,
        color: textColor,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.05,
        letterSpacing: 0,
        color: textColor,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: textColor,
      ),
      labelLarge: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textColor,
      ),
      labelMedium: GoogleFonts.spaceGrotesk(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: textColor,
      ),
      labelSmall: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: textColor,
      ),
    );
  }

  // ── Helper: border color by theme ──
  static Color borderColor(Brightness brightness) =>
      brightness == Brightness.light ? NeoBrutalColors.ink : NeoBrutalColors.darkLine;

  // ── Helper: hard shadow ──
  static List<BoxShadow> hardShadow({
    Offset offset = AppConstants.shadowDefault,
    Brightness brightness = Brightness.light,
  }) {
    return [
      BoxShadow(
        color: brightness == Brightness.light
            ? NeoBrutalColors.ink
            : Colors.black,
        offset: offset,
        blurRadius: 0,
      ),
    ];
  }
}
