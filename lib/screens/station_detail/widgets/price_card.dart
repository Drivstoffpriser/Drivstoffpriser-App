import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/current_price.dart';

class PriceCard extends StatelessWidget {
  final CurrentPrice price;

  const PriceCard({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.fuelType.displayName,
                  style: AppTextStyles.bodyMedium(context),
                ),
                const SizedBox(height: 4),
                Text(
                  '${price.reportCount} reports · ${timeago.format(price.updatedAt)}',
                  style: AppTextStyles.meta(context),
                ),
              ],
            ),
          ),
          Text(
            '${price.price.toStringAsFixed(2)} kr/${price.fuelType.unit}',
            style: AppTextStyles.priceMedium(
              context,
            ).copyWith(color: const Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }
}
