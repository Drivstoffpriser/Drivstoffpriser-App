import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/location_provider.dart';
import 'providers/price_provider.dart';
import 'providers/station_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // Already initialized (e.g. after hot restart)
  }
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  // Don't block the UI on auth — UserProvider has sensible defaults
  // (Anonymous user) so the app can render immediately.
  final userProvider = UserProvider();
  userProvider.initialize();

  // Start station loading immediately so data is ready by the time
  // the map screen renders.  Serves cache first (0 reads), then
  // falls back to aggregate docs (2 reads), then refreshes from
  // Overpass in the background.
  final stationProvider = StationProvider();
  stationProvider.fetchAllNorwayStations();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: stationProvider),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const App(),
    ),
  );
}
