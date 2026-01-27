import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../storage/token_storage.dart';
import 'in_app_notification_banner.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Note: Keep this lightweight. If you need Firebase here, initialize it in main.dart
  // before registering the handler, or initialize inside main (recommended).
  if (kDebugMode) {
    // ignore: avoid_print
    print('📩 (BG) messageId=${message.messageId} data=${message.data}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  NotificationService._();

  GlobalKey<NavigatorState>? _navigatorKey;

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  Future<void> init() async {
    await _requestNotificationPermission();
    await _initFirebaseMessaging();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {
      // Best effort: permission_handler may not support some platforms.
    }
  }

  Future<void> _initFirebaseMessaging() async {
    final messaging = FirebaseMessaging.instance;

    // iOS permission (Android 13+ handled via Permission.notification above)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Ensure notification displays when app is foregrounded on iOS
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Cache current token
    final token = await messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await tokenStorage.setFcmToken(token);
      if (kDebugMode) {
        // ignore: avoid_print
        print('✅ FCM token cached: $token');
      }
    }

    // Listen token refresh
    messaging.onTokenRefresh.listen((newToken) async {
      await tokenStorage.setFcmToken(newToken);
      if (kDebugMode) {
        // ignore: avoid_print
        print('🔄 FCM token refreshed: $newToken');
      }
    });

    // Foreground messages: show local notification
    FirebaseMessaging.onMessage.listen((message) async {
      _showForegroundBanner(message);
    });

    // When user taps notification and app opens
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('📨 onMessageOpenedApp: ${message.messageId}');
      }
    });

    // When app launched by tapping notification (terminated state)
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null && kDebugMode) {
      // ignore: avoid_print
      print('🚀 initialMessage: ${initialMessage.messageId}');
    }
  }

  void _showForegroundBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('📩 (FG) data-only: ${message.data}');
      }
      return;
    }

    final title = notification.title ?? 'Vocafy';
    final body = notification.body ?? '';

    if (kDebugMode) {
      // ignore: avoid_print
      print('📩 (FG) $title - $body');
    }

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    InAppNotificationBanner.show(
      context,
      title: title,
      message: body,
      duration: const Duration(seconds: 4),
    );
  }
}

final notificationService = NotificationService.instance;
