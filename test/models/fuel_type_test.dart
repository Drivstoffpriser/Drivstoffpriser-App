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
