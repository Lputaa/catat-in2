import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed settings for theme mode, future backup timestamps, etc.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const _boxName = 'settings';
  static const _themeKey = 'themeMode';
  static const _apiKeyKey = 'claudeApiKey';
  static const _onboardingKey = 'onboarding_completed';

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

  // ── Claude API Key ──
  String? get apiKey {
    final value = _box.get(_apiKeyKey) as String?;
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Future<void> setApiKey(String? key) async {
    if (key == null || key.isEmpty) {
      await _box.delete(_apiKeyKey);
    } else {
      await _box.put(_apiKeyKey, key);
    }
  }

  // ── Onboarding ──
  bool get onboardingCompleted =>
      _box.get(_onboardingKey, defaultValue: false) as bool;

  Future<void> setOnboardingCompleted(bool value) async {
    await _box.put(_onboardingKey, value);
  }
}
