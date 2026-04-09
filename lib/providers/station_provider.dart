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
import '../models/station.dart';
import '../services/backend_api_client.dart';
import '../services/cache_service.dart';
import '../services/distance_service.dart';
import '../services/favorite_service.dart';
import '../services/firestore_service.dart';
import '../widgets/brand_logo.dart';

enum SortMode { cheapest, nearest, latest }

class StationProvider extends ChangeNotifier {
  List<Station> _stations = [];

  // Separate state for the map view, populated by bbox fetches.
  List<Station> _mapStations = [];
  String? _bestMapStationId;
  FuelType _selectedFuelType = FuelType.petrol95;
  SortMode _sortMode = SortMode.cheapest;
  Set<String> _selectedBrands = {};
  bool _isLoading = false;
  bool _showFavoritesOnly = false;
  Set<String> _favoriteStationIds = {};

  /// Map radius in km. null means show all stations ("All of Norway").
  double? _mapRadiusKm;

  /// Station list radius in km. null means show all stations.
  double? _listRadiusKm = 20;

  double? _userLat;
  double? _userLng;

  List<Station> get stations => _stations;
  FuelType get selectedFuelType => _selectedFuelType;
  SortMode get sortMode => _sortMode;
  Set<String> get selectedBrands => _selectedBrands;
  bool get isLoading => _isLoading;
  bool get hasUserLocation => _userLat != null && _userLng != null;
  double? get mapRadiusKm => _mapRadiusKm;
  double? get listRadiusKm => _listRadiusKm;
  bool get showFavoritesOnly => _showFavoritesOnly;
  Set<String> get favoriteStationIds => _favoriteStationIds;

  /// Set the map filter radius in km. Pass null to show all stations.
  void setMapRadius(double? km) {
    _mapRadiusKm = km;
    notifyListeners();
  }

  /// Set the station list filter radius in km. Pass null to show all stations.
  void setListRadius(double? km) {
    _listRadiusKm = km;
    notifyListeners();
  }

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

  /// Set the user's location for distance-based filtering.
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    notifyListeners();
  }

  /// Filter stations by a given radius in km.
  Iterable<Station> _filterByRadius(double? radiusKm) {
    Iterable<Station> result = _stations;

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
    Iterable<Station> result = _filterByRadius(_listRadiusKm);

    if (_selectedBrands.isNotEmpty) {
      result = result.where((s) => _selectedBrands.contains(s.brand));
    }

    if (_showFavoritesOnly) {
      result = result.where((s) => _favoriteStationIds.contains(s.id));
    }

    return result.toList();
  }

  /// Stations filtered by map radius and selected brands.
  /// Used by the map to show stations.
  List<Station> get brandFilteredStations {
    Iterable<Station> result = _filterByRadius(_mapRadiusKm);

    if (_selectedBrands.isNotEmpty) {
      result = result.where((s) => _selectedBrands.contains(s.brand));
    }

    if (_showFavoritesOnly) {
      result = result.where((s) => _favoriteStationIds.contains(s.id));
    }

    return result.toList();
  }

  String? get bestMapStationId => _bestMapStationId;

  void _recomputeBestMapStation() {
    String? bestId;
    double bestPrice = double.infinity;
    for (final station in _mapStations) {
      final p = station.prices[_selectedFuelType];
      if (p != null && p.price < bestPrice) {
        bestPrice = p.price;
        bestId = station.id;
      }
    }
    _bestMapStationId = bestId;
  }

  /// Stations from the last bbox fetch, filtered by brand/favorites.
  /// Used exclusively by the map screen.
  List<Station> get mapStations {
    Iterable<Station> result = _mapStations;

    if (_selectedBrands.isNotEmpty) {
      result = result.where((s) => _selectedBrands.contains(s.brand));
    }

    if (_showFavoritesOnly) {
      result = result.where((s) => _favoriteStationIds.contains(s.id));
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

  /// Load stations and prices from the backend API.
  /// Called on app startup.
  Future<void> loadStations() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchFromBackend();
    } catch (e) {
      debugPrint('Failed to load stations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Re-fetch stations and prices from the backend.
  Future<void> refreshStations() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _fetchFromBackend();
    } catch (e) {
      debugPrint('Failed to refresh stations: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStationsByBbox({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    try {
      final client = BackendApiClient();
      _mapStations = await client.getStationsByBbox(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
      );
      _recomputeBestMapStation();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load stations by bbox: $e');
    }
  }

  Future<void> _fetchFromBackend() async {
    final client = BackendApiClient();
    // Use user location if available; fall back to Norway center + full-country radius.
    final lat = _userLat ?? 65.0;
    final lng = _userLng ?? 17.0;
    final distance = _userLat != null ? 200000.0 : 2500000.0;
    _stations = await client.getStations(
      lat: lat,
      lng: lng,
      distance: distance,
    );

    await CacheService.cacheStations(_stations);

    // Load remote brand logos and update BrandLogo cache
    try {
      final logos = await FirestoreService.getBrandLogos();
      BrandLogo.setRemoteLogos(logos);
    } catch (_) {
      // Non-critical — local assets still work
    }
  }

  void setFuelType(FuelType type) {
    _selectedFuelType = type;
    _recomputeBestMapStation();
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    _sortMode = mode;
    notifyListeners();
  }

  /// Stations filtered by brand and sorted by the current sort mode.
  /// Shows all stations; those with prices sort first.
  List<Station> sortedStations({double? userLat, double? userLng}) {
    final all = List<Station>.from(filteredStations);

    switch (_sortMode) {
      case SortMode.cheapest:
        all.sort((a, b) {
          final pa = a.prices[_selectedFuelType];
          final pb = b.prices[_selectedFuelType];
          if (pa == null && pb == null) return a.name.compareTo(b.name);
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.price.compareTo(pb.price);
        });
      case SortMode.nearest:
        if (userLat != null && userLng != null) {
          all.sort((a, b) {
            final da = DistanceService.distanceInMeters(
              userLat,
              userLng,
              a.latitude,
              a.longitude,
            );
            final db = DistanceService.distanceInMeters(
              userLat,
              userLng,
              b.latitude,
              b.longitude,
            );
            return da.compareTo(db);
          });
        } else {
          all.sort((a, b) => a.name.compareTo(b.name));
        }
      case SortMode.latest:
        all.sort((a, b) {
          final pa = a.prices[_selectedFuelType];
          final pb = b.prices[_selectedFuelType];
          if (pa == null && pb == null) return a.name.compareTo(b.name);
          if (pa == null) return 1;
          if (pb == null) return -1;
          final paTime = pa.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final pbTime = pb.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return pbTime.compareTo(paTime);
        });
    }

    return all;
  }
}
