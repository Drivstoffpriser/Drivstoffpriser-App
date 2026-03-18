import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../config/constants.dart';
import '../../../models/fuel_type.dart';
import '../../../providers/user_provider.dart';

class PriceInputField extends StatelessWidget {
  final TextEditingController controller;
  final FuelType fuelType;

  const PriceInputField({
    super.key,
    required this.controller,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fuelType.displayName,
                style: AppTextStyles.label(isDark).copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(isDark).withOpacity(0.8),
                ),
              ),
              Text(
                'kr/${fuelType.unit}',
                style: AppTextStyles.label(isDark).copyWith(color: AppColors.textMuted(isDark)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: AppTextStyles.price(isDark).copyWith(fontSize: 24),
            decoration: InputDecoration(
              hintText: '00.00',
              hintStyle: AppTextStyles.price(isDark).copyWith(
                fontSize: 24,
                color: AppColors.textMuted(isDark).withOpacity(0.2),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return null;
              final cleaned = value.replaceAll(',', '.');
              final val = double.tryParse(cleaned);
              if (val == null) return 'Invalid number';
              if (val < AppConstants.minFuelPrice || val > AppConstants.maxFuelPrice) {
                return 'Range: ${AppConstants.minFuelPrice}-${AppConstants.maxFuelPrice}';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
