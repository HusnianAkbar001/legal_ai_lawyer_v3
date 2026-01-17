import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_preferences.dart';

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  final box = Hive.box(AppPreferences.boxName);
  return AppPreferences(box);
});

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ref.read(appPreferencesProvider).getThemeMode();
  }

  void setThemeMode(ThemeMode mode) {
    ref.read(appPreferencesProvider).setThemeMode(mode);
    state = mode;
  }
}

final appLanguageProvider =
    NotifierProvider<AppLanguageController, String>(AppLanguageController.new);

class AppLanguageController extends Notifier<String> {
  @override
  String build() {
    return ref.read(appPreferencesProvider).getLanguage();
  }

  void setLanguage(String language) {
    ref.read(appPreferencesProvider).setLanguage(language);
    state = language;
  }
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(appPreferencesProvider).getOnboardingComplete();
  }

  void completeOnboarding() {
    ref.read(appPreferencesProvider).setOnboardingComplete(true);
    state = true;
  }
}

final safeModeProvider =
    NotifierProvider<SafeModeController, bool>(SafeModeController.new);

class SafeModeController extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(appPreferencesProvider).getSafeMode();
  }

  void setSafeMode(bool value) {
    ref.read(appPreferencesProvider).setSafeMode(value);
    state = value;
  }
}
