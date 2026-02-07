import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _position;
  bool _isLoading = false;
  String? _error;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _position != null;

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _position = await _locationService.getCurrentPosition();
      if (_position == null) {
        _error = 'Location permission denied or service disabled.';
      }
    } catch (e) {
      _error = 'Failed to get location: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
