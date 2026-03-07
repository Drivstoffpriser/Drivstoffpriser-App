import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import '../services/distance_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

const backgroundTaskName = 'checkPriceAlerts';
const _dedupPrefsKey = 'notifiedAlertKeys';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );

      await NotificationService.initialize();

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null || userId.isEmpty) return true;

      final alerts = await FirestoreService.getActiveAlerts(userId);
      if (alerts.isEmpty) return true;

      final prices = await FirestoreService.getCurrentPrices();
      final stations = await FirestoreService.getStations();
      final stationMap = {for (final s in stations) s.id: s};

      final notifiedSet =
          (prefs.getStringList(_dedupPrefsKey) ?? []).toSet();
      var changed = false;

      for (final alert in alerts) {
        for (final price in prices) {
          if (price.fuelType != alert.fuelType) continue;
          if (price.price > alert.targetPrice) continue;
          if (price.updatedAt.isBefore(alert.createdAt)) continue;

          if (alert.stationId != null &&
              alert.stationId != price.stationId) {
            continue;
          }

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

          final dedupKey = '${alert.id}_${price.stationId}';
          if (notifiedSet.contains(dedupKey)) continue;

          notifiedSet.add(dedupKey);
          changed = true;

          final station = stationMap[price.stationId];
          final stationName = station?.name ?? price.stationId;

          await NotificationService.showPriceAlert(
            id: dedupKey.hashCode,
            stationName: stationName,
            price: price.price,
            targetPrice: alert.targetPrice,
            fuelType: alert.fuelType.displayName,
          );
        }
      }

      if (changed) {
        await prefs.setStringList(_dedupPrefsKey, notifiedSet.toList());
      }

      return true;
    } catch (_) {
      return false;
    }
  });
}
