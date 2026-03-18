import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/current_price.dart';
import '../../../models/station.dart';
import '../../../providers/user_provider.dart';

class StationMarker extends StatelessWidget {
  final Station station;
  final CurrentPrice? price;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.price,
    required this.onTap,
  });

  static ({String label, Color color}) _formatAge(Duration age) {
    final minutes = age.inMinutes;
    final hours = age.inHours;

    if (minutes < 60) {
      return (label: '${minutes}m', color: Colors.green);
    }
    if (hours <= 5) {
      return (label: '${hours}hr', color: Colors.green);
    }
    if (hours <= 12) {
      return (label: '${hours}hr', color: Colors.orange);
    }
    if (hours <= 23) {
      return (label: '${hours}hr', color: Colors.red);
    }
    return (label: '>1d', color: Colors.grey);
  String? _getBrandAsset(String brand) {
    final b = brand.toLowerCase();
    if (b.contains('circle k')) return 'assets/logos/circle-k.png';
    if (b.contains('shell')) return 'assets/logos/shell.png';
    if (b.contains('esso')) return 'assets/logos/esso.png';
    if (b.contains('uno-x')) return 'assets/logos/uno-x.png';
    if (b.contains('yx')) return 'assets/logos/yx.png';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final brandAsset = _getBrandAsset(station.brand);
    
    return GestureDetector(
      onTap: onTap,
<<<<<<< HEAD
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (price != null) ...[
            () {
              final age = DateTime.now().difference(price!.updatedAt);
              final (:label, :color) = _formatAge(age);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            }(),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                price != null
                    ? '${price!.price.toStringAsFixed(2)} kr'
                    : station.brand,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
=======
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0x1F000000), // rgba(0,0,0,0.12)
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 6,
              offset: const Offset(0, 2),
>>>>>>> 2bd3d39 (ui overhaul)
            ),
          ],
        ),
        child: _buildContent(brandAsset, isDark),
      ),
    );
  }

  Widget _buildContent(String? brandAsset, bool isDark) {
    // 1. URL priority
    if (station.logoUrl != null && station.logoUrl!.isNotEmpty) {
      return Center(
        child: Image.network(
          station.logoUrl!,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallback(brandAsset, isDark),
        ),
      );
    }
    
    return _buildFallback(brandAsset, isDark);
  }

  Widget _buildFallback(String? brandAsset, bool isDark) {
    // 2. Local Asset priority
    if (brandAsset != null) {
      return Center(
        child: Image.asset(
          brandAsset,
          width: 28,
          height: 28,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildGeneric(isDark),
        ),
      );
    }

    // 3. Generic Priority
    return _buildGeneric(isDark);
  }

  Widget _buildGeneric(bool isDark) {
    final truncatedName = station.name.length > 10 
        ? '${station.name.substring(0, 10)}...' 
        : station.name;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_gas_station,
          size: 22,
          color: const Color(0xFF8A8A8A),
        ),
        Text(
          truncatedName,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8A8A8A),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
