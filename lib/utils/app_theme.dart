import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/settings_controller.dart';
import '../config/app_config.dart';

class AppColors {
  // Helper to check if dark mode is active
  static bool get isDark {
    try {
      final settings = Get.find<SettingsController>();
      if (settings.themeMode.value == ThemeMode.system) {
        return Get.isDarkMode;
      }
      return settings.themeMode.value == ThemeMode.dark;
    } catch (_) {
      return Get.isDarkMode;
    }
  }

  // Main Theme Colors
  static const Color primary = AppConfig.primaryColor;
  static Color get background =>
      isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
  static Color get accent => const Color(0xFF60A5FA);

  // Card & Section Colors
  static Color get cardBg => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  static Color get white => isDark ? const Color(0xFF2C2C2C) : Colors.white;

  // Text Colors
  static Color get textMain =>
      isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  static LinearGradient get headerGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary.withValues(alpha: 0.4), background.withValues(alpha: 0.2)],
  );
}

class AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF0F172A)),
      bodyMedium: TextStyle(color: Color(0xFF0F172A)),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: const Color(0xFF121212),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF121212),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF1F5F9)),
      bodyMedium: TextStyle(color: Color(0xFFF1F5F9)),
    ),
  );
}

class AppTextStyles {
  static TextStyle get h1 => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
    height: 1.2,
  );

  static TextStyle get h2 => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textMain,
  );

  static TextStyle get h3 => TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );

  static TextStyle get h4 => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );

  static TextStyle get bodyLarge =>
      TextStyle(fontSize: 16, color: AppColors.textMain);

  static TextStyle get bodyMedium =>
      TextStyle(fontSize: 14, color: AppColors.textSecondary);

  static TextStyle get bodySmall =>
      TextStyle(fontSize: 12, color: AppColors.textSecondary);

  static TextStyle get label => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}

///fontWeight: 400
TextStyle normalTextStyle = GoogleFonts.raleway(fontWeight: FontWeight.w400);

///fontWeight: 700
TextStyle boldTextStyle = GoogleFonts.raleway(fontWeight: FontWeight.w700);
