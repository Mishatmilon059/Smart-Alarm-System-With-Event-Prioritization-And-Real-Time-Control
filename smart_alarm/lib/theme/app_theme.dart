import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static bool isDark = true;

  // Core palette
  static Color get background => isDark ? const Color(0xFF0E0E0F) : const Color(0xFFF8FAFC);
  static Color get surface => isDark ? const Color(0xFF0E0E0F) : const Color(0xFFFFFFFF);
  static Color get surfaceContainerLowest => isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get surfaceContainerLow => isDark ? const Color(0xFF131314) : const Color(0xFFF1F5F9);
  static Color get surfaceContainer => isDark ? const Color(0xFF1A191B) : const Color(0xFFE2E8F0);
  static Color get surfaceContainerHigh => isDark ? const Color(0xFF201F21) : const Color(0xFFCBD5E1);
  static Color get surfaceContainerHighest => isDark ? const Color(0xFF262627) : const Color(0xFF94A3B8);
  static Color get surfaceVariant => isDark ? const Color(0xFF262627) : const Color(0xFFE2E8F0);
  static Color get surfaceBright => isDark ? const Color(0xFF2C2C2D) : const Color(0xFFFFFFFF);

  // Accent colors
  static Color get primary => isDark ? const Color(0xFF39FF14) : const Color(0xFF059669); 
  static Color get primaryDim => isDark ? const Color(0xFF32CD32) : const Color(0xFF10B981);
  static Color get secondary => isDark ? const Color(0xFF39FF14) : const Color(0xFF059669);
  static Color get tertiary => isDark ? const Color(0xFFBF5AF2) : const Color(0xFF7C3AED);
  static Color get alertRed => isDark ? const Color(0xFFFF0000) : const Color(0xFFDC2626);
  static Color get error => isDark ? const Color(0xFFBF5AF2) : const Color(0xFF7C3AED);

  // Text colors
  static Color get onSurface => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  static Color get onSurfaceVariant => isDark ? const Color(0xFFADAAAB) : const Color(0xFF475569);
  static Color get onBackground => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);
  static Color get slateText => isDark ? const Color(0xFF64748B) : const Color(0xFF64748B);
  static Color get outline => isDark ? const Color(0xFF767576) : const Color(0xFF94A3B8);
  static Color get outlineVariant => isDark ? const Color(0xFF484849) : const Color(0xFFCBD5E1);

  // Semantic
  static Color get secondaryContainer => isDark ? const Color(0xFF006E24) : const Color(0xFFD1FAE5);
  static Color get onSecondary => isDark ? const Color(0xFF005219) : const Color(0xFF065F46);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme(
        brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
        onSurface: AppColors.onSurface,
        onPrimary: const Color(0xFF004A5D),
        onSecondary: AppColors.onSecondary,
        onError: const Color(0xFF31004A),
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
      textTheme: GoogleFonts.interTextTheme(
        AppColors.isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
