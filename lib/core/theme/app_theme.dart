import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'adaptive_theme_provider.dart';
import 'app_colors.dart';

/// Quản lý Global Theme của toàn ứng dụng (Design System).
/// Chuẩn Production-Ready, hỗ trợ cả Light Mode và Dark Mode mượt mà.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _createTheme(
        primaryColor: AppColors.priorityMedium,
        backgroundColor: AppColors.background,
        cardColor: AppColors.surface,
        isDark: false,
      );

  static ThemeData get darkTheme => _createTheme(
        primaryColor: AppColors.priorityMedium,
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        cardColor: const Color(0xFF1E293B), // Slate 800
        isDark: true,
      );

  static ThemeData getAdaptiveTheme({
    required AdaptiveMode mode,
    required bool isDark,
  }) {
    Color primaryColor;
    Color backgroundColor;
    Color cardColor;

    if (isDark) {
      backgroundColor = const Color(0xFF0B1120); // Darker Slate
      cardColor = const Color(0xFF1E293B);

      switch (mode) {
        case AdaptiveMode.calm:
          primaryColor = AppColors.calmAccent;
          break;
        case AdaptiveMode.focus:
          primaryColor = AppColors.focusAccent;
          break;
        case AdaptiveMode.overload:
          primaryColor = AppColors.overloadAccent;
          break;
      }
    } else {
      switch (mode) {
        case AdaptiveMode.calm:
          primaryColor = AppColors.calmPrimary;
          backgroundColor = AppColors.calmBackground;
          cardColor = AppColors.calmCard;
          break;
        case AdaptiveMode.focus:
          primaryColor = AppColors.focusPrimary;
          backgroundColor = AppColors.focusBackground;
          cardColor = AppColors.focusCard;
          break;
        case AdaptiveMode.overload:
          primaryColor = AppColors.overloadPrimary;
          backgroundColor = AppColors.overloadBackground;
          cardColor = AppColors.overloadCard;
          break;
      }
    }

    return _createTheme(
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      cardColor: cardColor,
      isDark: isDark,
    );
  }

  static ThemeData _createTheme({
    required Color primaryColor,
    required Color backgroundColor,
    required Color cardColor,
    required bool isDark,
  }) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        surface: backgroundColor,
      ),

      // 1. Typography
      textTheme: TextTheme(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: secondaryTextColor,
        ),
      ),

      // 2. Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white : primaryColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // 3. Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // 4. Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        hintStyle: TextStyle(color: secondaryTextColor),
      ),

      // 5. FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // 6. Drawer
      drawerTheme: DrawerThemeData(
        backgroundColor: cardColor,
        elevation: 0,
      ),
    );
  }
}
