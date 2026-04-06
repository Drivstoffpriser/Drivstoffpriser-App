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
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../l10n/l10n_helper.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/user_provider.dart';

/// Whether the filter is shown on the map or the station list.
enum FilterLocation { map, list }

class BrandFilterButton extends StatelessWidget {
  final String heroTag;
  final FilterLocation filterLocation;

  const BrandFilterButton({
    super.key,
    this.heroTag = 'brandFilter',
    this.filterLocation = FilterLocation.map,
  });

  @override
  Widget build(BuildContext context) {
    final stationProvider = context.watch<StationProvider>();
    final userProvider = context.watch<UserProvider>();
    final radiusKm = filterLocation == FilterLocation.map
        ? stationProvider.mapRadiusKm
        : stationProvider.listRadiusKm;
    final hasFilter =
        stationProvider.selectedBrands.isNotEmpty ||
        radiusKm != null ||
        stationProvider.showFavoritesOnly ||
        (filterLocation == FilterLocation.map &&
            !userProvider.allowMapRotation);
    final activeColor = AppColors.primaryContainer(context);

    return GestureDetector(
      onTap: () => _showBrandFilterSheet(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border(context), width: 0.5),
            ),
            child: Center(
              child: Icon(
                Icons.tune_outlined,
                size: 18,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          if (hasFilter)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surfaceElevated(context),
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBrandFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => _BrandFilterSheet(filterLocation: filterLocation),
    );
  }
}

class _BrandFilterSheet extends StatelessWidget {
  final FilterLocation filterLocation;

  const _BrandFilterSheet({required this.filterLocation});

  static String _radiusLabel(BuildContext context, double? km) {
    if (km == null) return context.l10n.allOfNorway;
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final userProvider = context.watch<UserProvider>();
    final isMap = filterLocation == FilterLocation.map;
    final brands = isMap
        ? provider.mapAvailableBrands
        : provider.listAvailableBrands;
    final radiusKm = isMap ? provider.mapRadiusKm : provider.listRadiusKm;
    final activeColor = AppColors.primaryContainer(context);
    final allowMapRotation = userProvider.allowMapRotation;

    final steps = [5, 10, 20, 50, 100, 200, 500, null];
    final currentIndex = radiusKm == null
        ? steps.length - 1
        : steps.indexWhere((s) => s != null && (s as num) >= radiusKm.round());
    final sliderValue = (currentIndex == -1 ? steps.length - 1 : currentIndex)
        .toDouble();

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        28,
        16,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.searchRadius,
                  style: AppTextStyles.title(context),
                ),
                const Spacer(),
                Text(
                  _radiusLabel(context, radiusKm),
                  style: AppTextStyles.bodyMedium(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: activeColor,
                inactiveTrackColor: AppColors.border(context),
                thumbColor: activeColor,
                overlayColor: activeColor.withValues(alpha: 0.12),
              ),
              child: Slider(
                value: sliderValue,
                min: 0,
                max: (steps.length - 1).toDouble(),
                divisions: steps.length - 1,
                onChanged: (v) {
                  final idx = v.round();
                  final km = steps[idx];
                  if (isMap) {
                    provider.setMapRadius(km?.toDouble());
                  } else {
                    provider.setListRadius(km?.toDouble());
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  context.l10n.filterByBrand,
                  style: AppTextStyles.title(context),
                ),
                const Spacer(),
                if (provider.selectedBrands.isNotEmpty)
                  GestureDetector(
                    onTap: () => provider.clearBrandFilter(),
                    child: Text(
                      context.l10n.clearAll,
                      style: AppTextStyles.label(
                        context,
                      ).copyWith(color: activeColor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: brands.map((brand) {
                final selected = provider.selectedBrands.contains(brand);
                return _FilterChip(
                  label: brand,
                  isSelected: selected,
                  onTap: () => provider.toggleBrand(brand),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  size: 20,
                  color: provider.showFavoritesOnly
                      ? Colors.red
                      : AppColors.textMuted(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.showFavoritesOnly,
                    style: AppTextStyles.bodyMedium(context),
                  ),
                ),
                Switch(
                  value: provider.showFavoritesOnly,
                  onChanged: (v) => provider.setShowFavoritesOnly(v),
                  activeTrackColor: Colors.red.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.red;
                    }
                    return null;
                  }),
                ),
              ],
            ),
            if (isMap) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 20,
                    color: allowMapRotation
                        ? activeColor
                        : AppColors.textMuted(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.allowMapRotation,
                      style: AppTextStyles.bodyMedium(context),
                    ),
                  ),
                  Switch(
                    value: allowMapRotation,
                    onChanged: userProvider.setAllowMapRotation,
                    activeTrackColor: activeColor.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return activeColor;
                      }
                      return null;
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryContainer(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _isPressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected
                    ? activeColor
                    : AppColors.border(context),
                width: 0.5,
              ),
            ),
            child: Text(
              widget.label,
              style: AppTextStyles.chipLabel(context).copyWith(
                color: widget.isSelected
                    ? (isDark ? AppColors.darkBackground : Colors.white)
                    : AppColors.textMuted(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
