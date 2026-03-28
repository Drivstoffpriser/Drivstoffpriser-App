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

  LocationResult? _lastResult;
  LocationResult? get lastResult => _lastResult;

  Future<void> fetchLocation() async {
    if (_positionSub != null) return; // Already listening

    _isLoading = true;
    _error = null;
    _lastResult = null;
    notifyListeners();

    try {
      // Check/request permissions FIRST — must happen before any
      // Geolocator call that requires location access.
      final result = await _locationService.checkPermission();
      _lastResult = result;
      if (result != LocationResult.granted) {
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
      _positionSub =
          Geolocator.getPositionStream(
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
