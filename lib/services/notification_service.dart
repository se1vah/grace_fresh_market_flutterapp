import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../firebase_options.dart';
import '../views/main_navigation_screen.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('Background notification tapped: ${notificationResponse.payload}');
  NotificationService.shouldNavigateToNotificationScreen = true;
}

class NotificationService {
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static bool shouldNavigateToNotificationScreen = false;

  /// Call to navigate directly to the Notification screen.
  static void navigateToNotificationScreen() {
    shouldNavigateToNotificationScreen = true;
    final activeState = MainNavigationScreen.activeState;
    if (activeState != null && activeState.mounted) {
      shouldNavigateToNotificationScreen = false;
      activeState.openNotificationTab();
      return;
    }

    final context = navigatorKey.currentContext;
    if (context != null) {
      shouldNavigateToNotificationScreen = false;
      MainNavigationScreen.navigateToTab(context, 2);
    }
  }

  /// Check and perform pending notification navigation.
  static void checkPendingNotificationNavigation(BuildContext context) {
    if (shouldNavigateToNotificationScreen) {
      shouldNavigateToNotificationScreen = false;
      MainNavigationScreen.navigateToTab(context, 2);
    }
  }

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'grocery_default_channel',
    'Grocery Notifications',
    description: 'Notifications from Grocery App',
    importance: Importance.high,
  );

  /// Initialize all notification functionality.
  static Future<void> initialize() async {
    await _requestPermission();

    await _initializeLocalNotifications();

    await _configureForegroundNotifications();

    await _configureNotificationTap();

    _generateFcmToken();

    _listenForTokenRefresh();
  }

  /// Request notification permission.
  static Future<void> _requestPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );
  }

  /// Initialize local notifications.
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(_channel);
  }

  /// Called when local notification is tapped.
  static void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');

    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _handleNotificationData(data);
        return;
      } catch (e) {
        debugPrint('Notification payload error: $e');
      }
    }

    navigateToNotificationScreen();
  }

  /// Handle notification when app is in foreground.
  static Future<void> _configureForegroundNotifications() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Foreground notification received');

      debugPrint('Message ID: ${message.messageId}');

      debugPrint('Data: ${message.data}');

      final RemoteNotification? notification = message.notification;

      if (notification == null) {
        return;
      }

      await _showLocalNotification(message);
    });
  }

  /// Display local notification when app is
  /// in foreground.
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;

    if (notification == null) {
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'grocery_default_channel',
          'Grocery Notifications',
          channelDescription: 'Notifications from Grocery App',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title ?? 'Grocery App',
      body: notification.body ?? '',
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  /// Configure notification tap handling.
  static Future<void> _configureNotificationTap() async {
    // App opened from terminated state via FCM.
    final RemoteMessage? initialMessage = await _messaging.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('Opened from terminated notification via FCM');
      _handleNotificationData(initialMessage.data);
    }

    // App opened from terminated state via local notification.
    final NotificationAppLaunchDetails? launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      debugPrint('Opened from terminated notification via local notifications');
      navigateToNotificationScreen();
    }

    // App opened from background via FCM.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Opened from background notification via FCM');
      _handleNotificationData(message.data);
    });
  }

  /// Handle notification data.
  static void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('Notification data: $data');

    final String? type = data['type']?.toString();
    final String? orderId = data['orderId']?.toString();
    final String? screen = data['screen']?.toString();

    debugPrint('Notification type: $type');
    debugPrint('Order ID: $orderId');
    debugPrint('Screen: $screen');

    navigateToNotificationScreen();
  }

  /// Get current FCM token safely. Returns null if token is unavailable or fails.
  static Future<String?> getFcmToken() async {
    try {
      final String? token = await _messaging.getToken().timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      return token;
    } catch (e) {
      debugPrint('Failed to fetch FCM token: $e');
      return null;
    }
  }

  /// Generate FCM token.
  static Future<void> _generateFcmToken() async {
    try {
      final String? token = await getFcmToken();

      if (token == null) {
        debugPrint('FCM token is null');
        return;
      }

      debugPrint('');
      debugPrint('======================================');
      debugPrint('FCM TOKEN:');
      debugPrint(token);
      debugPrint('======================================');
      debugPrint('');

      // Send token to your backend.
      await _sendTokenToBackend(token);
    } catch (e) {
      debugPrint('Failed to generate FCM token: $e');
    }
  }

  /// Listen for token changes.
  static void _listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((String newToken) async {
      debugPrint('FCM token refreshed:');

      debugPrint(newToken);

      await _sendTokenToBackend(newToken);
    });
  }

  /// Send token to your Next.js backend.
  static Future<void> _sendTokenToBackend(String token) async {
    /*
      IMPORTANT:

      Replace this with your actual API.

      Example:

      final response = await http.post(
        Uri.parse(
          'https://your-domain.com/api/user/device-token',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer YOUR_JWT_TOKEN',
        },
        body: jsonEncode({
          'fcmToken': token,
          'deviceType': 'android',
        }),
      );

      debugPrint(
        'Backend response: ${response.body}',
      );
    */

    debugPrint('FCM token ready for backend');

    debugPrint(token);
  }
}

/// Background FCM handler.
///
/// This MUST be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('Background FCM message:');

  debugPrint('Message ID: ${message.messageId}');

  debugPrint('Data: ${message.data}');
}
