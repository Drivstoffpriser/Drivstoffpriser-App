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

import 'package:shared_preferences/shared_preferences.dart';

import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/station.dart';

class CacheService {
  static const _allStationsKey = 'cached_all_stations';
  static const _serverLastUpdatedKey = 'stations_server_last_updated';
  static const _pricesCacheKey = 'cached_prices';

  /// TTL for the cross-session price cache.
  static const priceCacheTtl = Duration(hours: 1);

  /// Cache all stations (base data, no prices).
  static Future<void> cacheAllStations(
    List<Station> stations,
    DateTime serverLastUpdated,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(stations.map((s) => s.toJson()).toList());
    await prefs.setString(_allStationsKey, json);
    await prefs.setString(
      _serverLastUpdatedKey,
      serverLastUpdated.toIso8601String(),
    );
  }

  /// Returns cached stations, or null if no cache exists.
  static Future<List<Station>?> getCachedAllStations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_allStationsKey);
    if (json == null) return null;
    final list = jsonDecode(json) as List;
    return list
        .map((e) => Station.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Returns the server's lastUpdatedAt timestamp from the last cache, or null.
  static Future<DateTime?> getStoredLastUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_serverLastUpdatedKey);
    if (raw == null) return null;
    return DateTime.parse(raw);
  }

  /// Remove legacy cache keys from pre-lazy-loading versions of the app.
  static Future<void> clearLegacyCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_stations');
    await prefs.remove('cached_stations_ts');
  }

  /// Persist prices and fetch timestamps for stations that have prices.
  static Future<void> cachePrices(
    Map<String, Station> stations,
    Map<String, DateTime> fetchedAt,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{};
    for (final entry in fetchedAt.entries) {
      final station = stations[entry.key];
      if (station == null || station.prices.isEmpty) continue;
      data[entry.key] = {
        'prices': station.prices.values.map((p) => p.toJson()).toList(),
        'fetchedAt': entry.value.toIso8601String(),
      };
    }
    await prefs.setString(_pricesCacheKey, jsonEncode(data));
  }

  /// Returns cached prices and fetch timestamps, or null if no cache exists.
  static Future<
    ({
      Map<String, Map<FuelType, CurrentPrice>> prices,
      Map<String, DateTime> fetchedAt,
    })?
  >
  getCachedPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pricesCacheKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final prices = <String, Map<FuelType, CurrentPrice>>{};
      final fetchedAt = <String, DateTime>{};
      for (final entry in data.entries) {
        final m = entry.value as Map<String, dynamic>;
        final priceList = (m['prices'] as List)
            .map((p) => CurrentPrice.fromJson(p as Map<String, dynamic>))
            .toList();
        prices[entry.key] = {for (final p in priceList) p.fuelType: p};
        fetchedAt[entry.key] = DateTime.parse(m['fetchedAt'] as String);
      }
      return (prices: prices, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }

  /// Clear the price cache (called on full station refresh).
  static Future<void> clearPriceCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pricesCacheKey);
  }
}
