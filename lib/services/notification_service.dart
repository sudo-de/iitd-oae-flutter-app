import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  String? _fcmToken;

  // Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      _isInitialized = true;

      if (kDebugMode) {
        debugPrint('Notification service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize notification service: $e');
      }
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      if (kDebugMode) {
        debugPrint('User granted permission: ${settings.authorizationStatus}');
      }

      // Get FCM token with retry logic
      await _getFCMTokenWithRetry();

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        if (kDebugMode) {
          debugPrint('FCM Token refreshed: $token');
        }
        // Here you would typically send the new token to your server
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to initialize Firebase messaging: $e');
      }
      // Continue with local notifications even if FCM fails
    }
  }

  // Get FCM token with retry logic
  Future<void> _getFCMTokenWithRetry({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check network connectivity first
        if (!await _checkNetworkConnectivity()) {
          if (kDebugMode) {
            debugPrint(
              'No network connectivity, skipping FCM token attempt $attempt',
            );
          }
          if (attempt < maxRetries) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          }
          break;
        }

        _fcmToken = await _firebaseMessaging.getToken();
        if (_fcmToken != null && _fcmToken!.isNotEmpty) {
          if (kDebugMode) {
            debugPrint(
              'FCM Token obtained successfully on attempt $attempt: ${_fcmToken!.substring(0, 20)}...',
            );
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('FCM Token attempt $attempt failed: $e');
        }

        if (attempt < maxRetries) {
          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    if (kDebugMode) {
      debugPrint('Failed to get FCM token after $maxRetries attempts');
    }
  }

  // Check network connectivity
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Get FCM token
  String? get fcmToken => _fcmToken;

  // Retry FCM token generation
  Future<void> retryFCMToken() async {
    if (kDebugMode) {
      debugPrint('Retrying FCM token generation...');
    }
    await _getFCMTokenWithRetry(maxRetries: 5);
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) {
        debugPrint('Notification service not initialized');
      }
      return;
    }

    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'iitd_oae_channel',
            'IIT Delhi OAE Notifications',
            channelDescription: 'Notifications for IIT Delhi OAE app',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            sound: RawResourceAndroidNotificationSound('notification_sound'),
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      if (kDebugMode) {
        debugPrint('Local notification shown: $title - $body');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to show local notification: $e');
      }
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
      debugPrint('Message notification: ${message.notification?.title}');
    }

    // Show local notification for foreground messages
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'IIT Delhi OAE',
        body: message.notification!.body ?? 'New notification',
        payload: message.data.toString(),
      );
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification tapped: ${message.data}');
    }

    // Handle navigation based on message data
    // You can add navigation logic here based on the message type
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('Local notification tapped: ${response.payload}');
    }

    // Handle navigation based on notification payload
    // You can add navigation logic here
  }

  // Subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      // Check if FCM is available
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Cannot subscribe to topic $topic: FCM token not available',
          );
        }
        return;
      }

      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe to topic $topic: $e');
      }
      // Don't throw the error, just log it
    }
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // Check if FCM is available
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            'Cannot unsubscribe from topic $topic: FCM token not available',
          );
        }
        return;
      }

      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to unsubscribe from topic $topic: $e');
      }
      // Don't throw the error, just log it
    }
  }

  // Subscribe driver to driver-specific topics
  Future<void> subscribeDriverToTopics(String driverId) async {
    await subscribeToTopic('drivers');
    await subscribeToTopic('driver_$driverId');
  }

  // Subscribe student to student-specific topics
  Future<void> subscribeStudentToTopics(String studentId) async {
    await subscribeToTopic('students');
    await subscribeToTopic('student_$studentId');
  }

  // Subscribe admin to admin topics
  Future<void> subscribeAdminToTopics() async {
    await subscribeToTopic('admins');
    await subscribeToTopic('system_notifications');
  }

  // Clear all notifications
  Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  // await Firebase.initializeApp();

  if (kDebugMode) {
    debugPrint('Handling a background message: ${message.messageId}');
  }

  // Handle background message
  // You can add background processing logic here
}
