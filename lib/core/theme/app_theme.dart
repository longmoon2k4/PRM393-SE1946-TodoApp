import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Quản lý Global Theme của toàn ứng dụng (Design System).
/// Ép khuôn tất cả các thư viện và Widget mặc định tuân thủ theo 1 thiết kế chung.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _createTheme(
        primaryColor: AppColors.priorityMedium,
        backgroundColor: AppColors.background,
        cardColor: AppColors.surface,
      );

  static ThemeData get calmTheme => _createTheme(
        primaryColor: AppColors.calmPrimary,
        backgroundColor: AppColors.calmBackground,
        cardColor: AppColors.calmCard,
      );

  static ThemeData get focusTheme => _createTheme(
        primaryColor: AppColors.focusPrimary,
        backgroundColor: AppColors.focusBackground,
        cardColor: AppColors.focusCard,
      );

  static ThemeData get overloadTheme => _createTheme(
        primaryColor: AppColors.overloadPrimary,
        backgroundColor: AppColors.overloadBackground,
        cardColor: AppColors.overloadCard,
      );

  static ThemeData _createTheme({
    required Color primaryColor,
    required Color backgroundColor,
    required Color cardColor,
  }) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        surface: backgroundColor,
      ),

      // 1. Ép khuôn Font chữ (Typography)
      textTheme: TextTheme(
        titleLarge:
            baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium:
            baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: baseTextTheme.bodyLarge
            ?.copyWith(color: const Color(0xFF334155)), // Slate 700
      ),

      // 2. Ép khuôn Nút bấm (Buttons)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: AppColors.divider),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // 3. Ép khuôn Thẻ (Cards)
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // 4. Ép khuôn Ô nhập liệu (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),

      // 5. Ép khuôn Nút FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // 6. Ép khuôn Menu trượt (Drawer)
      drawerTheme: DrawerThemeData(
        backgroundColor: cardColor,
        elevation: 0,
      ),
    );
  }
}
