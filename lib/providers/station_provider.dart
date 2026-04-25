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

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/fuel_type.dart';
import '../models/station.dart';
import '../services/backend_api_client.dart';
import '../services/cache_service.dart';
import '../services/distance_service.dart';
import '../services/favorite_service.dart';
import '../services/firestore_service.dart';
import '../widgets/brand_logo.dart';

enum SortMode { cheapest, nearest, latest }

class StationProvider extends ChangeNotifier {
  /// All stations keyed by ID — the single source of truth.
  Map<String, Station> _allStations = {};

  /// Tracks when prices were last fetched per station.
  final Map<String, DateTime> _priceFetchedAt = {};

  /// Station IDs currently being fetched — prevents duplicate requests.
  final Set<String> _priceLoadingIds = {};

  static const _priceTtl = Duration(minutes: 5);
  static const _priceBatchSize = 50;

  /// Stations fetched from `GET /stations` for list view (sorted by backend).
  /// Used for cheapest/latest sort modes which need server-side ordering.
  List<Station> _listStations = [];
  bool _isListLoading = false;

  String? _bestMapStationId;
  FuelType _selectedFuelType = FuelType.petrol95;
  SortMode _sortMode = SortMode.cheapest;
  Set<String> _selectedBrands = {};
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  Set<String> _favoriteStationIds = {};

  /// Completer for waiting on auth before fetching stations.
  Completer<void>? _authCompleter;

  /// Map radius in km. null means show all stations ("All of Norway").
  double? _mapRadiusKm;

  /// Station list radius in km. null means show all stations.
  double? _listRadiusKm = 20;

  double? _userLat;
  double? _userLng;

  List<Station> get stations => _allStations.values.toList();
  FuelType get selectedFuelType => _selectedFuelType;
  SortMode get sortMode => _sortMode;
  Set<String> get selectedBrands => _selectedBrands;
  bool get isLoading => _isLoading;
  bool get hasUserLocation => _userLat != null && _userLng != null;
  double? get mapRadiusKm => _mapRadiusKm;
  double? get listRadiusKm => _listRadiusKm;
  bool get showFavoritesOnly => _showFavoritesOnly;
  Set<String> get favoriteStationIds => _favoriteStationIds;
  bool get isListLoading => _isListLoading;

  /// Look up a station by ID.
  Station? getStation(String id) => _allStations[id];

  // ── Initialization ────────────────────────────────────────────────────────

  /// Initialize station data. Loads from cache first, then checks if
  /// the backend has newer data via `/stations/last-updated`.
  /// Call `onAuthReady()` once auth is established so the provider
  /// can fetch from the backend if needed.
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    _authCompleter = Completer<void>();

    try {
      // 1. Load cached stations immediately for fast UI.
      CacheService.clearLegacyCache(); // one-time migration, not awaited
      final cached = await CacheService.getCachedAllStations();
      if (cached != null) {
        _allStations = {for (final s in cached) s.id: s};
        notifyListeners();
      }

      // 2. Check server timestamp (no auth needed).
      final client = BackendApiClient();
      DateTime? serverLastUpdated;
      try {
        serverLastUpdated = await client.getStationsLastUpdated();
      } catch (e) {
        debugPrint('Failed to check last-updated: $e');
      }

      // 3. Compare with stored timestamp.
      final storedLastUpdated = await CacheService.getStoredLastUpdatedAt();
      final needsFetch =
          serverLastUpdated != null &&
          (storedLastUpdated == null || serverLastUpdated != storedLastUpdated);

      if (needsFetch) {
        // Wait for auth before making the authenticated call.
        await _authCompleter!.future;
        final stations = await client.getAllStations();
        _allStations = {for (final s in stations) s.id: s};
        await CacheService.cacheAllStations(stations, serverLastUpdated);
      }

      // Load brand logos.
      try {
        final logos = await FirestoreService.getBrandLogos();
        BrandLogo.setRemoteLogos(logos);
      } catch (_) {
        // Non-critical — local assets still work.
      }
    } catch (e) {
      debugPrint('Failed to initialize stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signal that Firebase auth is ready. Unblocks `initialize()` if
  /// it's waiting to fetch stations from the backend.
  void onAuthReady() {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete();
    }
  }

  // ── Price loading ─────────────────────────────────────────────────────────

  /// Fetch prices for the given station IDs.
  /// Skips stations whose prices are still fresh or already being fetched.
  Future<void> loadPricesForStations(List<String> stationIds) async {
    final now = DateTime.now();
    final needed = stationIds.where((id) {
      if (_priceLoadingIds.contains(id)) return false;
      final fetchedAt = _priceFetchedAt[id];
      if (fetchedAt != null && now.difference(fetchedAt) < _priceTtl) {
        return false;
      }
      return _allStations.containsKey(id);
    }).toList();

    if (needed.isEmpty) return;

    _priceLoadingIds.addAll(needed);
    notifyListeners();

    try {
      final client = BackendApiClient();
      // Batch into chunks to avoid URL length limits.
      for (var i = 0; i < needed.length; i += _priceBatchSize) {
        final chunk = needed.sublist(
          i,
          i + _priceBatchSize > needed.length
              ? needed.length
              : i + _priceBatchSize,
        );
        final priceMap = await client.getStationPrices(chunk);
        for (final entry in priceMap.entries) {
          final station = _allStations[entry.key];
          if (station != null) {
            _allStations[entry.key] = station.copyWithPrices(entry.value);
            _priceFetchedAt[entry.key] = DateTime.now();
          }
        }
        // Also mark stations that returned no prices as fetched.
        for (final id in chunk) {
          _priceFetchedAt.putIfAbsent(id, () => DateTime.now());
        }
        _priceLoadingIds.removeAll(chunk);
        _recomputeBestMapStation();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load prices: $e');
    } finally {
      final hadLoading = _priceLoadingIds.any(needed.contains);
      _priceLoadingIds.removeAll(needed);
      if (hadLoading) notifyListeners();
    }
  }

  /// True if a price fetch is currently in-flight for this station.
  bool isPriceLoading(String id) => _priceLoadingIds.contains(id);

  // ── Favorites ─────────────────────────────────────────────────────────────

  Future<void> loadFavorites() async {
    _favoriteStationIds = await FavoriteService.getFavorites();
    notifyListeners();
  }

  Future<void> toggleFavorite(String stationId) async {
    final wasFavorite = _favoriteStationIds.contains(stationId);
    if (wasFavorite) {
      _favoriteStationIds.remove(stationId);
    } else {
      _favoriteStationIds.add(stationId);
    }
    notifyListeners();
    try {
      if (wasFavorite) {
        await FavoriteService.removeFavorite(stationId);
      } else {
        await FavoriteService.addFavorite(stationId);
      }
    } catch (e) {
      // Roll back on failure
      if (wasFavorite) {
        _favoriteStationIds.add(stationId);
      } else {
        _favoriteStationIds.remove(stationId);
      }
      notifyListeners();
      rethrow;
    }
  }

  bool isFavorite(String stationId) => _favoriteStationIds.contains(stationId);

  void setShowFavoritesOnly(bool value) {
    _showFavoritesOnly = value;
    notifyListeners();
  }

  // ── Location & Radius ─────────────────────────────────────────────────────

  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    notifyListeners();
  }

  void setMapRadius(double? km) {
    _mapRadiusKm = km;
    notifyListeners();
  }

  void setListRadius(double? km, {double? userLat, double? userLng}) {
    _listRadiusKm = km;
    if (userLat != null && userLng != null) {
      _userLat = userLat;
      _userLng = userLng;
    }
    notifyListeners();
    loadSortedStations();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  Iterable<Station> _filterByRadius(double? radiusKm) {
    Iterable<Station> result = _allStations.values;

    if (radiusKm != null && _userLat != null && _userLng != null) {
      final radiusMeters = radiusKm * 1000;
      result = result.where((s) {
        final d = DistanceService.distanceInMeters(
          _userLat!,
          _userLng!,
          s.latitude,
          s.longitude,
        );
        return d <= radiusMeters;
      });
    }

    return result;
  }

  Iterable<Station> _applyBrandAndFavFilter(Iterable<Station> source) {
    if (_selectedBrands.isNotEmpty) {
      source = source.where((s) => _selectedBrands.contains(s.brand));
    }
    if (_showFavoritesOnly) {
      source = source.where((s) => _favoriteStationIds.contains(s.id));
    }
    return source;
  }

  /// Brands available within the map radius.
  List<String> get mapAvailableBrands {
    final brands = _filterByRadius(
      _mapRadiusKm,
    ).map((s) => s.brand).where((b) => b.isNotEmpty).toSet().toList();
    brands.sort();
    return brands;
  }

  /// Brands available within the station list radius.
  List<String> get listAvailableBrands {
    final brands = _filterByRadius(
      _listRadiusKm,
    ).map((s) => s.brand).where((b) => b.isNotEmpty).toSet().toList();
    brands.sort();
    return brands;
  }

  /// Stations filtered by station list radius and selected brands.
  List<Station> get filteredStations {
    return _applyBrandAndFavFilter(_filterByRadius(_listRadiusKm)).toList();
  }

  /// Stations filtered by map radius and selected brands.
  List<Station> get brandFilteredStations {
    return _applyBrandAndFavFilter(_filterByRadius(_mapRadiusKm)).toList();
  }

  String? get bestMapStationId => _bestMapStationId;

  void _recomputeBestMapStation() {
    String? bestId;
    double bestPrice = double.infinity;
    for (final station in _allStations.values) {
      final p = station.prices[_selectedFuelType];
      if (p != null && p.price < bestPrice) {
        bestPrice = p.price;
        bestId = station.id;
      }
    }
    _bestMapStationId = bestId;
  }

  // ── Sorting & Fuel Type ───────────────────────────────────────────────────

  void toggleBrand(String brand) {
    _selectedBrands = Set.of(_selectedBrands);
    if (_selectedBrands.contains(brand)) {
      _selectedBrands.remove(brand);
    } else {
      _selectedBrands.add(brand);
    }
    notifyListeners();
  }

  void clearBrandFilter() {
    _selectedBrands = {};
    notifyListeners();
  }

  void setFuelType(FuelType type) {
    _selectedFuelType = type;
    _recomputeBestMapStation();
    notifyListeners();
    if (_sortMode != SortMode.nearest) {
      loadSortedStations();
    }
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
    loadSortedStations();
  }

  /// Fetch stations with prices from `GET /stations`, pre-sorted by the
  /// backend. Used for the station list's cheapest/latest tabs.
  Future<void> loadSortedStations() async {
    _isListLoading = true;
    notifyListeners();

    try {
      final client = BackendApiClient();
      final lat = _userLat ?? 65.0;
      final lng = _userLng ?? 17.0;
      final double distance;
      if (_userLat != null && _listRadiusKm != null) {
        distance = _listRadiusKm! * 1000;
      } else {
        distance = 2500000.0;
      }
      _listStations = await client.getStations(
        lat: lat,
        lng: lng,
        distance: distance,
        sort: switch (_sortMode) {
          SortMode.cheapest => 'cheapest',
          SortMode.nearest => 'nearest',
          SortMode.latest => 'latest',
        },
        fuelType: _sortMode == SortMode.nearest
            ? null
            : _selectedFuelType.backendString,
      );

      // Merge fetched prices into _allStations so other screens benefit.
      for (final s in _listStations) {
        if (s.prices.isNotEmpty) {
          final existing = _allStations[s.id];
          if (existing != null) {
            _allStations[s.id] = existing.copyWithPrices(s.prices);
            _priceFetchedAt[s.id] = DateTime.now();
          }
        }
      }
      _recomputeBestMapStation();
    } catch (e) {
      debugPrint('Failed to load sorted stations: $e');
    } finally {
      _isListLoading = false;
      notifyListeners();
    }
  }

  /// Returns stations for the list view.
  /// For cheapest/latest: uses `_listStations` (server-sorted with prices).
  /// For nearest: sorts `_allStations` client-side by distance.
  List<Station> sortedStations({double? userLat, double? userLng}) {
    if (_sortMode != SortMode.nearest) {
      // Use server-sorted list, applying brand/favorites filter.
      return _applyBrandAndFavFilter(_listStations).toList();
    }

    // Nearest: sort locally from all stations.
    final list = filteredStations;
    final lat = userLat ?? _userLat;
    final lng = userLng ?? _userLng;

    if (lat != null && lng != null) {
      list.sort((a, b) {
        final da = DistanceService.distanceInMeters(
          lat,
          lng,
          a.latitude,
          a.longitude,
        );
        final db = DistanceService.distanceInMeters(
          lat,
          lng,
          b.latitude,
          b.longitude,
        );
        return da.compareTo(db);
      });
    }
    return list;
  }

  // ── Search ────────────────────────────────────────────────────────────────

  /// Search all stations client-side by name, brand, address, or city.
  List<Station> searchStations(String query) {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    return _allStations.values.where((s) {
      return s.name.toLowerCase().contains(lower) ||
          s.brand.toLowerCase().contains(lower) ||
          s.address.toLowerCase().contains(lower) ||
          s.city.toLowerCase().contains(lower);
    }).toList();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  /// Invalidate the price cache for a single station, forcing the next
  /// [loadPricesForStations] call to re-fetch from the backend.
  void invalidatePriceCache(String stationId) {
    _priceFetchedAt.remove(stationId);
  }

  /// Re-fetch all stations unconditionally and clear price cache.
  Future<void> refreshStations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final client = BackendApiClient();
      final stations = await client.getAllStations();
      _allStations = {for (final s in stations) s.id: s};
      _priceFetchedAt.clear();
      _listStations = [];

      final serverLastUpdated = await client.getStationsLastUpdated();
      if (serverLastUpdated != null) {
        await CacheService.cacheAllStations(stations, serverLastUpdated);
      }

      try {
        final logos = await FirestoreService.getBrandLogos();
        BrandLogo.setRemoteLogos(logos);
      } catch (_) {}
    } catch (e) {
      debugPrint('Failed to refresh stations: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
