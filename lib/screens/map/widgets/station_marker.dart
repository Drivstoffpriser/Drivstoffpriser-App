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

import '../../../config/app_colors.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../models/current_price.dart';
import '../../../models/station.dart';
import '../../../widgets/brand_logo.dart';

class StationMarker extends StatefulWidget {
  final Station station;
  final CurrentPrice? price;
  final bool isBestPrice;
  final bool isLoadingPrice;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.price,
    this.isBestPrice = false,
    this.isLoadingPrice = false,
    required this.onTap,
  });

  @override
  State<StationMarker> createState() => _StationMarkerState();
}

class _StationMarkerState extends State<StationMarker> {
  bool _isPressed = false;

  static final Map<String, String> _brandLogoAssets = {
    'Automat1': 'assets/logos/automat1.png',
    'Circle K': 'assets/logos/circle-k.png',
    'Esso': 'assets/logos/esso.png',
    'Shell': 'assets/logos/shell.png',
    'YX': 'assets/logos/yx.png',
    'Uno-X': 'assets/logos/uno-x.png',
    'St1': 'assets/logos/st1.png',
    'YX Truck': 'assets/logos/yx-truck.png',
    'Tanken': 'assets/logos/tanken.png',
    'Bunker Oil': 'assets/logos/bunker.png',
  };

  String? _getLogoAsset() {
    final brand = widget.station.brand;
    if (brand.isEmpty) return null;
    return _brandLogoAssets[brand];
  }

  String? _getRemoteLogoUrl() {
    final brand = widget.station.brand;
    if (brand.isEmpty) return null;
    return BrandLogo.remoteLogoUrl(brand);
  }

  Widget _buildBrandImage(
    BuildContext context, {
    required double size,
    BoxFit fit = BoxFit.contain,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    final logoAsset = _getLogoAsset();
    final remoteUrl = _getRemoteLogoUrl();

    if (remoteUrl != null) {
      return ClipOval(
        child: Padding(
          padding: padding,
          child: Image.network(
            remoteUrl,
            width: size,
            height: size,
            fit: fit,
            errorBuilder: (_, _, _) => logoAsset != null
                ? Image.asset(
                    logoAsset,
                    fit: fit,
                    errorBuilder: (_, _, _) => _buildFallbackLogo(context),
                  )
                : _buildFallbackLogo(context),
          ),
        ),
      );
    }

    if (logoAsset != null) {
      return ClipOval(
        child: Padding(
          padding: padding,
          child: Image.asset(
            logoAsset,
            fit: fit,
            errorBuilder: (_, _, _) => _buildFallbackLogo(context),
          ),
        ),
      );
    }

    return _buildFallbackLogo(context);
  }

  /// Format age label and pick color:
  /// - <1hr → "3m", "25m" etc. green
  /// - 1–5hr → "1hr", "2hr" etc. green
  /// - 6–12hr → yellow/orange
  /// - 13–23hr → red
  /// - 24hr+ → ">1d" gray
  static ({String label, Color color}) _formatAge(
    BuildContext context,
    Duration age,
  ) {
    final minutes = age.inMinutes;
    final hours = age.inHours;

    final color = AppColors.freshness(age);
    if (minutes < 60) {
      return (label: context.l10n.ageMinutes(minutes), color: color);
    }
    if (hours <= 23) {
      return (label: context.l10n.ageHours(hours), color: color);
    }
    return (label: context.l10n.ageOver1Day, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: _buildLogoWithPrice(context),
      ),
    );
  }

  /// Logo circle with freshness-colored border, time badge, and price tag.
  Widget _buildLogoWithPrice(BuildContext context) {
    final price = widget.price;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color borderColor;
    final String? ageLabel;
    if (price == null || price.isEstimate) {
      borderColor = AppColors.border(context);
      ageLabel = null;
    } else {
      final age = DateTime.now().difference(price.updatedAt!);
      final formatted = _formatAge(context, age);
      borderColor = formatted.color;
      ageLabel = formatted.label;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo circle with freshness-colored border
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(context),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: _buildBrandImage(
                context,
                size: 34,
                padding: const EdgeInsets.all(3),
              ),
            ),
            // Time badge — top right
            if (ageLabel != null)
              Positioned(
                top: -4,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ageLabel,
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else if (price != null && price.isEstimate)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_mark_rounded,
                    size: 9,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        // Price tag — always visible. Shows price when loaded, a spinner
        // while fetching, and a dash placeholder when the backend has no
        // price for this station.
        _buildPricePill(context, price, isDark),
      ],
    );
  }

  Widget _buildPricePill(
    BuildContext context,
    CurrentPrice? price,
    bool isDark,
  ) {
    final hasPrice = price != null;
    final highlight = widget.isBestPrice && hasPrice;
    final textColor = highlight
        ? (isDark ? AppColors.darkBackground : Colors.white)
        : AppColors.textPrimary(context);

    // Min width so the pill is at least wide enough to fit a two-decimal
    // price like "99.99" with the star prefix for best-price.
    const pillMinWidth = 44.0;

    return Container(
      constraints: const BoxConstraints(minWidth: pillMinWidth),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primaryContainer(context)
            : (isDark ? AppColors.darkSurfaceHigh : Colors.white),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? AppColors.primaryContainer(context)
              : AppColors.border(context),
          width: highlight ? 1 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? AppColors.primaryContainer(context).withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: highlight ? 8 : 4,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasPrice) ...[
            if (highlight && !price.isEstimate)
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(Icons.star_rounded, size: 10, color: textColor),
              ),
            Text(
              price.price.toStringAsFixed(2),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ] else if (widget.isLoadingPrice)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.textMuted(context),
              ),
            )
          else
            Text(
              '—',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    final brand = widget.station.brand.isNotEmpty ? widget.station.brand : '?';
    final initials = brand.length > 2
        ? brand.substring(0, 2).toUpperCase()
        : brand.toUpperCase();
    final activeColor = AppColors.primaryContainer(context);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            activeColor.withValues(alpha: 0.12),
            activeColor.withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activeColor,
          ),
        ),
      ),
    );
  }
}
