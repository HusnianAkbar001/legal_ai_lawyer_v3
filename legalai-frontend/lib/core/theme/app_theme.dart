import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displayLarge),
      displayMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displayMedium),
      displaySmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displaySmall),
      headlineLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineLarge),
      headlineMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineMedium),
      headlineSmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineSmall),
      titleLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleLarge),
      titleMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleMedium),
      titleSmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleSmall),
    );

    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppPalette.primary,
        secondary: AppPalette.secondary,
        tertiary: AppPalette.tertiary,
        surface: AppPalette.surfaceLight,
        error: AppPalette.error,
        background: AppPalette.backgroundLight,
      ),
      scaffoldBackgroundColor: AppPalette.backgroundLight,
      textTheme: textTheme.apply(
        bodyColor: AppPalette.textPrimaryLight,
        displayColor: AppPalette.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.backgroundLight,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppPalette.textPrimaryLight),
        titleTextStyle: TextStyle(
          color: AppPalette.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppPalette.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppPalette.error),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.surfaceLight,
        indicatorColor: AppPalette.primary.withOpacity(0.12),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppPalette.surfaceLight,
        indicatorColor: AppPalette.primary.withOpacity(0.12),
        selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE2E8F0), thickness: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primary,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displayLarge),
      displayMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displayMedium),
      displaySmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.displaySmall),
      headlineLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineLarge),
      headlineMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineMedium),
      headlineSmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.headlineSmall),
      titleLarge: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleLarge),
      titleMedium: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleMedium),
      titleSmall: GoogleFonts.spaceGrotesk(textStyle: base.textTheme.titleSmall),
    );

    return base.copyWith(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppPalette.primary,
        secondary: AppPalette.secondary,
        tertiary: AppPalette.tertiary,
        surface: AppPalette.surfaceDark,
        error: AppPalette.error,
        background: AppPalette.backgroundDark,
      ),
      scaffoldBackgroundColor: AppPalette.backgroundDark,
      textTheme: textTheme.apply(
        bodyColor: AppPalette.textPrimaryDark,
        displayColor: AppPalette.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.backgroundDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppPalette.textPrimaryDark),
        titleTextStyle: TextStyle(
          color: AppPalette.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF23324A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF23324A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppPalette.primary, width: 1.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.surfaceDark,
        indicatorColor: AppPalette.primary.withOpacity(0.2),
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppPalette.surfaceDark,
        indicatorColor: AppPalette.primary.withOpacity(0.2),
        selectedLabelTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.primary,
          side: const BorderSide(color: Color(0xFF23324A)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
