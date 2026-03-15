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
