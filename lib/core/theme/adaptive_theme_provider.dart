import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

// TODO: Implement Logic tự động đổi ThemeData theo backlog
final adaptiveThemeProvider = Provider<ThemeData>((ref) {
  return ThemeData.light(); // Default theme
});
