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
import 'package:flutter/services.dart';

import '../../../config/app_text_styles.dart';
import '../../../l10n/l10n_helper.dart';
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
        labelText: '${fuelType.localizedName(context)} (${fuelType.unit})',
        suffixText: 'kr/${fuelType.unit}',
        helperText: context.l10n.priceRange,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return required ? context.l10n.enterAPrice : null;
        }
        final price = double.tryParse(value);
        if (price == null) return context.l10n.invalidNumber;
        if (price < 5.0 || price > 50.0) {
          return context.l10n.priceMustBeBetween;
        }
        return null;
      },
    );
  }
}
