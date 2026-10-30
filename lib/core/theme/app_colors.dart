import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);

  // Priority Colors
  static const Color priorityLow = Color(0xFF64748B);
  static const Color priorityMedium = Color(0xFF3B82F6);
  static const Color priorityHigh = Color(0xFFF59E0B);
  static const Color priorityUrgent = Color(0xFFEF4444);

  // Status Colors
  static const Color statusTodo = Color(0xFF475569);
  static const Color statusTodoBg = Color(0xFFF1F5F9);
  static const Color statusInProgress = Color(0xFF2563EB);
  static const Color statusInProgressBg = Color(0xFFEFF6FF);
  static const Color statusDone = Color(0xFF10B981);
  static const Color statusDoneBg = Color(0xFFECFDF5);
  static const Color statusCancelled = Color(0xFF94A3B8);

  // Adaptive Themes - Calm Mode (Dịu mát)
  static const Color calmPrimary = Color(0xFF0D9488); // Teal 600
  static const Color calmAccent = Color(0xFF14B8A6);
  static const Color calmBackground = Color(0xFFF0FDF4); // Mint 50
  static const Color calmCard = Color(0xFFFFFFFF);

  // Adaptive Themes - Focus Mode (Tập trung - Ấm)
  static const Color focusPrimary = Color(0xFFD97706); // Amber 600
  static const Color focusAccent = Color(0xFFF59E0B);
  static const Color focusBackground = Color(0xFFFFFBEB); // Amber 50
  static const Color focusCard = Color(0xFFFFFFFF);

  // Adaptive Themes - Overload Mode (Quá tải - Đỏ khẩn cấp)
  static const Color overloadPrimary = Color(0xFFDC2626); // Red 600
  static const Color overloadAccent = Color(0xFFEF4444);
  static const Color overloadBackground = Color(0xFFFEF2F2); // Red 50
  static const Color overloadCard = Color(0xFFFFFFFF);
}
