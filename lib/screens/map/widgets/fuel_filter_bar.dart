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
import '../../../models/fuel_type.dart';
import '../../../providers/station_provider.dart';

class FuelFilterBar extends StatelessWidget {
  final Widget? trailing;

  const FuelFilterBar({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ...FuelType.values.map((type) {
                  final selected = provider.selectedFuelType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FuelChip(
                      label: type.localizedName(context),
                      isSelected: selected,
                      onTap: () => provider.setFuelType(type),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (provider.favoriteStationIds.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(right: trailing != null ? 8 : 16),
            child: GestureDetector(
              onTap: () =>
                  provider.setShowFavoritesOnly(!provider.showFavoritesOnly),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: provider.showFavoritesOnly
                        ? Colors.red
                        : AppColors.border(context),
                    width: 0.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    provider.showFavoritesOnly
                        ? Icons.favorite
                        : Icons.favorite_border,
                    size: 18,
                    color: provider.showFavoritesOnly
                        ? Colors.red
                        : AppColors.textMuted(context),
                  ),
                ),
              ),
            ),
          ),
        if (trailing != null)
          Padding(padding: const EdgeInsets.only(right: 16), child: trailing!),
      ],
    );
  }
}

class _FuelChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FuelChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FuelChip> createState() => _FuelChipState();
}

class _FuelChipState extends State<_FuelChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = AppColors.primaryContainer(context);

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
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor
                  : (isDark
                        ? AppColors.darkSurfaceHigh
                        : AppColors.lightSurfaceLow),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.isSelected
                    ? activeColor
                    : AppColors.border(context),
                width: 0.5,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            child: Center(
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
      ),
    );
  }
}
