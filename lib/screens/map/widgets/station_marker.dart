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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
