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

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'models/station.dart';
import 'models/station_submission.dart';
import 'providers/user_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/add_station/add_station_screen.dart';
import 'screens/admin/admin_modify_requests_screen.dart';
import 'screens/admin/admin_submissions_screen.dart';
import 'screens/settings/bug_report_screen.dart';
import 'screens/settings/my_station_submissions_screen.dart';
import 'screens/station_detail/station_detail_screen.dart';
import 'screens/submit_price/price_capture_screen.dart';
import 'widgets/connectivity_gate.dart';
import 'widgets/floating_pill_nav.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return MaterialApp(
      title: 'Drivstoffpriser',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: userProvider.themeMode,
      locale: userProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => ConnectivityGate(child: child!),
      home: const FloatingPillNav(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.stationDetail:
            final station = settings.arguments as Station;
            return MaterialPageRoute(
              builder: (_) => StationDetailScreen(station: station),
            );
          case AppRoutes.submitPrice:
            final station = settings.arguments as Station;
            return MaterialPageRoute(
              builder: (_) => PriceCaptureScreen(station: station),
            );
          case AppRoutes.auth:
            final isRegister = settings.arguments is bool
                ? settings.arguments as bool
                : true;
            return MaterialPageRoute(
              builder: (_) =>
                  AuthScreen(popOnSuccess: true, initialIsRegister: isRegister),
            );
          case AppRoutes.bugReport:
            return MaterialPageRoute(builder: (_) => const BugReportScreen());
          case AppRoutes.addStation:
            final args = settings.arguments;
            if (args is StationSubmission) {
              return MaterialPageRoute(
                builder: (_) => AddStationScreen(editSubmission: args),
              );
            }
            return MaterialPageRoute(
              builder: (_) =>
                  AddStationScreen(initialLocation: args as LatLng?),
            );
          case AppRoutes.myStationSubmissions:
            return MaterialPageRoute(
              builder: (_) => const MyStationSubmissionsScreen(),
            );
          case AppRoutes.adminSubmissions:
            return MaterialPageRoute(
              builder: (_) => const AdminSubmissionsScreen(),
            );
          case AppRoutes.adminModifyRequests:
            return MaterialPageRoute(
              builder: (_) => const AdminModifyRequestsScreen(),
            );
          default:
            return null;
        }
      },
    );
  }
}
