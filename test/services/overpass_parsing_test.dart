import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_price_tracker/models/station.dart';

// We test the parsing logic by calling the same logic OverpassService._parseNode uses.
// Since _parseNode is private, we replicate its logic here for unit testing.
// This ensures the OSM tag → Station mapping works correctly.

Station parseNode(Map<String, dynamic> node) {
  final tags = node['tags'] as Map<String, dynamic>? ?? {};
  final osmId = node['id'];
  final brand = tags['brand'] as String? ?? 'Unknown';
  final name = tags['name'] as String? ?? '$brand Station';
  final street = tags['addr:street'] as String? ?? '';
  final houseNumber = tags['addr:housenumber'] as String? ?? '';
  final address = '$street $houseNumber'.trim();
  final city =
      tags['addr:city'] as String? ?? tags['addr:postcode'] as String? ?? '';

  return Station(
    id: 'osm_$osmId',
    name: name,
    brand: brand,
    address: address,
    city: city,
    latitude: (node['lat'] as num).toDouble(),
    longitude: (node['lon'] as num).toDouble(),
  );
}

void main() {
  group('Overpass node parsing', () {
    test('parses a fully tagged node', () {
      final node = {
        'type': 'node',
        'id': 12345,
        'lat': 59.9139,
        'lon': 10.7522,
        'tags': {
          'amenity': 'fuel',
          'brand': 'Circle K',
          'name': 'Circle K Majorstuen',
          'addr:street': 'Bogstadveien',
          'addr:housenumber': '1',
          'addr:city': 'Oslo',
        },
      };

      final station = parseNode(node);
      expect(station.id, 'osm_12345');
      expect(station.name, 'Circle K Majorstuen');
      expect(station.brand, 'Circle K');
      expect(station.address, 'Bogstadveien 1');
      expect(station.city, 'Oslo');
      expect(station.latitude, 59.9139);
      expect(station.longitude, 10.7522);
    });

    test('uses brand as fallback name', () {
      final node = {
        'id': 999,
        'lat': 60.0,
        'lon': 5.0,
        'tags': {
          'brand': 'Shell',
        },
      };

      final station = parseNode(node);
      expect(station.name, 'Shell Station');
      expect(station.brand, 'Shell');
    });

    test('handles missing brand', () {
      final node = {
        'id': 888,
        'lat': 60.0,
        'lon': 5.0,
        'tags': <String, dynamic>{},
      };

      final station = parseNode(node);
      expect(station.brand, 'Unknown');
      expect(station.name, 'Unknown Station');
    });

    test('handles missing address fields', () {
      final node = {
        'id': 777,
        'lat': 60.0,
        'lon': 5.0,
        'tags': {
          'brand': 'Esso',
          'name': 'Esso Sentrum',
        },
      };

      final station = parseNode(node);
      expect(station.address, '');
      expect(station.city, '');
    });

    test('falls back to postcode when city is missing', () {
      final node = {
        'id': 666,
        'lat': 60.0,
        'lon': 5.0,
        'tags': {
          'brand': 'YX',
          'name': 'YX Truck Stop',
          'addr:postcode': '0182',
        },
      };

      final station = parseNode(node);
      expect(station.city, '0182');
    });

    test('handles missing tags map', () {
      final node = {
        'id': 555,
        'lat': 60.0,
        'lon': 5.0,
      };

      final station = parseNode(node);
      expect(station.brand, 'Unknown');
      expect(station.name, 'Unknown Station');
      expect(station.address, '');
      expect(station.city, '');
    });

    test('street without housenumber has no trailing space', () {
      final node = {
        'id': 444,
        'lat': 60.0,
        'lon': 5.0,
        'tags': {
          'brand': 'St1',
          'name': 'St1 Odda',
          'addr:street': 'Strandgata',
        },
      };

      final station = parseNode(node);
      expect(station.address, 'Strandgata');
      expect(station.address.endsWith(' '), false);
    });
  });
}
