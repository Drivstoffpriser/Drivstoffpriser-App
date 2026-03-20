import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headlines use Space Grotesk
  static TextStyle heading(BuildContext context) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle title(BuildContext context) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  // Body/label styles use Inter
  static TextStyle body(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle label(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  static TextStyle labelBold(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle meta(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  static TextStyle priceLarge(BuildContext context) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle priceMedium(BuildContext context) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle priceSmall(BuildContext context) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle stationName(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle chipLabel(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle navLabel(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }

  static TextStyle navLabelActive(BuildContext context) {
    return GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF00d1ff),
    );
  }

  // Section header style for uppercase labels
  static TextStyle sectionHeader(BuildContext context) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
    );
  }
}
