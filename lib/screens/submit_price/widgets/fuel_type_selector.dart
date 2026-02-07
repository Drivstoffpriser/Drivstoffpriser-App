import 'package:flutter/material.dart';

import '../../../models/fuel_type.dart';

class FuelTypeSelector extends StatelessWidget {
  final FuelType selected;
  final ValueChanged<FuelType> onChanged;

  const FuelTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<FuelType>(
      segments: FuelType.values.map((type) {
        return ButtonSegment(
          value: type,
          label: Text(type.displayName),
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
