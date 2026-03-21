import 'package:flutter/foundation.dart';

import '../config/constants.dart';
import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/station.dart';
import '../services/cache_service.dart';
import '../services/distance_service.dart';
import '../services/firestore_service.dart';
import '../services/overpass_service.dart';

enum SortMode { cheapest, nearest, latest }

class StationProvider extends ChangeNotifier {
  List<Station> _stations = [];
  List<CurrentPrice> _prices = [];
  FuelType _selectedFuelType = FuelType.petrol95;
  SortMode _sortMode = SortMode.cheapest;
  Set<String> _selectedBrands = {};
  bool _isLoading = false;

  /// Filter radius in km. null means show all stations (no distance filter).
  double? _filterRadiusKm = 20;

  double? _userLat;
  double? _userLng;

  List<Station> get stations => _stations;
  List<CurrentPrice> get prices => _prices;
  FuelType get selectedFuelType => _selectedFuelType;
  SortMode get sortMode => _sortMode;
  Set<String> get selectedBrands => _selectedBrands;
  bool get isLoading => _isLoading;
  bool get hasUserLocation => _userLat != null && _userLng != null;
  double? get filterRadiusKm => _filterRadiusKm;

  /// Set the filter radius in km. Pass null to show all stations.
  void setFilterRadius(double? km) {
    _filterRadiusKm = km;
    notifyListeners();
  }

  /// Set the user's location for distance-based filtering.
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    notifyListeners();
  }

  /// Stations filtered by radius only (before brand filter).
  Iterable<Station> get _radiusFiltered {
    Iterable<Station> result = _stations;

    if (_filterRadiusKm != null && _userLat != null && _userLng != null) {
      final radiusMeters = _filterRadiusKm! * 1000;
      result = result.where((s) {
        final d = DistanceService.distanceInMeters(
          _userLat!, _userLng!, s.latitude, s.longitude,
        );
        return d <= radiusMeters;
      });
    }

    return result;
  }

  /// Sorted list of unique brand names from stations within the radius
  /// (independent of brand filter so all chips remain visible).
  List<String> get availableBrands {
    final brands = _radiusFiltered.map((s) => s.brand).where((b) => b.isNotEmpty).toSet().toList();
    brands.sort();
    return brands;
  }

  /// Stations filtered by radius (if set) and selected brands.
  List<Station> get filteredStations {
    Iterable<Station> result = _radiusFiltered;

    if (_selectedBrands.isNotEmpty) {
      result = result.where((s) => _selectedBrands.contains(s.brand));
    }

    return result.toList();
  }

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

  /// Load stations and prices. Reads from local cache first; falls back
  /// to Firestore aggregate docs (2 reads) if cache is stale or empty.
  Future<void> loadStations() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try local cache first (0 Firestore reads)
      final cachedStations = await CacheService.getCachedStations();
      final cachedPrices = await CacheService.getCachedPrices();

      if (cachedStations != null && cachedPrices != null) {
        _stations = cachedStations;
        _prices = cachedPrices;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Cache miss — read from Firestore aggregate docs (2 reads)
      await _fetchFromFirestore();
    } catch (e) {
      debugPrint('Failed to load stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Force-refresh from Firestore aggregate docs, bypassing cache.
  Future<void> refreshFromFirestore() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchFromFirestore();
    } catch (e) {
      debugPrint('Failed to refresh from Firestore: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchFromFirestore() async {
    final stations = await FirestoreService.getStations();
    final prices = await FirestoreService.getPrices();

    _stations = stations;
    _prices = prices;

    // Update local cache
    await CacheService.cacheStations(stations);
    await CacheService.cachePrices(prices);
  }

  /// Fetch stations from Overpass near [lat],[lng] and upsert into Firestore.
  /// Then refresh local data from Firestore.
  Future<void> fetchNearbyStations(double lat, double lng) async {
    try {
      final stations = await OverpassService.fetchNearbyStations(
        lat: lat,
        lng: lng,
        radiusMeters: AppConstants.defaultSearchRadiusMeters,
      );
      if (stations.isNotEmpty) {
        await FirestoreService.upsertStations(stations);
      } else {
        await FirestoreService.seedIfEmpty();
      }
    } catch (e) {
      debugPrint('Failed to fetch nearby stations: $e');
      await FirestoreService.seedIfEmpty();
    }
    await refreshFromFirestore();
  }

  /// Fetch ALL fuel stations in Norway from Overpass and upsert into Firestore.
  /// Serves cached/aggregate data immediately (≤2 reads), then refreshes from
  /// Overpass in the background and updates the UI when done.
  Future<void> fetchAllNorwayStations() async {
    // 1. Show cached or aggregate data immediately so the UI isn't empty.
    if (_stations.isEmpty) {
      await loadStations();
    }

    // 2. Fetch from Overpass and update Firestore + local state.
    try {
      final stations = await OverpassService.fetchAllNorwayStations();
      debugPrint('Overpass returned ${stations.length} Norway stations');
      if (stations.isNotEmpty) {
        await FirestoreService.upsertStations(stations);
      } else {
        await FirestoreService.seedIfEmpty();
      }
    } catch (e) {
      debugPrint('Failed to fetch/save Norway stations: $e');
      try {
        await FirestoreService.seedIfEmpty();
      } catch (e2) {
        debugPrint('Seed fallback also failed: $e2');
      }
    }
    await refreshFromFirestore();
  }

  void setFuelType(FuelType type) {
    _selectedFuelType = type;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  /// Get the current price for a station and the selected fuel type.
  CurrentPrice? getPriceForStation(String stationId) {
    try {
      return _prices.firstWhere(
        (p) => p.stationId == stationId && p.fuelType == _selectedFuelType,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all prices for a specific station.
  List<CurrentPrice> getPricesForStation(String stationId) {
    return _prices.where((p) => p.stationId == stationId).toList();
  }

  /// Stations filtered by brand and sorted by the current sort mode.
  /// Shows all stations; those with prices sort first.
  List<Station> sortedStations({double? userLat, double? userLng}) {
    final all = List<Station>.from(filteredStations);

    switch (_sortMode) {
      case SortMode.cheapest:
        all.sort((a, b) {
          final pa = getPriceForStation(a.id);
          final pb = getPriceForStation(b.id);
          // Stations with prices come first
          if (pa == null && pb == null) return a.name.compareTo(b.name);
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.price.compareTo(pb.price);
        });
      case SortMode.nearest:
        if (userLat != null && userLng != null) {
          all.sort((a, b) {
            final da = DistanceService.distanceInMeters(
              userLat, userLng, a.latitude, a.longitude,
            );
            final db = DistanceService.distanceInMeters(
              userLat, userLng, b.latitude, b.longitude,
            );
            return da.compareTo(db);
          });
        } else {
          all.sort((a, b) => a.name.compareTo(b.name));
        }
      case SortMode.latest:
        all.sort((a, b) {
          final pa = getPriceForStation(a.id);
          final pb = getPriceForStation(b.id);
          if (pa == null && pb == null) return a.name.compareTo(b.name);
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pb.updatedAt.compareTo(pa.updatedAt);
        });
    }

    return all;
  }
}
