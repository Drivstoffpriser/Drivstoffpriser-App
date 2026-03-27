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
