import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../models/station.dart';

class OverpassService {
  static const String _baseUrl = 'https://overpass-api.de/api/interpreter';
  static const int _timeoutSeconds = 30;
  static const List<String> _supportedBrands = [
    'Circle K',
    'Shell',
    'Esso',
    'YX',
    'Uno-X',
  ];

  /// Fetches fuel stations from the OSM Overpass API within [radiusMeters]
  /// of the given [lat]/[lng] coordinates.
  ///
  /// Returns an empty list on any failure (network, timeout, parse error).
  static Future<List<Station>> fetchNearbyStations({
    required double lat,
    required double lng,
    int radiusMeters = 50000,
  }) async {
    final brandRegex = _supportedBrands.join('|');
    final query = '[out:json][timeout:$_timeoutSeconds];'
        '(node["amenity"="fuel"]["brand"~"$brandRegex"]'
        '(around:$radiusMeters,$lat,$lng););out body;';

    final uri = Uri.parse(_baseUrl).replace(queryParameters: {'data': query});

    try {
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: _timeoutSeconds + 5));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];

      final stations = elements
          .where((e) => (e as Map<String, dynamic>)['type'] == 'node')
          .map((e) => _parseNode(e as Map<String, dynamic>))
          .toList();

      return _deduplicateByProximity(stations);
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Removes duplicate stations:
  /// - Same name within 500m → clearly the same place
  /// - Same brand within 50m → co-located nodes (fuel + charging)
  static List<Station> _deduplicateByProximity(List<Station> stations) {
    final result = <Station>[];

    for (final station in stations) {
      final isDuplicate = result.any((existing) {
        final dist = _distanceMeters(
          existing.latitude,
          existing.longitude,
          station.latitude,
          station.longitude,
        );
        // Same name within 500m
        if (existing.name == station.name && dist < 500) return true;
        // Same brand within 50m
        if (existing.brand == station.brand && dist < 50) return true;
        return false;
      });

      if (!isDuplicate) result.add(station);
    }

    return result;
  }

  /// Haversine distance in meters between two coordinates.
  static double _distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in meters
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;

  static Station _parseNode(Map<String, dynamic> node) {
    final tags = node['tags'] as Map<String, dynamic>? ?? {};
    final osmId = node['id'];
    final brand = tags['brand'] as String? ?? 'Unknown';
    final name = tags['name'] as String? ?? '$brand Station';
    final street = tags['addr:street'] as String? ?? '';
    final houseNumber = tags['addr:housenumber'] as String? ?? '';
    final address = '$street $houseNumber'.trim();
    final city = tags['addr:city'] as String? ??
        tags['addr:postcode'] as String? ??
        '';

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
}
