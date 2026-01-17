import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

class AppPreferences {
  static const String boxName = 'app_prefs';

  final Box _box;

  AppPreferences(this._box);

  static Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
  }

  ThemeMode getThemeMode() {
    final raw = _box.get(AppConstants.themeModeKey) as String?;
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void setThemeMode(ThemeMode mode) {
    _box.put(AppConstants.themeModeKey, _themeModeToString(mode));
  }

  String getLanguage() {
    final raw = _box.get(AppConstants.languageKey) as String?;
    if (raw == 'ur') return 'ur';
    return 'en';
  }

  void setLanguage(String language) {
    final value = language == 'ur' ? 'ur' : 'en';
    _box.put(AppConstants.languageKey, value);
  }

  bool getOnboardingComplete() {
    final raw = _box.get(AppConstants.onboardingCompleteKey);
    return raw is bool ? raw : false;
  }

  void setOnboardingComplete(bool value) {
    _box.put(AppConstants.onboardingCompleteKey, value);
  }

  bool getSafeMode() {
    final raw = _box.get(AppConstants.safeModeKey);
    return raw is bool ? raw : false;
  }

  void setSafeMode(bool value) {
    _box.put(AppConstants.safeModeKey, value);
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
      default:
        return 'system';
    }
  }
}
