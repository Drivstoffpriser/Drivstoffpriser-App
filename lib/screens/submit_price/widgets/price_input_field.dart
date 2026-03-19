import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../config/app_text_styles.dart';
import '../../../models/fuel_type.dart';

class PriceInputField extends StatelessWidget {
  final TextEditingController controller;
  final FuelType fuelType;
  final bool required;

  const PriceInputField({
    super.key,
    required this.controller,
    required this.fuelType,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: AppTextStyles.body(context),
      decoration: InputDecoration(
        labelText: '${fuelType.displayName} (${fuelType.unit})',
        suffixText: 'kr/${fuelType.unit}',
        helperText: 'Range: 5-50 kr',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return required ? 'Enter a price' : null;
        }
        final price = double.tryParse(value);
        if (price == null) return 'Invalid number';
        if (price < 5.0 || price > 50.0) {
          return 'Price must be between 5 and 50 kr';
        }
        return null;
      },
    );
  }
}
