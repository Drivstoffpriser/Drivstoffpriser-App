import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../models/current_price.dart';

class PriceCard extends StatelessWidget {
  final CurrentPrice price;

  const PriceCard({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price.fuelType.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${price.reportCount} reports · ${timeago.format(price.updatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '${price.price.toStringAsFixed(2)} kr/${price.fuelType.unit}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
