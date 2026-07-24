import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed settings for theme mode, future backup timestamps, etc.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // ── Theme Mode ──
  ThemeMode get themeMode {
    final value = _box.get(_themeKey, defaultValue: 'system') as String;
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(_themeKey, mode.name);
  }
}
