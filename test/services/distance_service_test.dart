import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_price_tracker/services/distance_service.dart';

void main() {
  group('DistanceService.distanceInMeters', () {
    test('same point returns 0', () {
      final d = DistanceService.distanceInMeters(59.91, 10.75, 59.91, 10.75);
      expect(d, 0.0);
    });

    test('Oslo to Bergen is approximately 305 km', () {
      // Oslo (59.9139, 10.7522) to Bergen (60.3913, 5.3221)
      final d = DistanceService.distanceInMeters(
        59.9139, 10.7522, 60.3913, 5.3221,
      );
      // Straight-line distance is ~305 km
      expect(d, greaterThan(300000));
      expect(d, lessThan(310000));
    });

    test('short distance is accurate', () {
      // Two points ~1 km apart in Oslo
      final d = DistanceService.distanceInMeters(
        59.9139, 10.7522, 59.9229, 10.7522,
      );
      // ~1000m (purely north, 0.009 degrees latitude)
      expect(d, greaterThan(900));
      expect(d, lessThan(1100));
    });

    test('distance is symmetric', () {
      final d1 = DistanceService.distanceInMeters(59.91, 10.75, 60.39, 5.32);
      final d2 = DistanceService.distanceInMeters(60.39, 5.32, 59.91, 10.75);
      expect(d1, closeTo(d2, 0.01));
    });

    test('antipodal points give approximately half earth circumference', () {
      // North pole to south pole
      final d = DistanceService.distanceInMeters(90, 0, -90, 0);
      // Should be ~20,015 km (half circumference)
      expect(d, greaterThan(20000000));
      expect(d, lessThan(20100000));
    });
  });

  group('DistanceService.formatDistance', () {
    test('under 1000m shows meters', () {
      expect(DistanceService.formatDistance(0), '0 m');
      expect(DistanceService.formatDistance(500), '500 m');
      expect(DistanceService.formatDistance(999), '999 m');
    });

    test('1000m and above shows km with one decimal', () {
      expect(DistanceService.formatDistance(1000), '1.0 km');
      expect(DistanceService.formatDistance(1500), '1.5 km');
      expect(DistanceService.formatDistance(10000), '10.0 km');
      expect(DistanceService.formatDistance(305000), '305.0 km');
    });

    test('rounds meters correctly', () {
      expect(DistanceService.formatDistance(499.4), '499 m');
      expect(DistanceService.formatDistance(499.6), '500 m');
    });
  });
}
