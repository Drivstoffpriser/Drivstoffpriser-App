import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/station.dart';
import '../services/distance_service.dart';
import '../services/firestore_service.dart';

enum SortMode { cheapest, nearest }

class StationProvider extends ChangeNotifier {
  List<Station> _stations = [];
  List<CurrentPrice> _prices = [];
  FuelType _selectedFuelType = FuelType.diesel;
  SortMode _sortMode = SortMode.cheapest;
  bool _isLoading = false;

  StreamSubscription? _stationsSub;
  StreamSubscription? _pricesSub;

  List<Station> get stations => _stations;
  List<CurrentPrice> get prices => _prices;
  FuelType get selectedFuelType => _selectedFuelType;
  SortMode get sortMode => _sortMode;
  bool get isLoading => _isLoading;

  Future<void> loadStations() async {
    _isLoading = true;
    notifyListeners();

    // Cancel any existing subscriptions
    await _stationsSub?.cancel();
    await _pricesSub?.cancel();

    _stationsSub = FirestoreService.stationsStream().listen((stations) {
      _stations = stations;
      _isLoading = false;
      notifyListeners();
    });

    _pricesSub = FirestoreService.currentPricesStream().listen((prices) {
      _prices = prices;
      notifyListeners();
    });
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

  /// Stations sorted by the current sort mode.
  /// Shows all stations; those with prices sort first.
  List<Station> sortedStations({double? userLat, double? userLng}) {
    final all = List<Station>.from(_stations);

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
    }

    return all;
  }

  @override
  void dispose() {
    _stationsSub?.cancel();
    _pricesSub?.cancel();
    super.dispose();
  }
}
