import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_price_tracker/models/fuel_type.dart';

/// Test the JSON response parsing logic (extracted to match ClaudeVisionService._parseResponse).
Map<FuelType, double> parseResponse(String responseText) {
  var text = responseText;
  if (text.startsWith('```')) {
    text = text
        .replaceAll(RegExp(r'^```\w*\n?'), '')
        .replaceAll(RegExp(r'\n?```$'), '');
  }

  final json = jsonDecode(text.trim()) as Map<String, dynamic>;
  final prices = <FuelType, double>{};

  const keyMap = {
    'diesel': FuelType.diesel,
    'petrol_95': FuelType.petrol95,
    'petrol_98': FuelType.petrol98,
  };

  for (final entry in keyMap.entries) {
    final value = json[entry.key];
    if (value is num) {
      final price = value.toDouble();
      if (price >= 10.0 && price <= 35.0) {
        prices[entry.value] = price;
      }
    }
  }

  return prices;
}

void main() {
  group('Claude Vision response parsing', () {
    test('parses all three fuel types', () {
      final result = parseResponse(
        '{"diesel":19.79,"petrol_95":20.47,"petrol_98":21.35}',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
      expect(result[FuelType.petrol98], 21.35);
    });

    test('handles null values (fuel type not visible)', () {
      final result = parseResponse(
        '{"diesel":19.79,"petrol_95":null,"petrol_98":null}',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result.containsKey(FuelType.petrol95), isFalse);
      expect(result.containsKey(FuelType.petrol98), isFalse);
    });

    test('filters out-of-range prices', () {
      final result = parseResponse(
        '{"diesel":5.00,"petrol_95":50.00,"petrol_98":20.00}',
      );
      expect(result.containsKey(FuelType.diesel), isFalse);
      expect(result.containsKey(FuelType.petrol95), isFalse);
      expect(result[FuelType.petrol98], 20.00);
    });

    test('handles all nulls', () {
      final result = parseResponse(
        '{"diesel":null,"petrol_95":null,"petrol_98":null}',
      );
      expect(result, isEmpty);
    });

    test('strips markdown code fences', () {
      final result = parseResponse(
        '```json\n{"diesel":19.79,"petrol_95":20.47,"petrol_98":null}\n```',
      );
      expect(result[FuelType.diesel], 19.79);
      expect(result[FuelType.petrol95], 20.47);
    });

    test('handles integer prices', () {
      final result = parseResponse(
        '{"diesel":20,"petrol_95":21,"petrol_98":null}',
      );
      expect(result[FuelType.diesel], 20.0);
      expect(result[FuelType.petrol95], 21.0);
    });
  });
}
