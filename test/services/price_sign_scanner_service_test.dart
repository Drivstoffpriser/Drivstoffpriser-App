import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_price_tracker/models/fuel_type.dart';
import 'package:fuel_price_tracker/services/price_sign_scanner_service.dart';

void main() {
  group('PriceSignScannerService.parseRecognizedText', () {
    test('standard same-line labels with dot decimals', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 19.79\n95 20.47',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
      expect(result.containsKey(FuelType.petrol98), isFalse);
      expect(result.containsKey(FuelType.electric), isFalse);
    });

    test('Norwegian comma decimals are normalized to dots', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'Diesel 19,79\n95 20,47',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('split lines — label and price on adjacent lines', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D\n19.79\n95\n20.47',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('with noise text that should be ignored', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'UNO X\nD 19.79\n95 20.47',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('no prices found returns empty map', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'WELCOME\nOPEN 24H',
      );
      expect(result, isEmpty);
    });

    test('all three fuel types recognized', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 19.79\n95 20.47\n98 21.35',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
      expect(result[FuelType.petrol98], 21.35);
    });

    test('prices outside plausible range are ignored', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 5.00\n95 50.00',
      );
      expect(result, isEmpty);
    });

    test('"Diesel" full word is matched', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'Diesel 22.50',
      );
      expect(result[FuelType.diesel], 22.50);
    });

    test('95 and 98 are not treated as prices (out of range)', () {
      // "95" and "98" without decimal points should not be matched as prices
      final result = PriceSignScannerService.parseRecognizedText(
        '95\n98',
      );
      expect(result, isEmpty);
    });

    test('mixed: some same-line, some split', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 19.79\n95\n20.47\n98 21.35',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
      expect(result[FuelType.petrol98], 21.35);
    });
  });

  group('LED 7-segment normalization', () {
    test('fixes "9s" → "95" (s misread as 5)', () {
      // ML Kit reads "9s 2047" instead of "95 20.47"
      final result = PriceSignScannerService.parseRecognizedText(
        'D 19.19\n9s 2047',
      );
      expect(result[FuelType.diesel], 19.19);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('recovers missing decimal in 4-digit sequence', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 1979\n95 2047',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('recovers missing decimal in 3-digit sequence', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 197',
      );
      expect(result[FuelType.diesel], 19.7);
    });

    test('real ML Kit output from Uno X sign', () {
      // Exact raw text from the logs
      final result = PriceSignScannerService.parseRecognizedText(
        'Uno\nD 19.19\n9s 2047\n95\nSone\n(30)\nSTIAD',
      );
      expect(result[FuelType.diesel], 19.19);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('does not create false prices from non-price digit sequences', () {
      // "5050" → "50.50" is out of range, should stay as-is
      final result = PriceSignScannerService.parseRecognizedText(
        'D 5050',
      );
      expect(result, isEmpty);
    });

    test('handles combined LED fixes: s→5 and decimal recovery', () {
      final result = PriceSignScannerService.parseRecognizedText(
        'D 1979\n9s 2047\n98 2135',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
      expect(result[FuelType.petrol98], 21.35);
    });
  });

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
