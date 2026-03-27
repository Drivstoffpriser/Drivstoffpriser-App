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
import 'package:fuel_price_tracker/models/current_price.dart';
import 'package:fuel_price_tracker/models/fuel_type.dart';

void main() {
  group('CurrentPrice', () {
    final json = {
      'stationId': 'osm_123',
      'fuelType': 'petrol95',
      'price': 21.49,
      'updatedAt': '2026-03-21T12:00:00.000',
      'reportCount': 5,
    };

    test('fromJson creates valid CurrentPrice', () {
      final price = CurrentPrice.fromJson(json);
      expect(price.stationId, 'osm_123');
      expect(price.fuelType, FuelType.petrol95);
      expect(price.price, 21.49);
      expect(price.updatedAt, DateTime.parse('2026-03-21T12:00:00.000'));
      expect(price.reportCount, 5);
    });

    test('toJson produces correct map', () {
      final price = CurrentPrice.fromJson(json);
      final output = price.toJson();
      expect(output['stationId'], 'osm_123');
      expect(output['fuelType'], 'petrol95');
      expect(output['price'], 21.49);
      expect(output['reportCount'], 5);
    });

    test('fromJson handles int price', () {
      final intJson = Map<String, dynamic>.from(json);
      intJson['price'] = 22;
      final price = CurrentPrice.fromJson(intJson);
      expect(price.price, 22.0);
    });

    test('all fuel types parse correctly', () {
      for (final type in FuelType.values) {
        final typeJson = Map<String, dynamic>.from(json);
        typeJson['fuelType'] = type.name;
        final price = CurrentPrice.fromJson(typeJson);
        expect(price.fuelType, type);
      }
    });

    test('roundtrip preserves all fields', () {
      final price = CurrentPrice.fromJson(json);
      final roundtripped = CurrentPrice.fromJson(price.toJson());
      expect(roundtripped.stationId, price.stationId);
      expect(roundtripped.fuelType, price.fuelType);
      expect(roundtripped.price, price.price);
      expect(roundtripped.updatedAt, price.updatedAt);
      expect(roundtripped.reportCount, price.reportCount);
    });
  });
}
