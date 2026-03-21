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
