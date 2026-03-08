import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/current_price.dart';
import '../models/station.dart';

class CacheService {
  static const _stationsKey = 'cached_stations';
  static const _pricesKey = 'cached_prices';
  static const _stationsTsKey = 'cached_stations_ts';
  static const _pricesTsKey = 'cached_prices_ts';

  /// Cache TTL — data older than this is considered stale.
  static const _ttl = Duration(minutes: 30);

  static Future<void> cacheStations(List<Station> stations) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(stations.map((s) => s.toJson()).toList());
    await prefs.setString(_stationsKey, json);
    await prefs.setInt(_stationsTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> cachePrices(List<CurrentPrice> prices) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(prices.map((p) => p.toJson()).toList());
    await prefs.setString(_pricesKey, json);
    await prefs.setInt(_pricesTsKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<List<Station>?> getCachedStations() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isFresh(prefs, _stationsTsKey)) return null;
    final json = prefs.getString(_stationsKey);
    if (json == null) return null;
    final list = jsonDecode(json) as List;
    return list.map((e) => Station.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<CurrentPrice>?> getCachedPrices() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_isFresh(prefs, _pricesTsKey)) return null;
    final json = prefs.getString(_pricesKey);
    if (json == null) return null;
    final list = jsonDecode(json) as List;
    return list.map((e) => CurrentPrice.fromJson(e as Map<String, dynamic>)).toList();
  }

  static bool _isFresh(SharedPreferences prefs, String tsKey) {
    final ts = prefs.getInt(tsKey);
    if (ts == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age < _ttl.inMilliseconds;
  }
}
