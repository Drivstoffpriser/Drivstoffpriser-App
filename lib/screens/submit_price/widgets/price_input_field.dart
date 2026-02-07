import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/constants.dart';
import '../../../models/fuel_type.dart';

class PriceInputField extends StatelessWidget {
  final TextEditingController controller;
  final FuelType fuelType;

  const PriceInputField({
    super.key,
    required this.controller,
    required this.fuelType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: 'Price (${AppConstants.currencyCode}/${fuelType.unit})',
        suffixText: 'kr/${fuelType.unit}',
        border: const OutlineInputBorder(),
        helperText: 'Range: ${AppConstants.minFuelPrice.toStringAsFixed(0)}-${AppConstants.maxFuelPrice.toStringAsFixed(0)} kr',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Enter a price';
        final price = double.tryParse(value);
        if (price == null) return 'Invalid number';
        if (price < AppConstants.minFuelPrice || price > AppConstants.maxFuelPrice) {
          return 'Price must be between ${AppConstants.minFuelPrice.toStringAsFixed(0)} and ${AppConstants.maxFuelPrice.toStringAsFixed(0)} kr';
        }
        return null;
      },
    );
  }
}
