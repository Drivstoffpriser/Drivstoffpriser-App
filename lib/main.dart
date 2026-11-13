/*
* A crowdsourced platform for real-time fuel price monitoring in Norway
* Copyright (C) 2026  Tsotne Karchava & Contributors
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import 'dart:io' show Platform;

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/location_provider.dart';
import 'providers/price_provider.dart';
import 'providers/station_provider.dart';
import 'providers/statistics_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  timeago.setLocaleMessages('nb', timeago.NbNoMessages());
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized (e.g. after hot restart)
  }

  // App Check is only enforced for Android in the Firebase Console.
  // Activating on iOS causes UNAVAILABLE errors because DeviceCheck
  // tokens fail and the client SDK blocks requests.
  if (!kIsWeb && Platform.isAndroid) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  }
  await GoogleSignIn.instance.initialize();

  // Don't block the UI on auth — UserProvider has sensible defaults
  // (Anonymous user) so the app can render immediately.
  final userProvider = UserProvider();
  final authReady = userProvider.initialize();

  final stationProvider = StationProvider();
  // Start station initialization (loads cache, checks last-updated).
  // The authenticated fetch is deferred until auth is ready.
  stationProvider.initialize();

  authReady.then((_) {
    stationProvider.onAuthReady();
    stationProvider.loadFavorites();
    // Preload the sorted station list so it's ready when the user
    // navigates to the list screen.
    stationProvider.loadSortedStations();
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: stationProvider),
        ChangeNotifierProvider(create: (_) => PriceProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => StatisticsProvider()),
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: const App(),
    ),
  );
}
