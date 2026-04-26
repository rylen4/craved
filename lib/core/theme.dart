import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color surface = Color(0xFF0E0E0E);
  static const Color primary = Color(0xFF52F2F5);
  static const Color primaryContainer = Color(0xFF0CD0D3);
  static const Color onPrimary = Color(0xFF003738);
  static const Color surfaceContainerLow = Color(0xFF131313);
  static const Color surfaceContainer = Color(0xFF1A1919);
  static const Color surfaceContainerHigh = Color(0xFF201F1F);
  static const Color surfaceContainerHighest = Color(0xFF262626);
  static const Color outlineVariant = Color(0xFF494847);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1),
        displayMedium: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
        headlineLarge: GoogleFonts.manrope(fontWeight: FontWeight.bold, color: Colors.white),
        bodyLarge: GoogleFonts.inter(color: Colors.white70),
        bodyMedium: GoogleFonts.inter(color: Colors.white60),
      ),
    );
  }
}
