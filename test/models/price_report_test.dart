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
import 'package:fuel_price_tracker/models/price_report.dart';

void main() {
  group('PriceReport', () {
    final json = {
      'id': 'report_1',
      'stationId': 'osm_123',
      'fuelType': 'diesel',
      'price': 19.89,
      'userId': 'uid_abc',
      'reportedAt': '2026-03-21T14:30:00.000',
    };

    test('fromJson creates valid PriceReport', () {
      final report = PriceReport.fromJson(json);
      expect(report.id, 'report_1');
      expect(report.stationId, 'osm_123');
      expect(report.fuelType, FuelType.diesel);
      expect(report.price, 19.89);
      expect(report.userId, 'uid_abc');
      expect(report.reportedAt, DateTime.parse('2026-03-21T14:30:00.000'));
    });

    test('toJson produces correct map', () {
      final report = PriceReport.fromJson(json);
      final output = report.toJson();
      expect(output['id'], 'report_1');
      expect(output['stationId'], 'osm_123');
      expect(output['fuelType'], 'diesel');
      expect(output['price'], 19.89);
      expect(output['userId'], 'uid_abc');
    });

    test('roundtrip preserves all fields', () {
      final report = PriceReport.fromJson(json);
      final roundtripped = PriceReport.fromJson(report.toJson());
      expect(roundtripped.id, report.id);
      expect(roundtripped.stationId, report.stationId);
      expect(roundtripped.fuelType, report.fuelType);
      expect(roundtripped.price, report.price);
      expect(roundtripped.userId, report.userId);
      expect(roundtripped.reportedAt, report.reportedAt);
    });
  });
}
