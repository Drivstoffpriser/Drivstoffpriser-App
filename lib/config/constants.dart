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

import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'TankVenn';
  static const String currencyCode = 'NOK';
  static const String currencySymbol = 'kr';

  // Default map center: Oslo
  static final LatLng defaultMapCenter = LatLng(59.9139, 10.7522);
  static const double defaultMapZoom = 12.0;

  // Overpass API search radius (meters)
  static const int defaultSearchRadiusMeters = 20000;

  // Max distance (meters) from station to submit a price report
  static const double maxReportDistanceMeters = 1000;

  // Price validation range (NOK)
  static const double minFuelPrice = 5.0;
  static const double maxFuelPrice = 50.0;
}
