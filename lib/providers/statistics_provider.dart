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

import 'package:flutter/foundation.dart';

import '../models/fuel_type.dart';
import '../models/price_statistics.dart';
import '../services/backend_api_client.dart';

class StatisticsProvider extends ChangeNotifier {
  PriceStatistics? _statistics;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  Map<String, Map<FuelType, List<ProviderPriceDayPoint>>>? _providerPrices;
  Map<String, Map<FuelType, double>>? _providerLast24h;
  bool _isLoadingProviderPrices = false;

  ContributorStats? _contributors;
  bool _isLoadingContributors = false;
  String? _contributorsError;

  PriceStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;

  /// True when data is being refreshed in the background (existing data still shown).
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;

  Map<String, Map<FuelType, List<ProviderPriceDayPoint>>>? get providerPrices =>
      _providerPrices;
  Map<String, Map<FuelType, double>>? get providerLast24h => _providerLast24h;
  bool get isLoadingProviderPrices => _isLoadingProviderPrices;

  ContributorStats? get contributors => _contributors;
  bool get isLoadingContributors => _isLoadingContributors;
  String? get contributorsError => _contributorsError;

  Future<void> fetchStatistics({
    double? lat,
    double? lng,
    double? radiusKm,
  }) async {
    if (_statistics != null) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final client = BackendApiClient();
      final hasLocation = lat != null && lng != null;
      final distanceMeters = radiusKm != null ? radiusKm * 1000 : null;

      final futures = await Future.wait([
        client.getStatistics(),
        if (hasLocation)
          client.getNearestStatistics(
            lat: lat,
            lng: lng,
            distanceMeters: distanceMeters,
          ),
      ]);

      final latest = futures[0] as PriceStatistics;
      final nearby = hasLocation
          ? futures[1] as Map<FuelType, PriceExtremes>
          : <FuelType, PriceExtremes>{};

      _statistics = PriceStatistics(
        allStationsExtremes: latest.allStationsExtremes,
        nearbyStationsExtremes: nearby,
        activity: latest.activity,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> fetchProviderPrices({bool refresh = false}) async {
    if (_providerPrices != null && !refresh) return;
    if (refresh) {
      _providerPrices = null;
      _providerLast24h = null;
    }
    _isLoadingProviderPrices = true;
    notifyListeners();
    try {
      final result = await BackendApiClient().getProviderPrices();
      _providerPrices = result.prices;
      _providerLast24h = result.last24h;
    } catch (_) {
      // silently fail — UI shows empty state
    } finally {
      _isLoadingProviderPrices = false;
      notifyListeners();
    }
  }

  Future<void> fetchContributors({bool refresh = false}) async {
    if (_contributors != null && !refresh) return;
    _isLoadingContributors = true;
    _contributorsError = null;
    notifyListeners();
    try {
      _contributors = await BackendApiClient().getContributors();
    } catch (e) {
      _contributorsError = e.toString();
    } finally {
      _isLoadingContributors = false;
      notifyListeners();
    }
  }
}
