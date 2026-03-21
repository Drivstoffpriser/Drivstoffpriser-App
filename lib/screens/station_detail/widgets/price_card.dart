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
    final activeColor = AppColors.primaryContainer(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border(context),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  price.fuelType.displayName,
                  style: AppTextStyles.label(context).copyWith(
                    color: activeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${price.price.toStringAsFixed(2)}',
            style: AppTextStyles.priceLarge(context).copyWith(
              fontSize: 24,
              color: AppColors.textPrimary(context),
            ),
          ),
          Text(
            'kr/${price.fuelType.unit}',
            style: AppTextStyles.meta(context),
          ),
          const SizedBox(height: 8),
          Text(
            '${price.reportCount} reports · ${timeago.format(price.updatedAt)}',
            style: AppTextStyles.meta(context),
          ),
        ],
      ),
    );
  }
}
