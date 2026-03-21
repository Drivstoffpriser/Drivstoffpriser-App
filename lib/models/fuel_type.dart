import 'package:flutter/material.dart';

import '../l10n/l10n_helper.dart';

enum FuelType {
  petrol95,
  petrol98,
  diesel;

  String get displayName {
    switch (this) {
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.petrol95:
        return 'Bensin 95';
      case FuelType.petrol98:
        return 'Bensin 98';
    }
  }

  String localizedName(BuildContext context) => switch (this) {
    FuelType.petrol95 => context.l10n.fuelPetrol95,
    FuelType.petrol98 => context.l10n.fuelPetrol98,
    FuelType.diesel => context.l10n.fuelDiesel,
  };

  String get unit => 'L';
}
