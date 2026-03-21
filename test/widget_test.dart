import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

import 'package:fuel_price_tracker/app.dart';
import 'package:fuel_price_tracker/providers/location_provider.dart';
import 'package:fuel_price_tracker/providers/price_provider.dart';
import 'package:fuel_price_tracker/providers/station_provider.dart';
import 'package:fuel_price_tracker/providers/user_provider.dart';

class MockFirebasePlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseAppPlatform();
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseAppPlatform();
  }

  @override
  List<FirebaseAppPlatform> get apps => [MockFirebaseAppPlatform()];
}

class MockFirebaseAppPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseAppPlatform {
  @override
  String get name => defaultFirebaseAppName;

  @override
  FirebaseOptions get options => const FirebaseOptions(
        apiKey: 'test',
        appId: 'test',
        messagingSenderId: 'test',
        projectId: 'test',
      );

  @override
  bool get isAutomaticDataCollectionEnabled => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    FirebasePlatform.instance = MockFirebasePlatform();
    await Firebase.initializeApp();
  });

  testWidgets('App launches with providers', (WidgetTester tester) async {
    // FlutterMap tries to load tiles which fail in test environment.
    // Overflow errors can occur due to small test viewport.
    // Firebase errors are expected in test environment.
    final origOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('HTTP') ||
          message.contains('Firebase') ||
          message.contains('MissingPluginException') ||
          message.contains('PlatformException')) {
        return;
      }
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

    // Pump a few frames to let the widget tree build.
    // pumpAndSettle can't be used because map tiles and connectivity
    // checks create animations/timers that never settle in test.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // App should render the bottom navigation (English l10n defaults)
    expect(find.text('Map'), findsWidgets);
    expect(find.text('Stations'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);

    FlutterError.onError = origOnError;
  });
}
