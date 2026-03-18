import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart';

class PriceBadge extends StatelessWidget {
  final double price;
  final String currency;

  const PriceBadge({
    super.key,
    required this.price,
    this.currency = 'kr',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;
    final color = AppColors.textPrimary(isDark);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          width: 1,
        ),
      ),
      child: Text(
        '${price.toStringAsFixed(2)} $currency',
        style: AppTextStyles.price(isDark),
      ),
    );
  }
}
