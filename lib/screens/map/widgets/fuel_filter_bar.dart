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
                    label: type.displayName,
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
                  ? const Color(0xFF2563EB)
                  : isDark
                  ? const Color(0xFF242424)
                  : const Color(0xFFF7F7F5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: widget.isSelected
                    ? const Color(0xFF2563EB)
                    : isDark
                    ? const Color(0x14FFFFFF)
                    : const Color(0x14000000),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: AppTextStyles.chipLabel(context).copyWith(
                  color: widget.isSelected
                      ? Colors.white
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
