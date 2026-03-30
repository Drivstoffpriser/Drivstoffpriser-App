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

import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_price_tracker/models/fuel_type.dart';

void main() {
  group('FuelType', () {
    test('displayName returns expected values', () {
      expect(FuelType.petrol95.displayName, 'Bensin 95');
      expect(FuelType.petrol98.displayName, 'Bensin 98');
      expect(FuelType.diesel.displayName, 'Diesel');
    });

    test('unit is L for all types', () {
      for (final type in FuelType.values) {
        expect(type.unit, 'L');
      }
    });

    test('values.byName round-trips all types', () {
      for (final type in FuelType.values) {
        expect(FuelType.values.byName(type.name), type);
      }
    });

    test('has exactly 3 values', () {
      expect(FuelType.values.length, 3);
    });
  });
}
