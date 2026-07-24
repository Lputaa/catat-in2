import 'package:flutter/material.dart';

/// Spacing, border, shadow constants from Style Guide §4-6
class AppConstants {
  AppConstants._();

  // ── Border ──
  static const double borderPrimary = 3.0;
  static const double borderSecondary = 2.0;
  static const double borderTertiary = 1.0;

  // ── Border Radius Exceptions (§1) ──
  static const double radiusDialog = 20.0;
  static const double radiusTemplateCard = 16.0;
  static const double radiusChip = 20.0;
  static const double radiusSnackBar = 12.0;

  // ── Shadow Presets (§5) ──
  static const Offset shadowDefault = Offset(6, 6);
  static const Offset shadowSmall = Offset(4, 4);
  static const Offset shadowLarge = Offset(8, 8);

  // ── Spacing (§4) ──
  static const double spacing4 = 4.0;
  static const double spacing6 = 6.0;
  static const double spacing8 = 8.0;
  static const double spacing10 = 10.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // ── Widget Sizing ──
  static const double buttonMinHeight = 48.0;
  static const double navBarHeight = 60.0;
  static const double iconBoxSize = 42.0;
  static const double iconBoxIconSize = 20.0;

  // ── Animation Durations (§8) ──
  static const Duration animButton = Duration(milliseconds: 100);
  static const Duration animLogo = Duration(milliseconds: 1200);
  static const Duration animProgress = Duration(milliseconds: 1200);
  static const Duration animToggle = Duration(milliseconds: 200);
  static const Duration animSegmented = Duration(milliseconds: 150);
}
