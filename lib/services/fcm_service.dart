import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();

      // Request permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _registerTokenWithBackend(token);
        }

        // Listen for token refreshes
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _registerTokenWithBackend(newToken);
        });

        _setupForegroundMessaging();
      }
    } catch (e) {
      // Ignore if google-services.json is missing during dev
    }
  }

  static Future<void> _registerTokenWithBackend(String token) async {
    try {
      // In a real app, use the shared dio instance with auth token
      // final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:5000/api/v1')); 
      // await dio.patch('/auth/fcm-token', data: {'fcmToken': token});
    } catch (e) {
      // ignore
    }
  }

  static void _setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'progcap_urgent_alerts',
              'Urgent NBA Alerts',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }
}
