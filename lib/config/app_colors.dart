import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary/Accent
  static const Color accent = Color(0xFF2563EB);


  // Light Mode
  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F5);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color textPrimaryLight = Color(0xFF0F0F0F);
  static const Color textMutedLight = Color(0xFF8A8A8A);

  // Dark Mode
  static const Color bgDark = Color(0xFF0F0F0F);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceElevatedDark = Color(0xFF242424);
  static const Color borderDark = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color textPrimaryDark = Color(0xFFF2F2F0);
  static const Color textMutedDark = Color(0xFF6A6A6A);

  static Color background(bool isDark) => isDark ? bgDark : bgLight;
  static Color surface(bool isDark) => isDark ? surfaceDark : surfaceLight;
  static Color surfaceElevated(bool isDark) => isDark ? surfaceElevatedDark : surfaceElevatedLight;
  static Color border(bool isDark) => isDark ? borderDark : borderLight;
  static Color textPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimaryLight;
  static Color textMuted(bool isDark) => isDark ? textMutedDark : textMutedLight;
}
