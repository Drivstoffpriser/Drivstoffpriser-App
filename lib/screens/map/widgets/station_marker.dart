import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../models/current_price.dart';
import '../../../models/station.dart';

class StationMarker extends StatefulWidget {
  final Station station;
  final CurrentPrice? price;
  final bool isBestPrice;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.price,
    this.isBestPrice = false,
    required this.onTap,
  });

  @override
  State<StationMarker> createState() => _StationMarkerState();
}

class _StationMarkerState extends State<StationMarker> {
  bool _isPressed = false;

  static final Map<String, String> _brandLogoAssets = {
    'Circle K': 'assets/logos/circle-k.png',
    'Esso': 'assets/logos/esso.png',
    'Shell': 'assets/logos/shell.png',
    'YX': 'assets/logos/yx.png',
    'Uno-X': 'assets/logos/uno-x.png',
    'St1': 'assets/logos/st1.png',
    'YX Truck': 'assets/logos/yx-truck.png',
    'Tanken': 'assets/logos/tanken.png',
  };

  String? _getLogoAsset() {
    final brand = widget.station.brand;
    if (brand.isEmpty) return null;
    return _brandLogoAssets[brand];
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

    if (minutes < 60) {
      return (label: context.l10n.ageMinutes(minutes), color: Colors.green);
    }
    if (hours <= 5) {
      return (label: context.l10n.ageHours(hours), color: Colors.green);
    }
    if (hours <= 12) {
      return (label: context.l10n.ageHours(hours), color: Colors.orange);
    }
    if (hours <= 23) {
      return (label: context.l10n.ageHours(hours), color: Colors.red);
    }
    return (label: context.l10n.ageOver1Day, color: Colors.grey);
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
        child: widget.price != null
            ? _buildLogoWithPrice(context)
            : _buildCircleMarker(context),
      ),
    );
  }

  /// Logo circle with freshness-colored border, time badge, and price tag.
  Widget _buildLogoWithPrice(BuildContext context) {
    final price = widget.price!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = _getLogoAsset();
    final age = DateTime.now().difference(price.updatedAt);
    final (:label, :color) = _formatAge(context, age);

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
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6),
                ],
              ),
              child: logoAsset != null
                  ? ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Image.asset(
                          logoAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              _buildFallbackLogo(context),
                        ),
                      ),
                    )
                  : _buildFallbackLogo(context),
            ),
            // Time badge — top right
            Positioned(
              top: -4,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Price tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: widget.isBestPrice
                ? AppColors.primaryContainer(context)
                : (isDark ? AppColors.darkSurfaceHigh : Colors.white),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isBestPrice
                  ? AppColors.primaryContainer(context)
                  : AppColors.border(context),
              width: widget.isBestPrice ? 1 : 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isBestPrice
                    ? AppColors.primaryContainer(
                        context,
                      ).withValues(alpha: 0.35)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: widget.isBestPrice ? 8 : 4,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isBestPrice)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Icon(
                    Icons.star_rounded,
                    size: 10,
                    color: isDark ? AppColors.darkBackground : Colors.white,
                  ),
                ),
              Text(
                price.price.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: widget.isBestPrice
                      ? (isDark ? AppColors.darkBackground : Colors.white)
                      : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// No price — plain circle with logo or initials.
  Widget _buildCircleMarker(BuildContext context) {
    final logoAsset = _getLogoAsset();

    return AnimatedOpacity(
      opacity: _isPressed ? 0.85 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border(context),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            if (logoAsset != null)
              ClipOval(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => _buildFallbackLogo(context),
                  ),
                ),
              )
            else
              _buildFallbackLogo(context),
          ],
        ),
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
