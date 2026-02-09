import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bug_report.dart';
import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/price_history_point.dart';
import '../models/price_report.dart';
import '../models/station.dart';
import '../models/user_profile.dart';
import 'mock_data_service.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Seeding ──────────────────────────────────────────────────────────

  /// Populates Firestore with mock data if the stations collection is empty.
  static Future<void> seedIfEmpty() async {
    final snapshot = await _db.collection('stations').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _db.batch();

    // Seed stations
    final stations = MockDataService.getStations();
    for (final station in stations) {
      final ref = _db.collection('stations').doc(station.id);
      batch.set(ref, station.toJson());
    }

    // Seed current prices
    final prices = MockDataService.getCurrentPrices();
    for (final price in prices) {
      final docId = '${price.stationId}_${price.fuelType.name}';
      final ref = _db.collection('currentPrices').doc(docId);
      batch.set(ref, price.toJson());
    }

    // Seed some initial reports
    for (final station in stations) {
      final reports = MockDataService.getReportsForStation(station.id);
      for (final report in reports) {
        final ref = _db
            .collection('stations')
            .doc(station.id)
            .collection('reports')
            .doc(report.id);
        batch.set(ref, report.toJson());
      }
    }

    await batch.commit();
  }

  /// Returns true if the stations collection has at least one document.
  static Future<bool> hasStations() async {
    final snapshot = await _db.collection('stations').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Upsert stations into Firestore. Existing stations are updated, not deleted.
  /// This preserves any linked reports and currentPrices documents.
  static Future<void> upsertStations(List<Station> stations) async {
    if (stations.isEmpty) return;

    final batch = _db.batch();
    for (final station in stations) {
      final ref = _db.collection('stations').doc(station.id);
      batch.set(ref, station.toJson(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ── Stations ─────────────────────────────────────────────────────────

  /// Real-time stream of all stations.
  static Stream<List<Station>> stationsStream() {
    return _db.collection('stations').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Station.fromJson(_normalizeTimestamps(doc.data()));
      }).toList();
    });
  }

  // ── Current Prices ───────────────────────────────────────────────────

  /// Real-time stream of all current prices.
  static Stream<List<CurrentPrice>> currentPricesStream() {
    return _db.collection('currentPrices').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CurrentPrice.fromJson(_normalizeTimestamps(doc.data()));
      }).toList();
    });
  }

  // ── Reports ──────────────────────────────────────────────────────────

  /// Fetch all price reports for a station, ordered by most recent first.
  static Future<List<PriceReport>> getReports(String stationId) async {
    final snapshot = await _db
        .collection('stations')
        .doc(stationId)
        .collection('reports')
        .orderBy('reportedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return PriceReport.fromJson(_normalizeTimestamps(doc.data()));
    }).toList();
  }

  /// Submit a new price report and update the denormalized current price.
  static Future<void> submitReport({
    required String stationId,
    required FuelType fuelType,
    required double price,
    required String userId,
  }) async {
    final now = DateTime.now();

    // Create report document (auto-generated ID)
    final reportRef = _db
        .collection('stations')
        .doc(stationId)
        .collection('reports')
        .doc();

    final report = PriceReport(
      id: reportRef.id,
      stationId: stationId,
      fuelType: fuelType,
      price: price,
      userId: userId,
      reportedAt: now,
    );

    // Update denormalized current price
    final priceDocId = '${stationId}_${fuelType.name}';
    final priceRef = _db.collection('currentPrices').doc(priceDocId);

    final batch = _db.batch();
    batch.set(reportRef, report.toJson());

    // Get current report count to increment
    final existingPrice = await priceRef.get();
    final currentCount = existingPrice.exists
        ? (existingPrice.data()?['reportCount'] as num?)?.toInt() ?? 0
        : 0;

    batch.set(
      priceRef,
      CurrentPrice(
        stationId: stationId,
        fuelType: fuelType,
        price: price,
        updatedAt: now,
        reportCount: currentCount + 1,
      ).toJson(),
    );

    await batch.commit();
  }

  /// Returns the most recent report time for a user+station+fuelType combo,
  /// or null if no report exists.
  static Future<DateTime?> getLastReportTime({
    required String userId,
    required String stationId,
    required FuelType fuelType,
  }) async {
    // Uses only equality filters to avoid requiring a Firestore
    // composite index. Finds the most recent report client-side.
    final snapshot = await _db
        .collection('stations')
        .doc(stationId)
        .collection('reports')
        .where('userId', isEqualTo: userId)
        .where('fuelType', isEqualTo: fuelType.name)
        .get();

    if (snapshot.docs.isEmpty) return null;

    DateTime? latest;
    for (final doc in snapshot.docs) {
      final data = _normalizeTimestamps(doc.data());
      final dt = DateTime.parse(data['reportedAt'] as String);
      if (latest == null || dt.isAfter(latest)) {
        latest = dt;
      }
    }
    return latest;
  }

  // ── Price History ────────────────────────────────────────────────────

  /// Compute 30-day price history from report documents.
  static Future<Map<FuelType, List<PriceHistoryPoint>>> getPriceHistory(
    String stationId, {
    int days = 30,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _db
        .collection('stations')
        .doc(stationId)
        .collection('reports')
        .where('reportedAt', isGreaterThan: cutoff.toIso8601String())
        .orderBy('reportedAt')
        .get();

    final reports = snapshot.docs.map((doc) {
      return PriceReport.fromJson(_normalizeTimestamps(doc.data()));
    }).toList();

    // Group by fuel type, then by day, taking the latest report per day
    final history = <FuelType, List<PriceHistoryPoint>>{};

    for (final fuelType in FuelType.values) {
      final fuelReports = reports.where((r) => r.fuelType == fuelType).toList();
      if (fuelReports.isEmpty) continue;

      // Group by date (ignoring time)
      final dayMap = <DateTime, PriceReport>{};
      for (final report in fuelReports) {
        final day = DateTime(
          report.reportedAt.year,
          report.reportedAt.month,
          report.reportedAt.day,
        );
        // Keep the latest report for each day
        if (!dayMap.containsKey(day) ||
            report.reportedAt.isAfter(dayMap[day]!.reportedAt)) {
          dayMap[day] = report;
        }
      }

      final points = dayMap.entries.map((e) {
        return PriceHistoryPoint(date: e.key, price: e.value.price);
      }).toList()..sort((a, b) => a.date.compareTo(b.date));

      history[fuelType] = points;
    }

    // If we got very few data points from reports, fall back to generated history
    // so the chart isn't empty (especially right after seeding)
    if (history.isEmpty || history.values.every((pts) => pts.length < 3)) {
      return _generateFallbackHistory(stationId, days: days);
    }

    return history;
  }

  /// Generate deterministic history as fallback when report data is sparse.
  static Map<FuelType, List<PriceHistoryPoint>> _generateFallbackHistory(
    String stationId, {
    int days = 30,
  }) {
    return MockDataService.getPriceHistory(stationId, days: days);
  }

  // ── User Profile ─────────────────────────────────────────────────────

  /// Get a user profile from Firestore.
  static Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(_normalizeTimestamps(doc.data()!));
  }

  /// Create or update a user profile in Firestore.
  static Future<void> setUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.id).set(profile.toJson());
  }

  /// Increment the report count for a user.
  static Future<void> incrementUserReportCount(String uid) async {
    await _db.collection('users').doc(uid).update({
      'reportCount': FieldValue.increment(1),
    });
  }

  // ── Bug Reports ──────────────────────────────────────────────────────

  /// Submit a bug report to the bug_reports collection.
  static Future<void> submitBugReport(BugReport report) async {
    await _db.collection('bug_reports').add(report.toMap());
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  /// Converts Firestore Timestamps to ISO strings so existing fromJson
  /// factories work unchanged.
  static Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }
}
