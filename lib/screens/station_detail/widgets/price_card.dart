import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/current_price.dart';
import '../../../providers/user_provider.dart';

class PriceCard extends StatelessWidget {
  final CurrentPrice price;

  const PriceCard({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border(isDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.fuelType.displayName,
                  style: AppTextStyles.body(isDark).copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${price.reportCount} reports · ${timeago.format(price.updatedAt)}',
                  style: AppTextStyles.label(isDark),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${price.price.toStringAsFixed(2)} kr',
                style: AppTextStyles.price(isDark).copyWith(fontSize: 18),
              ),
              Text(
                'per ${price.fuelType.unit}',
                style: AppTextStyles.label(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
