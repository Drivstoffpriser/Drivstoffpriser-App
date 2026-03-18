import 'package:flutter/material.dart';

import '../../../config/app_colors.dart';
import '../../../models/current_price.dart';
import '../../../models/station.dart';

class StationMarker extends StatefulWidget {
  final Station station;
  final CurrentPrice? price;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.price,
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
  };

  String? _getLogoAsset() {
    final brand = widget.station.brand;
    if (brand.isEmpty) return null;
    return _brandLogoAssets[brand];
  }

  @override
  Widget build(BuildContext context) {
    final logoAsset = _getLogoAsset();

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                      width: 36,
                      height: 36,
                      child: Image.asset(
                        logoAsset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            _buildFallbackLogo(context),
                      ),
                    ),
                  )
                else
                  _buildFallbackLogo(context),
                if (widget.price != null) _buildPriceBadge(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(BuildContext context) {
    final brand = widget.station.brand.isNotEmpty ? widget.station.brand : '?';
    final initials = brand.length > 2
        ? brand.substring(0, 2).toUpperCase()
        : brand.toUpperCase();

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2563EB).withValues(alpha: 0.1),
            const Color(0xFF2563EB).withValues(alpha: 0.05),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBadge(BuildContext context) {
    final price = widget.price!;

    return Positioned(
      bottom: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.surfaceElevated(context),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          price.price.toStringAsFixed(2),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
