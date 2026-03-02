import 'package:flutter/material.dart';

import '../../../models/current_price.dart';
import '../../../models/station.dart';

class StationMarker extends StatelessWidget {
  final Station station;
  final CurrentPrice? price;
  final VoidCallback onTap;

  const StationMarker({
    super.key,
    required this.station,
    this.price,
    required this.onTap,
  });

  static ({String label, Color color}) _formatAge(Duration age) {
    final minutes = age.inMinutes;
    final hours = age.inHours;

    if (minutes < 60) {
      return (label: '${minutes}m', color: Colors.green);
    }
    if (hours <= 5) {
      return (label: '${hours}hr', color: Colors.green);
    }
    if (hours <= 12) {
      return (label: '${hours}hr', color: Colors.orange);
    }
    if (hours <= 23) {
      return (label: '${hours}hr', color: Colors.red);
    }
    return (label: '>1d', color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (price != null) ...[
            () {
              final age = DateTime.now().difference(price!.updatedAt);
              final (:label, :color) = _formatAge(age);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              );
            }(),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                price != null
                    ? '${price!.price.toStringAsFixed(1)} kr'
                    : station.brand,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Icon(
            Icons.location_on,
            color: colorScheme.primary,
            size: 24,
          ),
        ],
      ),
    );
  }
}
