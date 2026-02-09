import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/constants.dart';
import 'firebase_options.dart';
import 'providers/location_provider.dart';
import 'providers/price_provider.dart';
import 'providers/station_provider.dart';
import 'providers/user_provider.dart';
import 'services/firestore_service.dart';
import 'services/location_service.dart';
import 'services/overpass_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  final userProvider = UserProvider();
  await userProvider.initialize();

  // Launch station init in the background — don't block the UI
  _initializeStations();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const App(),
    ),
  );
}

/// Tries to populate Firestore with real stations from OSM Overpass API.
/// Falls back to mock data if Overpass or location services are unavailable.
/// Runs in the background so the UI is not blocked.
Future<void> _initializeStations() async {
  try {
    // Try with user's actual location
    final position = await LocationService().getCurrentPosition();
    if (position != null) {
      final stations = await OverpassService.fetchNearbyStations(
        lat: position.latitude,
        lng: position.longitude,
        radiusMeters: AppConstants.defaultSearchRadiusMeters,
      );
      if (stations.isNotEmpty) {
        await FirestoreService.upsertStations(stations);
        return;
      }
    }

    // Fallback: try with default Oslo coordinates
    final stations = await OverpassService.fetchNearbyStations(
      lat: AppConstants.defaultMapCenter.latitude,
      lng: AppConstants.defaultMapCenter.longitude,
      radiusMeters: AppConstants.defaultSearchRadiusMeters,
    );
    if (stations.isNotEmpty) {
      await FirestoreService.upsertStations(stations);
      return;
    }

    // Ultimate fallback: seed from hardcoded mock data
    await FirestoreService.seedIfEmpty();
  } catch (e) {
    debugPrint('Station init failed: $e');
  }
}
