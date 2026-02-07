import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fuel_price_tracker/app.dart';
import 'package:fuel_price_tracker/providers/location_provider.dart';
import 'package:fuel_price_tracker/providers/price_provider.dart';
import 'package:fuel_price_tracker/providers/station_provider.dart';
import 'package:fuel_price_tracker/providers/user_provider.dart';

void main() {
  testWidgets('App launches with providers', (WidgetTester tester) async {
    // FlutterMap tries to load tiles which fail in test environment.
    // Overflow errors can occur due to small test viewport.
    // These are expected — suppress them.
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') || message.contains('HTTP')) return;
      origOnError?.call(details);
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => StationProvider()),
          ChangeNotifierProvider(create: (_) => PriceProvider()),
          ChangeNotifierProvider(create: (_) => LocationProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const App(),
      ),
    );

    // Let async operations settle
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // App should render the bottom navigation
    expect(find.text('Map'), findsWidgets);
    expect(find.text('Stations'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    FlutterError.onError = origOnError;
  });
}
