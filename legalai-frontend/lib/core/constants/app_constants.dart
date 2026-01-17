class AppConstants {
  static const String appName = 'Legal AI Lawyer';
  // static const String apiBaseUrlDev =
  //     'http://127.0.0.1:5000/api/v1'; // Android Emulator
  // static const String apiBaseUrlProd =
  //     'http://127.0.0.1:5000/api/v1'; // Placeholder
  static const String apiBaseUrlDev =
      'https://unflexible-zora-rostrally.ngrok-free.dev/api/v1'; // Android Emulator
  static const String apiBaseUrlProd =
      'https://unflexible-zora-rostrally.ngrok-free.dev/api/v1'; // Placeholder

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String themeModeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String safeModeKey = 'safe_mode';
}
