import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/current_price.dart';
import '../models/fuel_type.dart';
import '../models/price_alert.dart';
import '../models/station.dart';
import '../services/distance_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class AlertProvider extends ChangeNotifier {
  List<PriceAlert> _alerts = [];
  StreamSubscription? _alertsSub;
  String? _userId;

  /// Tracks alert+station combos already notified so we don't repeat.
  /// Shared with the background task via SharedPreferences.
  final Set<String> _notifiedKeys = {};

  static const _dedupPrefsKey = 'notifiedAlertKeys';

  List<PriceAlert> get alerts => _alerts;
  bool get hasActiveAlerts => _alerts.any((a) => a.isActive);

  /// Begin listening to alerts for the given user. Call again when
  /// the userId changes (e.g. sign-in / sign-out).
  void startListening(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _alertsSub?.cancel();
    _notifiedKeys.clear();

    if (userId == null || userId.isEmpty) {
      _alerts = [];
      notifyListeners();
      return;
    }

    // Load persisted dedup keys so we don't re-notify for alerts
    // already handled by a background task.
    SharedPreferences.getInstance().then((prefs) {
      final keys = prefs.getStringList(_dedupPrefsKey) ?? [];
      _notifiedKeys.addAll(keys);
    });

    _alertsSub = FirestoreService.priceAlertsStream(userId).listen((alerts) {
      _alerts = alerts;
      notifyListeners();
    });
  }

  /// Compare current prices against active alerts and fire notifications.
  /// Only prices updated AFTER the alert was created will trigger.
  void checkPrices(List<CurrentPrice> prices, List<Station> stations) {
    final stationMap = {for (final s in stations) s.id: s};

    for (final alert in _alerts) {
      if (!alert.isActive) continue;

      for (final price in prices) {
        if (price.fuelType != alert.fuelType) continue;
        if (price.price > alert.targetPrice) continue;

        // Only notify on prices reported AFTER the alert was created
        if (price.updatedAt.isBefore(alert.createdAt)) continue;

        // Station filter
        if (alert.stationId != null && alert.stationId != price.stationId) {
          continue;
        }

        // Distance filter (only when "any station")
        if (alert.stationId == null) {
          final station = stationMap[price.stationId];
          if (station == null) continue;
          final distMeters = DistanceService.distanceInMeters(
            alert.userLat,
            alert.userLng,
            station.latitude,
            station.longitude,
          );
          if (distMeters > alert.maxDistanceKm * 1000) continue;
        }

        // Dedup: don't notify the same alert+station combo twice
        final dedupKey = '${alert.id}_${price.stationId}';
        if (_notifiedKeys.contains(dedupKey)) continue;
        _notifiedKeys.add(dedupKey);
        _persistDedupKeys();

        final station = stationMap[price.stationId];
        final stationName = station?.name ?? price.stationId;

        NotificationService.showPriceAlert(
          id: dedupKey.hashCode,
          stationName: stationName,
          price: price.price,
          targetPrice: alert.targetPrice,
          fuelType: alert.fuelType.displayName,
        );
      }
    }
  }

  Future<void> createAlert({
    required String userId,
    required FuelType fuelType,
    required double targetPrice,
    String? stationId,
    double maxDistanceKm = 5,
    required double userLat,
    required double userLng,
  }) async {
    final alert = PriceAlert(
      id: const Uuid().v4(),
      userId: userId,
      fuelType: fuelType,
      targetPrice: targetPrice,
      stationId: stationId,
      maxDistanceKm: maxDistanceKm,
      userLat: userLat,
      userLng: userLng,
      createdAt: DateTime.now(),
    );
    await FirestoreService.createPriceAlert(alert);
  }

  Future<void> toggleAlert(PriceAlert alert) async {
    final updated = alert.copyWith(isActive: !alert.isActive);
    await FirestoreService.updatePriceAlert(updated);
    // If re-activated, clear its dedup keys so it can fire again
    if (updated.isActive) {
      _notifiedKeys.removeWhere((key) => key.startsWith('${alert.id}_'));
      _persistDedupKeys();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    await FirestoreService.deletePriceAlert(alertId);
    _notifiedKeys.removeWhere((key) => key.startsWith('${alertId}_'));
    _persistDedupKeys();
  }

  /// Fire-and-forget persistence of dedup keys for background task sync.
  void _persistDedupKeys() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList(_dedupPrefsKey, _notifiedKeys.toList());
    });
  }

  @override
  void dispose() {
    _alertsSub?.cancel();
    super.dispose();
  }
}
