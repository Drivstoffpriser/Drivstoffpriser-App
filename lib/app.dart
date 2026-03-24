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
import 'screens/submit_price/submit_price_screen.dart';
import 'widgets/connectivity_gate.dart';
import 'widgets/floating_pill_nav.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return MaterialApp(
      title: 'TankVenn',
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
              builder: (_) => SubmitPriceScreen(station: station),
            );
          case AppRoutes.auth:
            return MaterialPageRoute(
              builder: (_) => const AuthScreen(popOnSuccess: true),
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
              builder: (_) => AddStationScreen(initialLocation: args as LatLng?),
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
