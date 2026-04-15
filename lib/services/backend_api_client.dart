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

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/price_history_point.dart';
import '../models/price_report.dart';
import '../models/station.dart';

/// Thrown when the backend returns a non-2xx response.
class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class BackendApiClient {
  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      _uri(path),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    return _decodeMap(response);
  }

  Future<void> postVoid(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      _uri(path),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    _checkStatus(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await http.get(
      _uri(path, queryParams: queryParams),
      headers: await _authHeaders(),
    );
    return _decodeMap(response);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await http.get(
      _uri(path, queryParams: queryParams),
      headers: await _authHeaders(),
    );
    _checkStatus(response);
    return jsonDecode(response.body) as List<dynamic>;
  }

  Future<void> delete(String path, Map<String, dynamic> body) async {
    final response = await http.delete(
      _uri(path),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );
    _checkStatus(response);
  }

  // ── Domain methods ────────────────────────────────────────────────────────

  Future<List<Station>> getStations({
    required double lat,
    required double lng,
    required double distance,
    String sort = 'nearest',
    String? fuelType,
  }) async {
    final params = <String, String>{
      'lat': lat.toString(),
      'lng': lng.toString(),
      'distance': distance.toString(),
      'sort': sort,
    };
    if (fuelType != null) params['fuelType'] = fuelType;
    final data = await get('/stations', queryParams: params);
    final raw = data['stations'] as List<dynamic>;
    return [
      for (final item in raw)
        Station.fromBackendJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> registerPrices(
    String stationId,
    List<({FuelType fuelType, double price})> registrations,
  ) async {
    await postVoid('/stations/$stationId/prices', {
      'registrations': [
        for (final r in registrations)
          {'fuelType': r.fuelType.backendString, 'price': r.price},
      ],
    });
  }

  Future<Set<String>> getFavorites() async {
    final data = await get('/favorites');
    final ids = data['stationIds'] as List<dynamic>;
    return ids.cast<String>().toSet();
  }

  Future<void> addFavorite(String stationId) async {
    await postVoid('/favorites', {'stationId': stationId});
  }

  Future<void> removeFavorite(String stationId) async {
    await delete('/favorites', {'stationId': stationId});
  }

  Future<int> getPriceRegistrations() async {
    final data = await get('/users/price-registrations');
    return data['total'] as int;
  }

  Future<
    ({
      Map<FuelType, List<PriceHistoryPoint>> history,
      List<PriceReport> recentUpdates,
    })
  >
  getPriceHistory(String stationId) async {
    final data = await get('/stations/$stationId/history');

    final historyRaw = data['history'] as Map<String, dynamic>;
    final history = <FuelType, List<PriceHistoryPoint>>{};
    for (final entry in historyRaw.entries) {
      final fuelType = FuelType.fromBackendString(entry.key);
      final points = (entry.value as List<dynamic>).map((p) {
        final map = p as Map<String, dynamic>;
        return PriceHistoryPoint(
          date: DateTime.parse(map['date'] as String),
          price: _toDouble(map['averagePrice']),
        );
      }).toList();
      if (points.isNotEmpty) history[fuelType] = points;
    }

    final recentRaw = data['recentUpdates'] as List<dynamic>;
    final recentUpdates = recentRaw.map((r) {
      final map = r as Map<String, dynamic>;
      return PriceReport(
        id: map['id'] as String,
        stationId: stationId,
        fuelType: FuelType.fromBackendString(map['fuelType'] as String),
        price: _toDouble(map['price']),
        userId: '',
        reportedAt: DateTime.parse(map['registeredAt'] as String),
      );
    }).toList();

    return (history: history, recentUpdates: recentUpdates);
  }

  /// GET /stations/last-updated — no auth required.
  Future<DateTime?> getStationsLastUpdated() async {
    final response = await http.get(_uri('/stations/last-updated'));
    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['lastUpdatedAt'];
    return raw != null ? DateTime.parse(raw as String) : null;
  }

  /// GET /stations/all — returns all stations without prices.
  Future<List<Station>> getAllStations() async {
    final data = await get('/stations/all');
    final raw = data['stations'] as List<dynamic>;
    return [
      for (final item in raw)
        Station.fromBaseJson(item as Map<String, dynamic>),
    ];
  }

  /// GET /stations/prices?stationIds=id1&stationIds=id2...
  /// Returns prices keyed by station ID.
  Future<Map<String, Map<FuelType, CurrentPrice>>> getStationPrices(
    List<String> stationIds,
  ) async {
    final queryString = stationIds.map((id) => 'stationIds=$id').join('&');
    final uri = Uri.parse(
      '${BackendConfig.baseUrl}/stations/prices?$queryString',
    );
    final response = await http.get(uri, headers: await _authHeaders());
    _checkStatus(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['stations'] as List<dynamic>;

    final result = <String, Map<FuelType, CurrentPrice>>{};
    for (final item in raw) {
      final map = item as Map<String, dynamic>;
      final stationId = map['stationId'] as String;
      final prices = <FuelType, CurrentPrice>{};
      for (final p in (map['prices'] as List<dynamic>)) {
        final price = CurrentPrice.fromBackendJson(
          stationId,
          p as Map<String, dynamic>,
        );
        prices[price.fuelType] = price;
      }
      result[stationId] = prices;
    }
    return result;
  }

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.parse(v.toString());

  // ── Internal helpers ──────────────────────────────────────────────────────

  Uri _uri(String path, {Map<String, String>? queryParams}) {
    final base = BackendConfig.baseUrl;
    final uri = Uri.parse('$base$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw const ApiException(401, 'User not signed in');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  void _checkStatus(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        response.reasonPhrase ?? 'Unknown error',
      );
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    _checkStatus(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
