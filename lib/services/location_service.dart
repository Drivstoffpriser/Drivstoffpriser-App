import 'package:geolocator/geolocator.dart';

enum LocationResult { granted, serviceDisabled, denied, deniedForever }

class LocationService {
  /// Check and request location permissions.
  Future<LocationResult> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationResult.serviceDisabled;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.denied;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.deniedForever;
    }

    return LocationResult.granted;
  }

  Future<Position?> getCurrentPosition() async {
    final result = await checkPermission();
    if (result != LocationResult.granted) return null;

    return Geolocator.getCurrentPosition();
  }
}
