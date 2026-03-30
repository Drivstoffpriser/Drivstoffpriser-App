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
import 'package:fuel_price_tracker/models/station.dart';

void main() {
  group('Station', () {
    const json = {
      'id': 'osm_123',
      'name': 'Circle K Majorstuen',
      'brand': 'Circle K',
      'address': 'Bogstadveien 1',
      'city': 'Oslo',
      'latitude': 59.9291,
      'longitude': 10.7127,
    };

    test('fromJson creates valid Station', () {
      final station = Station.fromJson(json);
      expect(station.id, 'osm_123');
      expect(station.name, 'Circle K Majorstuen');
      expect(station.brand, 'Circle K');
      expect(station.address, 'Bogstadveien 1');
      expect(station.city, 'Oslo');
      expect(station.latitude, 59.9291);
      expect(station.longitude, 10.7127);
    });

    test('toJson produces correct map', () {
      final station = Station.fromJson(json);
      final output = station.toJson();
      expect(output, json);
    });

    test('fromJson handles int coordinates', () {
      final intJson = Map<String, dynamic>.from(json);
      intJson['latitude'] = 60;
      intJson['longitude'] = 11;
      final station = Station.fromJson(intJson);
      expect(station.latitude, 60.0);
      expect(station.longitude, 11.0);
    });

    test('roundtrip preserves all fields', () {
      final station = Station.fromJson(json);
      final roundtripped = Station.fromJson(station.toJson());
      expect(roundtripped.id, station.id);
      expect(roundtripped.name, station.name);
      expect(roundtripped.brand, station.brand);
      expect(roundtripped.address, station.address);
      expect(roundtripped.city, station.city);
      expect(roundtripped.latitude, station.latitude);
      expect(roundtripped.longitude, station.longitude);
    });
  });
}
