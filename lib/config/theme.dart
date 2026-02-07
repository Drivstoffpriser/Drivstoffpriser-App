import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _nordicBlue = Color(0xFF1A5276);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _nordicBlue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _nordicBlue,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
