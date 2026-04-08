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
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/current_price.dart';

class PriceCard extends StatelessWidget {
  final CurrentPrice price;
  final bool compact;

  const PriceCard({super.key, required this.price, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primaryContainer(context);

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 0.5),
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
                  price.fuelType.localizedName(context),
                  style: AppTextStyles.label(
                    context,
                  ).copyWith(color: activeColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price.price.toStringAsFixed(2),
                style: AppTextStyles.priceLarge(context).copyWith(
                  fontSize: compact ? 20 : 24,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(width: 4),
              Text('kr', style: AppTextStyles.meta(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeago.format(price.updatedAt),
            style: AppTextStyles.meta(context),
          ),
        ],
      ),
    );
  }
}
