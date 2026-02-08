import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'models/station.dart';
import 'providers/user_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/station_detail/station_detail_screen.dart';
import 'screens/submit_price/submit_price_screen.dart';
import 'widgets/app_bottom_nav.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<UserProvider>().isDarkMode;

    return MaterialApp(
      title: 'TankVenn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const AppBottomNav(),
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
          default:
            return null;
        }
      },
    );
  }
}
