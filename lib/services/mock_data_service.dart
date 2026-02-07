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
      // Oslo
      Station(id: 's1', name: 'Circle K Majorstuen', brand: 'Circle K', address: 'Kirkeveien 45', city: 'Oslo', latitude: 59.9290, longitude: 10.7127),
      Station(id: 's2', name: 'Shell Grønland', brand: 'Shell', address: 'Grønlandsleiret 12', city: 'Oslo', latitude: 59.9127, longitude: 10.7615),
      Station(id: 's3', name: 'Esso Sinsen', brand: 'Esso', address: 'Trondheimsveien 100', city: 'Oslo', latitude: 59.9380, longitude: 10.7780),
      Station(id: 's4', name: 'YX Bryn', brand: 'YX', address: 'Østensjøveien 52', city: 'Oslo', latitude: 59.9070, longitude: 10.8100),
      Station(id: 's5', name: 'Uno-X Løren', brand: 'Uno-X', address: 'Økernveien 20', city: 'Oslo', latitude: 59.9330, longitude: 10.7920),
      // Bergen
      Station(id: 's6', name: 'Circle K Åsane', brand: 'Circle K', address: 'Åsane Senter 1', city: 'Bergen', latitude: 60.4650, longitude: 5.3250),
      Station(id: 's7', name: 'Shell Nesttun', brand: 'Shell', address: 'Nesttunveien 88', city: 'Bergen', latitude: 60.3220, longitude: 5.3540),
      Station(id: 's8', name: 'Best Laksevåg', brand: 'Best', address: 'Damsgårdsveien 110', city: 'Bergen', latitude: 60.3800, longitude: 5.2950),
      // Trondheim
      Station(id: 's9', name: 'Circle K Lade', brand: 'Circle K', address: 'Haakon VIIs gate 30', city: 'Trondheim', latitude: 63.4380, longitude: 10.4350),
      Station(id: 's10', name: 'Esso Heimdal', brand: 'Esso', address: 'Heimdalsvegen 60', city: 'Trondheim', latitude: 63.3720, longitude: 10.3510),
      Station(id: 's11', name: 'YX Byåsen', brand: 'YX', address: 'Byåsveien 120', city: 'Trondheim', latitude: 63.4120, longitude: 10.3480),
      // Stavanger
      Station(id: 's12', name: 'Shell Forus', brand: 'Shell', address: 'Forusbeen 35', city: 'Stavanger', latitude: 58.8940, longitude: 5.7340),
      Station(id: 's13', name: 'Uno-X Hillevåg', brand: 'Uno-X', address: 'Hillevågsveien 70', city: 'Stavanger', latitude: 58.9550, longitude: 5.7180),
      Station(id: 's14', name: 'Circle K Madla', brand: 'Circle K', address: 'Madlaveien 30', city: 'Stavanger', latitude: 58.9410, longitude: 5.6870),
      Station(id: 's15', name: 'Best Sandnes', brand: 'Best', address: 'Langgata 100', city: 'Sandnes', latitude: 58.8520, longitude: 5.7350),
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
