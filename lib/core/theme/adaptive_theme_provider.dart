import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

// TODO: Implement Logic tự động đổi ThemeData theo backlog
final adaptiveThemeProvider = Provider<ThemeData>((ref) {
  return AppTheme.lightTheme; // Sử dụng Global Theme chuẩn
});
