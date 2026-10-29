import 'package:flutter/material.dart';

/// Hệ thống chuẩn hóa Kích thước và Khoảng cách (Spacing & Sizing).
/// Bắt buộc dùng các hằng số này thay vì gõ số cứng (hardcode) trong UI.
class AppSizes {
  AppSizes._();

  // --- 1. Spacing (Padding, Margin) ---
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;   // Khoảng cách chuẩn mặc định (Default padding)
  static const double p20 = 20.0;
  static const double p24 = 24.0;   // Khoảng cách Lớn (Screen margin)
  static const double p32 = 32.0;
  static const double p48 = 48.0;
  static const double p64 = 64.0;

  // --- 2. Radius (Bo góc) ---
  static const Radius radius4 = Radius.circular(4.0);
  static const Radius radius8 = Radius.circular(8.0);
  static const Radius radius12 = Radius.circular(12.0); // Bo góc mặc định cho Button/TextField
  static const Radius radius16 = Radius.circular(16.0); // Bo góc mặc định cho Card/Dialog
  static const Radius radius24 = Radius.circular(24.0);
  static const Radius radiusMax = Radius.circular(999.0); // Hình tròn (Pill shape)

  static const BorderRadius br4 = BorderRadius.all(radius4);
  static const BorderRadius br8 = BorderRadius.all(radius8);
  static const BorderRadius br12 = BorderRadius.all(radius12);
  static const BorderRadius br16 = BorderRadius.all(radius16);
  static const BorderRadius brMax = BorderRadius.all(radiusMax);

  // --- 3. Icon Sizes ---
  static const double iconSmall = 16.0;
  static const double iconNormal = 24.0;
  static const double iconLarge = 32.0;
}
