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
