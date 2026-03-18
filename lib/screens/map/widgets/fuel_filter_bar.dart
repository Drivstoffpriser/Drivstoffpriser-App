import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/fuel_type.dart';
import '../../../providers/station_provider.dart';
import '../../../providers/user_provider.dart';

class FuelFilterBar extends StatelessWidget {
  final Widget? trailing;

  const FuelFilterBar({super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final provider = context.watch<StationProvider>();

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: FuelType.values.map((type) {
                final selected = provider.selectedFuelType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type.displayName),
                    selected: selected,
                    onSelected: (_) => provider.setFuelType(type),
                  ),
                );
              }).toList(),
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: FuelType.values.map((type) {
          final selected = provider.selectedFuelType == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => provider.setFuelType(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.surface(isDark),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border(isDark),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Text(
                type.displayName,
                style: AppTextStyles.label(isDark).copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary(isDark),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            ),
          ),
        ),
        if (trailing != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: trailing!,
          ),
      ],
    );
  }
}
