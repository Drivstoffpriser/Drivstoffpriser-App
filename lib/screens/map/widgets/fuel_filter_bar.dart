import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/fuel_type.dart';
import '../../../providers/station_provider.dart';

class FuelFilterBar extends StatelessWidget {
  const FuelFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();

    return SingleChildScrollView(
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
      ),
    );
  }
}
