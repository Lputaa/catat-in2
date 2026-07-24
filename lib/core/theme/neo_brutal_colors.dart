import 'package:flutter/material.dart';

/// Neo-Brutalism color tokens for Catat-In
/// Matches Style Guide §2
class NeoBrutalColors {
  NeoBrutalColors._();

  // ── Light Theme Tokens ──
  static const Color bg = Color(0xFFFFFFFF);       // Clean white — scaffold bg
  static const Color ink = Color(0xFF1A1A1A);       // Softer black — text, borders, shadows
  static const Color primary = Color(0xFFFF6B35);   // Burnt orange — CTA, focused
  static const Color secondary = Color(0xFF4361EE); // Electric blue
  static const Color success = Color(0xFF06D6A0);   // Neon green
  static const Color danger = Color(0xFFEF476F);    // Bright red
  static const Color surface = Color(0xFFFFFFFF);   // White — card/panel bg
  static const Color muted = Color(0xFFE5E5E5);     // Grey — disabled, dividers

  // ── Dark Theme Tokens ──
  static const Color bgDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color darkLine = Color(0xFFE0E0E0);
  static const Color inkDark = Color(0xFFF5F5F5);

  // ── Accent Colors ──
  static const Color cyan = Color(0xFF00D9FF);
  static const Color yellow = Color(0xFFFFD60A);
  static const Color green = Color(0xFF06D6A0);
  static const Color purple = Color(0xFFB5179E);
  static const Color orange = Color(0xFFFF9F1C);

  // ── Category Color Map ──
  static const Color categoryKerja = primary;       // #FF6B35
  static const Color categoryBelajar = secondary;   // #4361EE
  static const Color categoryOlahraga = success;    // #06D6A0
  static const Color categoryHiburan = purple;      // #B5179E
  static const Color categoryKeseharian = yellow;   // #FFD60A
  static const Color categorySosial = cyan;         // #00D9FF
  static const Color categoryIbadah = orange;       // #FF9F1C
  static const Color categoryLainnya = muted;       // #E5E5E5

  // ── Financial Category Colors (for budget/transaction) ──
  static const Color income = success;
  static const Color expense = danger;

  // ── Hardcoded Dark Mode ──
  static const Color notesBgLight = Color(0xFFF0F0F0);
  static const Color notesBgDark = Color(0xFF2A2A2A);
  static const Color disabledChipBgDark = Color(0xFF333333);
  static const Color switchInactiveBgDark = Color(0xFF3A3A3A);
  static const Color outlineVariantDark = Color(0xFF363636);
  static const Color chartTooltipBgDark = Color(0xFF2A2A2A);
  static const Color chartGridDark = Color(0xFF2A2A2A);
}
