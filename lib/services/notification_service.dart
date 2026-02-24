import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'price_alerts',
    'Price Alerts',
    description: 'Notifications when fuel prices drop to your target',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(settings);

    // Create the Android notification channel and request permission
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        _channel.id,
        _channel.name,
        description: _channel.description,
        importance: _channel.importance,
      ),
    );
    // Android 13+ requires runtime notification permission
    await androidPlugin?.requestNotificationsPermission();
  }

  static Future<void> showPriceAlert({
    required int id,
    required String stationName,
    required double price,
    required double targetPrice,
    required String fuelType,
  }) async {
    await _plugin.show(
      id,
      'Price Alert: $fuelType',
      '$stationName has $fuelType at ${price.toStringAsFixed(2)} kr '
          '(your target: ${targetPrice.toStringAsFixed(2)} kr)',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
