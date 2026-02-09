import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _position;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<Position>? _positionSub;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _position != null;

  Future<void> fetchLocation() async {
    if (_positionSub != null) return; // Already listening

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check/request permissions FIRST — must happen before any
      // Geolocator call that requires location access.
      final allowed = await _locationService.checkPermission();
      if (!allowed) {
        _error = 'Location permission denied or service disabled.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Try last-known position for a quick initial fix
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && _position == null) {
        _position = lastKnown;
        _isLoading = false;
        notifyListeners();
      }

      // Get an immediate GPS fix so the map can center right away
      if (_position == null) {
        try {
          final current = await Geolocator.getCurrentPosition();
          _position = current;
          _isLoading = false;
          notifyListeners();
        } catch (_) {
          // Non-fatal — the stream below will provide updates
        }
      }

      // Stream live position updates
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50, // Update every 50 meters of movement
        ),
      ).listen(
        (position) {
          _position = position;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (e) {
          _error = 'Location error: $e';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = 'Failed to get location: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
