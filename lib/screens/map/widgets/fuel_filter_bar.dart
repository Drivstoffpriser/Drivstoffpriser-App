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
              children: FuelType.values.map((type) {
                final selected = provider.selectedFuelType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FuelChip(
                    label: type.localizedName(context),
                    isSelected: selected,
                    onTap: () => provider.setFuelType(type),
                  ),
                );
              }).toList(),
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
