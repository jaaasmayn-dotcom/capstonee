import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<bool> requestPermission() async {
    final settings =
        await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return settings.authorizationStatus ==
        AuthorizationStatus.authorized;
  }

  static Future<void> initialize() async {
    const AndroidInitializationSettings
        androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const InitializationSettings settings =
        InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings,
    );

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        showNotification(
          title:
              message.notification?.title ??
                  'SENSORIYA',
          body:
              message.notification?.body ??
                  '',
        );
      },
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails
        androidDetails =
        AndroidNotificationDetails(
      'aquarium_alerts',
      'Aquarium Alerts',
      channelDescription:
          'Aquarium monitoring alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }
}