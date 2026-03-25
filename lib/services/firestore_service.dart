import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bug_report.dart';
import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/price_history_point.dart';
import '../models/price_report.dart';
import '../models/station.dart';
import '../models/station_modify_request.dart';
import '../models/station_submission.dart';
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

    // Build aggregate docs
    batch.set(_db.collection('aggregates').doc('stations'), {
      'stations': stations.map((s) => s.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('aggregates').doc('prices'), {
      'prices': prices.map((p) => p.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Returns true if the stations collection has at least one document.
  static Future<bool> hasStations() async {
    final snapshot = await _db.collection('stations').limit(1).get();
    return snapshot.docs.isNotEmpty;
  }

  /// Rebuild the aggregate from the stations collection (N reads).
  static Future<void> rebuildStationsAggregate() => _rebuildStationsAggregate();

  /// Rebuild the stations aggregate doc.
  /// If [stations] is provided, uses them directly.
  /// Otherwise falls back to reading all station docs from Firestore.
  static Future<void> _rebuildStationsAggregate([
    List<Station>? stations,
  ]) async {
    final allStations = stations ?? await _readAllStations();

    await _db.collection('aggregates').doc('stations').set({
      'stations': allStations.map((s) => s.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Read all station docs from Firestore (N reads). Only used as fallback.
  static Future<List<Station>> _readAllStations() async {
    final snapshot = await _db.collection('stations').get();
    return snapshot.docs.map((doc) {
      return Station.fromJson(_normalizeTimestamps(doc.data()));
    }).toList();
  }

  /// Rebuild the prices aggregate from the currentPrices collection.
  static Future<void> rebuildPricesAggregate() => _rebuildPricesAggregate();

  /// Rebuild the prices aggregate doc.
  /// If [prices] is provided, uses them directly (0 reads).
  /// Otherwise falls back to reading all currentPrices docs from Firestore.
  static Future<void> _rebuildPricesAggregate([
    List<CurrentPrice>? prices,
  ]) async {
    final allPrices = prices ?? await _readAllPrices();

    await _db.collection('aggregates').doc('prices').set({
      'prices': allPrices.map((p) => p.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update or insert a single price in the prices aggregate (1 read + 1 write).
  static Future<void> _upsertPriceInAggregate(CurrentPrice price) async {
    final aggDoc = await _db.collection('aggregates').doc('prices').get();
    final list = aggDoc.exists
        ? ((aggDoc.data()!['prices'] as List<dynamic>?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
        : <Map<String, dynamic>>[];

    // Find existing entry by stationId + fuelType
    final idx = list.indexWhere(
      (p) =>
          p['stationId'] == price.stationId &&
          p['fuelType'] == price.fuelType.name,
    );

    if (idx != -1) {
      list[idx] = price.toJson();
    } else {
      list.add(price.toJson());
    }

    await _db.collection('aggregates').doc('prices').set({
      'prices': list,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Read all currentPrices docs from Firestore (N reads). Only used as fallback.
  static Future<List<CurrentPrice>> _readAllPrices() async {
    final snapshot = await _db.collection('currentPrices').get();
    return snapshot.docs.map((doc) {
      return CurrentPrice.fromJson(_normalizeTimestamps(doc.data()));
    }).toList();
  }

  // ── Stations (aggregate reads) ─────────────────────────────────────

  /// One-time read of all stations from the aggregate doc (1 read).
  static Future<List<Station>> getStations() async {
    final doc = await _db.collection('aggregates').doc('stations').get();
    if (!doc.exists) {
      // Fallback: read individual docs and build aggregate
      await _rebuildStationsAggregate();
      return getStations();
    }
    final data = doc.data()!;
    final list = (data['stations'] as List<dynamic>?) ?? [];
    return list.map((e) {
      return Station.fromJson(
        _normalizeTimestamps(Map<String, dynamic>.from(e as Map)),
      );
    }).toList();
  }

  // ── Current Prices (aggregate reads) ───────────────────────────────

  /// One-time read of all current prices from the aggregate doc (1 read).
  static Future<List<CurrentPrice>> getPrices() async {
    final doc = await _db.collection('aggregates').doc('prices').get();
    if (!doc.exists) {
      // Fallback: read individual docs and build aggregate
      await _rebuildPricesAggregate();
      return getPrices();
    }
    final data = doc.data()!;
    final list = (data['prices'] as List<dynamic>?) ?? [];
    return list.map((e) {
      return CurrentPrice.fromJson(
        _normalizeTimestamps(Map<String, dynamic>.from(e as Map)),
      );
    }).toList();
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

  /// Delete a price report (admin only).
  static Future<void> deleteReport(String stationId, String reportId) async {
    await _db
        .collection('stations')
        .doc(stationId)
        .collection('reports')
        .doc(reportId)
        .delete();
  }

  /// Submit a new price report and update the denormalized current price.
  /// Also rebuilds the prices aggregate doc.
  static Future<void> submitReport({
    required String stationId,
    required FuelType fuelType,
    required double price,
    required String userId,
    bool incrementUserReport = false,
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

    // Increment user report count only once per station submission
    if (incrementUserReport) {
      final userRef = _db.collection('users').doc(userId);
      batch.update(userRef, {'reportCount': FieldValue.increment(1)});
    }

    await batch.commit();

    // Update just the one price entry in the aggregate (1 read + 1 write)
    // instead of rebuilding the entire aggregate from currentPrices (N reads).
    final newPrice = CurrentPrice(
      stationId: stationId,
      fuelType: fuelType,
      price: price,
      updatedAt: now,
      reportCount: currentCount + 1,
    );
    await _upsertPriceInAggregate(newPrice);
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
    await _db
        .collection('users')
        .doc(profile.id)
        .set(profile.toJson(), SetOptions(merge: true));
  }

  // ── Account Deletion ─────────────────────────────────────────────────

  /// Delete all Firestore data associated with a user account.
  /// Community-contributed price data is left intact (anonymized/shared).
  static Future<void> deleteUserData(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ── Bug Reports ──────────────────────────────────────────────────────

  /// Submit a bug report to the bug_reports collection.
  static Future<void> submitBugReport(BugReport report) async {
    await _db.collection('bug_reports').add(report.toMap());
  }

  // ── New Station Submissions ─────────────────────────────────────────

  /// Submit a new station for admin approval.
  /// Writes to the `new_stations` collection (not the main `stations`).
  static Future<void> submitNewStation({
    required String name,
    required String brand,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required String submittedBy,
  }) async {
    await _db.collection('new_stations').add({
      'name': name,
      'brand': brand,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'submittedBy': submittedBy,
      'submittedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  /// Fetch all station submissions for a given user.
  static Future<List<StationSubmission>> getUserStationSubmissions(
    String uid,
  ) async {
    final snapshot = await _db
        .collection('new_stations')
        .where('submittedBy', isEqualTo: uid)
        .get();

    return snapshot.docs.map((doc) {
      return StationSubmission.fromJson(
        doc.id,
        _normalizeTimestamps(doc.data()),
      );
    }).toList();
  }

  /// Fetch submissions with unread feedback for a given user.
  static Future<List<StationSubmission>> getUnreadFeedback(String uid) async {
    final snapshot = await _db
        .collection('new_stations')
        .where('submittedBy', isEqualTo: uid)
        .get();

    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final feedback = data['feedback'] as String?;
          final feedbackRead = data['feedbackRead'] as bool? ?? false;
          return feedback != null && feedback.isNotEmpty && !feedbackRead;
        })
        .map(
          (doc) => StationSubmission.fromJson(
            doc.id,
            _normalizeTimestamps(doc.data()),
          ),
        )
        .toList();
  }

  /// Update an existing pending station submission.
  static Future<void> updateStationSubmission({
    required String docId,
    required String name,
    required String brand,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required String submittedBy,
  }) async {
    await _db.collection('new_stations').doc(docId).update({
      'name': name,
      'brand': brand,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'submittedBy': submittedBy,
      'status': 'pending',
    });
  }

  /// Delete a pending station submission.
  static Future<void> deleteStationSubmission(String docId) async {
    await _db.collection('new_stations').doc(docId).delete();
  }

  /// Mark feedback as read on a station submission.
  static Future<void> markFeedbackRead(String docId) async {
    await _db.collection('new_stations').doc(docId).update({
      'feedbackRead': true,
    });
  }

  // ── Admin Operations ────────────────────────────────────────────────

  /// Fetch all pending station submissions (admin only).
  static Future<List<StationSubmission>> getAllPendingSubmissions() async {
    final snapshot = await _db
        .collection('new_stations')
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs.map((doc) {
      return StationSubmission.fromJson(
        doc.id,
        _normalizeTimestamps(doc.data()),
      );
    }).toList();
  }

  /// Approve a station submission: copy to stations collection,
  /// update status to approved, rebuild stations aggregate.
  static Future<void> approveStation(
    StationSubmission submission, {
    String? feedback,
  }) async {
    final stationId = 'user_${submission.id}';
    final station = Station(
      id: stationId,
      name: submission.name,
      brand: submission.brand,
      address: submission.address,
      city: submission.city,
      latitude: submission.latitude,
      longitude: submission.longitude,
    );

    final batch = _db.batch();

    // Add to stations collection
    batch.set(_db.collection('stations').doc(stationId), station.toJson());

    // Update submission status + optional feedback
    final updateData = <String, dynamic>{'status': 'approved'};
    if (feedback != null && feedback.isNotEmpty) {
      updateData['feedback'] = feedback;
      updateData['feedbackRead'] = false;
    }
    batch.update(_db.collection('new_stations').doc(submission.id), updateData);

    await batch.commit();

    // Append the new station to the aggregate directly
    // (avoids race condition with batch write propagation)
    final aggDoc = await _db.collection('aggregates').doc('stations').get();
    final existing = aggDoc.exists
        ? ((aggDoc.data()!['stations'] as List<dynamic>?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
        : <Map<String, dynamic>>[];
    existing.add(station.toJson());
    await _db.collection('aggregates').doc('stations').set({
      'stations': existing,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a station from the stations collection and remove from aggregate.
  static Future<void> deleteStation(String stationId) async {
    await _db.collection('stations').doc(stationId).delete();

    // Remove from aggregate
    final aggDoc = await _db.collection('aggregates').doc('stations').get();
    if (aggDoc.exists) {
      final list = ((aggDoc.data()!['stations'] as List<dynamic>?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((s) => s['id'] != stationId)
          .toList();
      await _db.collection('aggregates').doc('stations').set({
        'stations': list,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Reject a station submission with optional feedback.
  static Future<void> rejectStation(String docId, {String? feedback}) async {
    final data = <String, dynamic>{'status': 'rejected'};
    if (feedback != null && feedback.isNotEmpty) {
      data['feedback'] = feedback;
      data['feedbackRead'] = false;
    }
    await _db.collection('new_stations').doc(docId).update(data);
  }

  // ── Station Modify Requests ─────────────────────────────────────────

  /// Submit a request to modify an existing station.
  static Future<void> submitModifyRequest(StationModifyRequest request) async {
    final data = request.toJson();
    data['submittedAt'] = FieldValue.serverTimestamp();
    data['status'] = 'pending';
    await _db.collection('station_modify_requests').add(data);
  }

  /// Fetch modify requests submitted by a given user.
  static Future<List<StationModifyRequest>> getUserModifyRequests(
    String uid,
  ) async {
    final snapshot = await _db
        .collection('station_modify_requests')
        .where('submittedBy', isEqualTo: uid)
        .get();
    return snapshot.docs.map((doc) {
      return StationModifyRequest.fromJson(
        doc.id,
        _normalizeTimestamps(doc.data()),
      );
    }).toList();
  }

  /// Fetch all pending modify requests (admin only).
  static Future<List<StationModifyRequest>>
  getAllPendingModifyRequests() async {
    final snapshot = await _db
        .collection('station_modify_requests')
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.map((doc) {
      return StationModifyRequest.fromJson(
        doc.id,
        _normalizeTimestamps(doc.data()),
      );
    }).toList();
  }

  /// Approve a modify request: update the station and rebuild aggregate.
  static Future<void> approveModifyRequest(
    StationModifyRequest request, {
    String? feedback,
  }) async {
    final stationRef = _db.collection('stations').doc(request.stationId);
    final requestRef = _db
        .collection('station_modify_requests')
        .doc(request.id);

    final batch = _db.batch();

    // Update the station with proposed values
    batch.update(stationRef, {
      'name': request.proposedName,
      'brand': request.proposedBrand,
      'address': request.proposedAddress,
      'city': request.proposedCity,
      'latitude': request.proposedLatitude,
      'longitude': request.proposedLongitude,
    });

    // Update request status
    final updateData = <String, dynamic>{'status': 'approved'};
    if (feedback != null && feedback.isNotEmpty) {
      updateData['feedback'] = feedback;
      updateData['feedbackRead'] = false;
    }
    batch.update(requestRef, updateData);

    await batch.commit();

    // Update the aggregate — replace the station in-place
    final aggDoc = await _db.collection('aggregates').doc('stations').get();
    if (aggDoc.exists) {
      final list = ((aggDoc.data()!['stations'] as List<dynamic>?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final idx = list.indexWhere((s) => s['id'] == request.stationId);
      if (idx != -1) {
        list[idx] = {
          'id': request.stationId,
          'name': request.proposedName,
          'brand': request.proposedBrand,
          'address': request.proposedAddress,
          'city': request.proposedCity,
          'latitude': request.proposedLatitude,
          'longitude': request.proposedLongitude,
        };
      }
      await _db.collection('aggregates').doc('stations').set({
        'stations': list,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Reject a modify request with optional feedback.
  static Future<void> rejectModifyRequest(
    String docId, {
    String? feedback,
  }) async {
    final data = <String, dynamic>{'status': 'rejected'};
    if (feedback != null && feedback.isNotEmpty) {
      data['feedback'] = feedback;
      data['feedbackRead'] = false;
    }
    await _db.collection('station_modify_requests').doc(docId).update(data);
  }

  /// Mark feedback as read on a modify request.
  static Future<void> markModifyFeedbackRead(String docId) async {
    await _db.collection('station_modify_requests').doc(docId).update({
      'feedbackRead': true,
    });
  }

  /// Fetch modify requests with unread feedback for a given user.
  static Future<List<StationModifyRequest>> getUnreadModifyFeedback(
    String uid,
  ) async {
    final snapshot = await _db
        .collection('station_modify_requests')
        .where('submittedBy', isEqualTo: uid)
        .get();
    return snapshot.docs
        .where((doc) {
          final data = doc.data();
          final feedback = data['feedback'] as String?;
          final feedbackRead = data['feedbackRead'] as bool? ?? false;
          return feedback != null && feedback.isNotEmpty && !feedbackRead;
        })
        .map(
          (doc) => StationModifyRequest.fromJson(
            doc.id,
            _normalizeTimestamps(doc.data()),
          ),
        )
        .toList();
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
