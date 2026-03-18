import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/user_provider.dart';

class BrandFilterButton extends StatelessWidget {
  final String heroTag;

  const BrandFilterButton({super.key, this.heroTag = 'brandFilter'});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final provider = context.watch<StationProvider>();
    final hasFilter =
        provider.selectedBrands.isNotEmpty || provider.filterRadiusKm != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _showBrandFilterSheet(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(isDark)),
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: AppColors.textPrimary(isDark),
            ),
          ),
        ),
        if (hasFilter)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background(isDark), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  void _showBrandFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BrandFilterSheet(),
    );
  }
}

class _BrandFilterSheet extends StatelessWidget {
  const _BrandFilterSheet();

  static String _radiusLabel(double? km) {
    if (km == null) return 'All of Norway';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final provider = context.watch<StationProvider>();
    final brands = provider.availableBrands;
    final radiusKm = provider.filterRadiusKm;

    // Slider: 0 = 5 km, 1 = All
    // We use discrete steps for a better feel.
    final steps = [5, 10, 20, 50, 100, 200, 500, null]; // null = All
    final currentIndex = radiusKm == null
        ? steps.length - 1
        : steps.indexWhere((s) => s != null && (s as num) >= radiusKm.round());
    final sliderValue =
        (currentIndex == -1 ? steps.length - 1 : currentIndex).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [ 
              Text(
                'Filter by Brand',
                style: AppTextStyles.heading(isDark),
              ),
              const Spacer(),
              if (provider.selectedBrands.isNotEmpty)
                TextButton(
                  onPressed: () => provider.clearBrandFilter(),
                  child: Text(
                    'Clear all',
                    style: AppTextStyles.label(isDark).copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: brands.map((brand) {
              final selected = provider.selectedBrands.contains(brand);
              return GestureDetector(
                onTap: () => provider.toggleBrand(brand),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.accent : AppColors.surface(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.border(isDark),
                      width: selected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    brand,
                    style: AppTextStyles.label(isDark).copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary(isDark),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
