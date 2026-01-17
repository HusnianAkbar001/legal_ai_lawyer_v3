import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_palette.dart';

class AdminColors {
  static const Color primary = Color(0xFF22D3EE);
  static const Color accent = Color(0xFF38BDF8);
  static const Color background = Color(0xFF0B0D12);
  static const Color surface = Color(0xFF12161E);
  static const Color surfaceAlt = Color(0xFF1B2230);
  static const Color border = Color(0xFF273142);
  static const Color textPrimary = AppPalette.textPrimaryDark;
  static const Color textSecondary = AppPalette.textSecondaryDark;
  static const Color success = AppPalette.success;
  static const Color warning = AppPalette.warning;
  static const Color error = AppPalette.error;
  static const Color info = AppPalette.info;
}

class AdminTheme {
  static ThemeData get dark {
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
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.primary,
        secondary: AdminColors.accent,
        background: AdminColors.background,
        surface: AdminColors.surface,
        error: AdminColors.error,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: textTheme.apply(
        bodyColor: AdminColors.textPrimary,
        displayColor: AdminColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AdminColors.textPrimary,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textPrimary,
          side: const BorderSide(color: AdminColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.surfaceAlt,
        selectedColor: AdminColors.primary.withOpacity(0.16),
        labelStyle: const TextStyle(color: AdminColors.textPrimary),
        side: const BorderSide(color: AdminColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AdminColors.surface,
        selectedIconTheme: const IconThemeData(color: AdminColors.primary),
        unselectedIconTheme: const IconThemeData(color: AdminColors.textSecondary),
        selectedLabelTextStyle: const TextStyle(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: const TextStyle(color: AdminColors.textSecondary),
        indicatorColor: AdminColors.primary.withOpacity(0.16),
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get light => dark;
}
