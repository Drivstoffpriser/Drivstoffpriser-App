import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/price_history_point.dart';
import '../models/price_report.dart';
import '../models/station.dart';

class MockDataService {
  static const _uuid = Uuid();

  static List<Station> getStations() {
    return const [
      // Oslo (coordinates from OpenStreetMap)
      Station(id: 's1', name: 'Circle K Kiellands plass', brand: 'Circle K', address: 'Kiellands plass', city: 'Oslo', latitude: 59.9288, longitude: 10.7500),
      Station(id: 's2', name: 'Shell Fjøsanger', brand: 'Shell', address: 'Cecilie Thoresens vei 13', city: 'Oslo', latitude: 59.8753, longitude: 10.8105),
      Station(id: 's3', name: 'Esso Trondheimsveien', brand: 'Esso', address: 'Trondheimsveien', city: 'Oslo', latitude: 59.9222, longitude: 10.7715),
      Station(id: 's4', name: 'YX Tåsen', brand: 'YX', address: 'Tåsen', city: 'Oslo', latitude: 59.9498, longitude: 10.7507),
      Station(id: 's5', name: 'Uno-X Fredensborg', brand: 'Uno-X', address: 'Fredensborgveien', city: 'Oslo', latitude: 59.9209, longitude: 10.7510),
      // Bergen (coordinates from OpenStreetMap)
      Station(id: 's6', name: 'Circle K Ulset', brand: 'Circle K', address: 'Ulset', city: 'Bergen', latitude: 60.4635, longitude: 5.3189),
      Station(id: 's7', name: 'Shell Fjøsanger', brand: 'Shell', address: 'Fjøsangerveien', city: 'Bergen', latitude: 60.3418, longitude: 5.3302),
      Station(id: 's8', name: 'Esso Nesttun', brand: 'Esso', address: 'Nesttun', city: 'Bergen', latitude: 60.3127, longitude: 5.3555),
      // Trondheim (coordinates from OpenStreetMap)
      Station(id: 's9', name: 'Circle K Tunga', brand: 'Circle K', address: 'Tungaveien', city: 'Trondheim', latitude: 63.4208, longitude: 10.4610),
      Station(id: 's10', name: 'Esso Kolstad', brand: 'Esso', address: 'Kolstadveien', city: 'Trondheim', latitude: 63.3665, longitude: 10.3464),
      Station(id: 's11', name: 'YX Lade', brand: 'YX', address: 'Lade', city: 'Trondheim', latitude: 63.4431, longitude: 10.4444),
      // Stavanger (coordinates from OpenStreetMap)
      Station(id: 's12', name: 'Circle K Forus', brand: 'Circle K', address: 'Forus', city: 'Stavanger', latitude: 58.8927, longitude: 5.7236),
      Station(id: 's13', name: 'Uno-X Forussletta', brand: 'Uno-X', address: 'Forussletta', city: 'Stavanger', latitude: 58.8776, longitude: 5.7258),
      Station(id: 's14', name: 'Circle K Mariero', brand: 'Circle K', address: 'Marieroveien', city: 'Stavanger', latitude: 58.9340, longitude: 5.7424),
      Station(id: 's15', name: 'Esso Sandnes', brand: 'Esso', address: 'Sandnes sentrum', city: 'Sandnes', latitude: 58.8493, longitude: 5.7368),
    ];
  }

  static List<CurrentPrice> getCurrentPrices() {
    final now = DateTime.now();
    return [
      // Oslo stations
      CurrentPrice(stationId: 's1', fuelType: FuelType.diesel, price: 20.49, updatedAt: now.subtract(const Duration(minutes: 15)), reportCount: 5),
      CurrentPrice(stationId: 's1', fuelType: FuelType.petrol95, price: 21.89, updatedAt: now.subtract(const Duration(minutes: 15)), reportCount: 4),
      CurrentPrice(stationId: 's1', fuelType: FuelType.petrol98, price: 23.19, updatedAt: now.subtract(const Duration(minutes: 30)), reportCount: 3),
      CurrentPrice(stationId: 's1', fuelType: FuelType.electric, price: 5.90, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),

      CurrentPrice(stationId: 's2', fuelType: FuelType.diesel, price: 21.09, updatedAt: now.subtract(const Duration(minutes: 45)), reportCount: 3),
      CurrentPrice(stationId: 's2', fuelType: FuelType.petrol95, price: 22.39, updatedAt: now.subtract(const Duration(minutes: 45)), reportCount: 3),
      CurrentPrice(stationId: 's2', fuelType: FuelType.petrol98, price: 23.69, updatedAt: now.subtract(const Duration(hours: 2)), reportCount: 2),

      CurrentPrice(stationId: 's3', fuelType: FuelType.diesel, price: 20.19, updatedAt: now.subtract(const Duration(minutes: 10)), reportCount: 6),
      CurrentPrice(stationId: 's3', fuelType: FuelType.petrol95, price: 21.49, updatedAt: now.subtract(const Duration(minutes: 10)), reportCount: 5),
      CurrentPrice(stationId: 's3', fuelType: FuelType.petrol98, price: 22.79, updatedAt: now.subtract(const Duration(minutes: 20)), reportCount: 4),
      CurrentPrice(stationId: 's3', fuelType: FuelType.electric, price: 6.20, updatedAt: now.subtract(const Duration(hours: 3)), reportCount: 1),

      CurrentPrice(stationId: 's4', fuelType: FuelType.diesel, price: 20.79, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),
      CurrentPrice(stationId: 's4', fuelType: FuelType.petrol95, price: 22.09, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),
      CurrentPrice(stationId: 's4', fuelType: FuelType.petrol98, price: 23.39, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 1),

      CurrentPrice(stationId: 's5', fuelType: FuelType.diesel, price: 19.99, updatedAt: now.subtract(const Duration(minutes: 5)), reportCount: 8),
      CurrentPrice(stationId: 's5', fuelType: FuelType.petrol95, price: 21.29, updatedAt: now.subtract(const Duration(minutes: 5)), reportCount: 7),
      CurrentPrice(stationId: 's5', fuelType: FuelType.petrol98, price: 22.59, updatedAt: now.subtract(const Duration(minutes: 5)), reportCount: 5),
      CurrentPrice(stationId: 's5', fuelType: FuelType.electric, price: 5.50, updatedAt: now.subtract(const Duration(minutes: 30)), reportCount: 3),

      // Bergen
      CurrentPrice(stationId: 's6', fuelType: FuelType.diesel, price: 21.29, updatedAt: now.subtract(const Duration(minutes: 20)), reportCount: 4),
      CurrentPrice(stationId: 's6', fuelType: FuelType.petrol95, price: 22.59, updatedAt: now.subtract(const Duration(minutes: 20)), reportCount: 3),
      CurrentPrice(stationId: 's6', fuelType: FuelType.petrol98, price: 23.89, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),

      CurrentPrice(stationId: 's7', fuelType: FuelType.diesel, price: 20.89, updatedAt: now.subtract(const Duration(hours: 2)), reportCount: 2),
      CurrentPrice(stationId: 's7', fuelType: FuelType.petrol95, price: 22.19, updatedAt: now.subtract(const Duration(hours: 2)), reportCount: 2),
      CurrentPrice(stationId: 's7', fuelType: FuelType.petrol98, price: 23.49, updatedAt: now.subtract(const Duration(hours: 2)), reportCount: 1),
      CurrentPrice(stationId: 's7', fuelType: FuelType.electric, price: 6.40, updatedAt: now.subtract(const Duration(hours: 4)), reportCount: 1),

      CurrentPrice(stationId: 's8', fuelType: FuelType.diesel, price: 20.59, updatedAt: now.subtract(const Duration(hours: 3)), reportCount: 1),
      CurrentPrice(stationId: 's8', fuelType: FuelType.petrol95, price: 21.89, updatedAt: now.subtract(const Duration(hours: 3)), reportCount: 1),

      // Trondheim
      CurrentPrice(stationId: 's9', fuelType: FuelType.diesel, price: 20.99, updatedAt: now.subtract(const Duration(minutes: 35)), reportCount: 3),
      CurrentPrice(stationId: 's9', fuelType: FuelType.petrol95, price: 22.29, updatedAt: now.subtract(const Duration(minutes: 35)), reportCount: 3),
      CurrentPrice(stationId: 's9', fuelType: FuelType.petrol98, price: 23.59, updatedAt: now.subtract(const Duration(minutes: 35)), reportCount: 2),
      CurrentPrice(stationId: 's9', fuelType: FuelType.electric, price: 5.80, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),

      CurrentPrice(stationId: 's10', fuelType: FuelType.diesel, price: 20.39, updatedAt: now.subtract(const Duration(hours: 5)), reportCount: 1),
      CurrentPrice(stationId: 's10', fuelType: FuelType.petrol95, price: 21.69, updatedAt: now.subtract(const Duration(hours: 5)), reportCount: 1),

      CurrentPrice(stationId: 's11', fuelType: FuelType.diesel, price: 21.19, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),
      CurrentPrice(stationId: 's11', fuelType: FuelType.petrol95, price: 22.49, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 2),
      CurrentPrice(stationId: 's11', fuelType: FuelType.petrol98, price: 23.79, updatedAt: now.subtract(const Duration(hours: 1)), reportCount: 1),

      // Stavanger
      CurrentPrice(stationId: 's12', fuelType: FuelType.diesel, price: 20.69, updatedAt: now.subtract(const Duration(minutes: 50)), reportCount: 3),
      CurrentPrice(stationId: 's12', fuelType: FuelType.petrol95, price: 21.99, updatedAt: now.subtract(const Duration(minutes: 50)), reportCount: 2),
      CurrentPrice(stationId: 's12', fuelType: FuelType.petrol98, price: 23.29, updatedAt: now.subtract(const Duration(minutes: 50)), reportCount: 2),
      CurrentPrice(stationId: 's12', fuelType: FuelType.electric, price: 7.10, updatedAt: now.subtract(const Duration(hours: 6)), reportCount: 1),

      CurrentPrice(stationId: 's13', fuelType: FuelType.diesel, price: 20.29, updatedAt: now.subtract(const Duration(minutes: 15)), reportCount: 4),
      CurrentPrice(stationId: 's13', fuelType: FuelType.petrol95, price: 21.59, updatedAt: now.subtract(const Duration(minutes: 15)), reportCount: 4),
      CurrentPrice(stationId: 's13', fuelType: FuelType.petrol98, price: 22.89, updatedAt: now.subtract(const Duration(minutes: 15)), reportCount: 3),

      CurrentPrice(stationId: 's14', fuelType: FuelType.diesel, price: 21.39, updatedAt: now.subtract(const Duration(hours: 2)), reportCount: 2),
      CurrentPrice(stationId: 's14', fuelType: FuelType.petrol95, price: 22.69, updatedAt: now.subtract(const Duration(hours: 2)), reportCount: 2),

      CurrentPrice(stationId: 's15', fuelType: FuelType.diesel, price: 20.09, updatedAt: now.subtract(const Duration(hours: 4)), reportCount: 1),
      CurrentPrice(stationId: 's15', fuelType: FuelType.petrol95, price: 21.39, updatedAt: now.subtract(const Duration(hours: 4)), reportCount: 1),
      CurrentPrice(stationId: 's15', fuelType: FuelType.petrol98, price: 22.69, updatedAt: now.subtract(const Duration(hours: 4)), reportCount: 1),
    ];
  }

  static List<PriceReport> getReportsForStation(String stationId) {
    final now = DateTime.now();
    final reports = <PriceReport>[];

    final prices = getCurrentPrices().where((p) => p.stationId == stationId);
    for (final price in prices) {
      reports.add(PriceReport(
        id: _uuid.v4(),
        stationId: stationId,
        fuelType: price.fuelType,
        price: price.price,
        userId: 'user-mock-1',
        reportedAt: price.updatedAt,
      ));
      // Add a second older report for variety
      reports.add(PriceReport(
        id: _uuid.v4(),
        stationId: stationId,
        fuelType: price.fuelType,
        price: price.price + 0.30,
        userId: 'user-mock-2',
        reportedAt: now.subtract(const Duration(days: 1)),
      ));
    }

    reports.sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return reports;
  }

  /// Generate deterministic 30-day price history for a station.
  static Map<FuelType, List<PriceHistoryPoint>> getPriceHistory(
    String stationId, {
    int days = 30,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final prices = getCurrentPrices().where((p) => p.stationId == stationId);
    final seed = stationId.hashCode;

    final history = <FuelType, List<PriceHistoryPoint>>{};

    for (final current in prices) {
      final points = <PriceHistoryPoint>[];
      final rng = Random(seed + current.fuelType.index);

      // Walk backward from today's price
      double price = current.price;
      for (int d = 0; d < days; d++) {
        final date = today.subtract(Duration(days: d));
        points.add(PriceHistoryPoint(date: date, price: price));

        // Vary the price for the previous day: sine wave + small random noise
        final wave = sin((d + seed) * 0.3) * 0.25;
        final noise = (rng.nextDouble() - 0.5) * 0.30;
        price = price - wave - noise;

        // Clamp to realistic bounds
        if (current.fuelType == FuelType.electric) {
          price = price.clamp(4.0, 9.0);
        } else {
          price = price.clamp(18.0, 26.0);
        }
      }

      // Reverse so oldest date comes first
      history[current.fuelType] = points.reversed.toList();
    }

    return history;
  }
}
