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
import 'package:fuel_price_tracker/services/price_sign_scanner_service.dart';

void main() {
  group('ScanResult metadata', () {
    test('cropMethod defaults to CropMethod.none', () {
      const result = ScanResult(prices: {}, rawText: '');
      expect(result.cropMethod, CropMethod.none);
    });

    test('shouldOfferManualCrop defaults to false', () {
      const result = ScanResult(prices: {}, rawText: '');
      expect(result.shouldOfferManualCrop, isFalse);
    });

    test('preserves cropMethod when set', () {
      const result = ScanResult(
        prices: {},
        rawText: 'test',
        cropMethod: CropMethod.autoCrop,
      );
      expect(result.cropMethod, CropMethod.autoCrop);

      const result2 = ScanResult(
        prices: {},
        rawText: 'test',
        cropMethod: CropMethod.manualCrop,
      );
      expect(result2.cropMethod, CropMethod.manualCrop);
    });

    test('preserves shouldOfferManualCrop when set to true', () {
      const result = ScanResult(
        prices: {},
        rawText: 'test',
        shouldOfferManualCrop: true,
      );
      expect(result.shouldOfferManualCrop, isTrue);
    });

    test('preserves prices with metadata', () {
      const result = ScanResult(
        prices: {FuelType.diesel: 19.79},
        rawText: 'D 19.79',
        cropMethod: CropMethod.autoCrop,
      );
      expect(result.prices[FuelType.diesel], 19.79);
      expect(result.cropMethod, CropMethod.autoCrop);
    });
  });
}
