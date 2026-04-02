/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Dark palette (cyberpunk navy/cyan) ──
  static const Color darkBackground = Color(0xFF0b1326);
  static const Color darkSurface = Color(0xFF171f33);
  static const Color darkSurfaceLow = Color(0xFF131b2e);
  static const Color darkSurfaceHigh = Color(0xFF222a3d);
  static const Color darkSurfaceHighest = Color(0xFF2d3449);
  static const Color darkSurfaceLowest = Color(0xFF060e20);
  static const Color darkOnSurface = Color(0xFFdae2fd);
  static const Color darkOnSurfaceVariant = Color(0xFFbbc9cf);
  static const Color darkPrimary = Color(0xFFa4e6ff);
  static const Color darkPrimaryContainer = Color(0xFF00d1ff);
  static const Color darkSecondary = Color(0xFFb9c7e0);
  static const Color darkOutlineVariant = Color(0xFF3c494e);
  static const Color darkError = Color(0xFFffb4ab);

  // ── Light palette ──
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLow = Color(0xFFF3F4F5);
  static const Color lightSurfaceHigh = Color(0xFFE8EAED);
  static const Color lightOnSurface = Color(0xFF191c1d);
  static const Color lightPrimary = Color(0xFF003f87);
  static const Color lightPrimaryContainer = Color(0xFF0056b3);
  static const Color lightSecondary = Color(0xFF006e25);

  // ── Accent (bright cyan) ──
  static const Color accent = Color(0xFF00d1ff);

  // ── Context-aware helpers ──
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color background(BuildContext context) =>
      _isDark(context) ? darkBackground : lightBackground;

  static Color surface(BuildContext context) =>
      _isDark(context) ? darkSurface : lightSurface;

  static Color surfaceElevated(BuildContext context) =>
      _isDark(context) ? darkSurfaceHigh : lightSurface;

  static Color surfaceLow(BuildContext context) =>
      _isDark(context) ? darkSurfaceLow : lightSurfaceLow;

  static Color border(BuildContext context) =>
      _isDark(context) ? darkOutlineVariant : const Color(0xFFDDE1E6);

  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? darkOnSurface : lightOnSurface;

  static Color textMuted(BuildContext context) =>
      _isDark(context) ? darkOnSurfaceVariant : const Color(0xFF6B7280);

  static Color pillNavBackground(BuildContext context) =>
      _isDark(context) ? darkSurfaceLow : lightSurface;

  static Color primary(BuildContext context) =>
      _isDark(context) ? darkPrimary : lightPrimary;

  static Color primaryContainer(BuildContext context) =>
      _isDark(context) ? darkPrimaryContainer : lightPrimaryContainer;

  /// Color indicating how fresh a price update is.
  static Color freshness(Duration age) {
    final hours = age.inHours;
    if (hours <= 5) return Colors.green;
    if (hours <= 12) return Colors.orange;
    if (hours <= 23) return Colors.red;
    return Colors.grey;
  }
}
