import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Check and request location permissions. Returns true if granted.
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    final allowed = await checkPermission();
    if (!allowed) return null;

    return Geolocator.getCurrentPosition();
  }
}
