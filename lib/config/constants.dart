import 'package:latlong2/latlong.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Fuel Price Tracker';
  static const String currencyCode = 'NOK';
  static const String currencySymbol = 'kr';

  // Default map center: Oslo
  static final LatLng defaultMapCenter = LatLng(59.9139, 10.7522);
  static const double defaultMapZoom = 12.0;

  // Overpass API search radius (meters)
  static const int defaultSearchRadiusMeters = 30000;

  // Max distance (meters) from station to submit a price report
  static const double maxReportDistanceMeters = 150;

  // Price validation range (NOK)
  static const double minFuelPrice = 5.0;
  static const double maxFuelPrice = 50.0;
}
