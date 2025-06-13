import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/notification.dart';

/// Firebase notification service for handling push notifications
class FirebaseNotificationService {
  static final FirebaseNotificationService _instance = FirebaseNotificationService._internal();
  factory FirebaseNotificationService() => _instance;
  FirebaseNotificationService._internal();

  static FirebaseNotificationService get instance => _instance;

  FirebaseMessaging? _firebaseMessaging;
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isInitialized = false;
  String? _fcmToken;

  // Stream controllers for notification events
  final StreamController<NotificationEntity> _notificationStreamController = 
      StreamController<NotificationEntity>.broadcast();
  final StreamController<String> _tokenStreamController = 
      StreamController<String>.broadcast();

  /// Stream of received notifications
  Stream<NotificationEntity> get notificationStream => _notificationStreamController.stream;

  /// Stream of FCM token updates
  Stream<String> get tokenStream => _tokenStreamController.stream;

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔔 [FirebaseNotificationService] Already initialized');
      return;
    }

    try {
      debugPrint('🔔 [FirebaseNotificationService] Initializing...');

      // Initialize Firebase if not already done
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
        debugPrint('🔔 [FirebaseNotificationService] Firebase initialized');
      }

      // Initialize Firebase Messaging
      _firebaseMessaging = FirebaseMessaging.instance;

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions
      await _requestPermissions();

      // Setup message handlers
      await _setupMessageHandlers();

      // Get and listen to FCM token
      await _setupFCMToken();

      _isInitialized = true;
      debugPrint('✅ [FirebaseNotificationService] Initialization complete');
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService] Initialization failed: $e');
      rethrow;
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Android initialization
    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const iosInitialization = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidInitialization,
      iOS: iosInitialization,
    );

    await _localNotifications!.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    debugPrint('🔔 [FirebaseNotificationService] Local notifications initialized');
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request Firebase Messaging permissions
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [FirebaseNotificationService] Permission status: ${settings.authorizationStatus}');

      // Request system notification permissions for Android 13+
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        debugPrint('🔔 [FirebaseNotificationService] Android notification permission: $status');
      }
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService] Permission request failed: $e');
    }
  }

  /// Setup FCM token handling
  Future<void> _setupFCMToken() async {
    try {
      // Get initial token
      _fcmToken = await _firebaseMessaging!.getToken();
      if (_fcmToken != null) {
        debugPrint('🔔 [FirebaseNotificationService] FCM Token: $_fcmToken');
        _tokenStreamController.add(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging!.onTokenRefresh.listen((token) {
        debugPrint('🔔 [FirebaseNotificationService] Token refreshed: $token');
        _fcmToken = token;
        _tokenStreamController.add(token);
      });
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService] FCM token setup failed: $e');
    }
  }

  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    debugPrint('🔔 [FirebaseNotificationService] Message handlers setup complete');
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FirebaseNotificationService] Foreground message: ${message.messageId}');
    
    final notification = _createNotificationFromMessage(message);
    _notificationStreamController.add(notification);

    // Show local notification for foreground messages
    _showLocalNotification(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [FirebaseNotificationService] Notification tapped: ${message.messageId}');
    
    final notification = _createNotificationFromMessage(message);
    _notificationStreamController.add(notification);
  }

  /// Handle local notification tap
  void _onLocalNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 [FirebaseNotificationService] Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final notification = NotificationEntity(
          id: data['id'] ?? '',
          userId: data['userId'] ?? '',
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          type: data['type'] ?? '',
          data: data['data'],
          createdAt: DateTime.now(),
        );
        _notificationStreamController.add(notification);
      } catch (e) {
        debugPrint('❌ [FirebaseNotificationService] Error parsing local notification payload: $e');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    if (_localNotifications == null) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'dayliz_notifications',
        'Dayliz Notifications',
        channelDescription: 'Notifications from Dayliz app',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final payload = jsonEncode({
        'id': message.messageId,
        'userId': message.data['userId'],
        'title': message.notification?.title,
        'body': message.notification?.body,
        'type': message.data['type'],
        'data': message.data,
      });

      await _localNotifications!.show(
        message.hashCode,
        message.notification?.title ?? 'Dayliz',
        message.notification?.body ?? '',
        notificationDetails,
        payload: payload,
      );

      debugPrint('🔔 [FirebaseNotificationService] Local notification shown');
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService] Error showing local notification: $e');
    }
  }

  /// Create notification entity from Firebase message
  NotificationEntity _createNotificationFromMessage(RemoteMessage message) {
    return NotificationEntity(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: message.data['userId'] ?? '',
      title: message.notification?.title ?? message.data['title'] ?? '',
      body: message.notification?.body ?? message.data['body'] ?? '',
      type: message.data['type'] ?? NotificationEntity.typeSystemAnnouncement,
      data: message.data,
      imageUrl: message.notification?.android?.imageUrl ?? message.data['imageUrl'],
      actionUrl: message.data['actionUrl'],
      priority: int.tryParse(message.data['priority'] ?? '0') ?? 0,
      createdAt: DateTime.now(),
    );
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (!_isInitialized || _firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.subscribeToTopic(topic);
      debugPrint('🔔 [FirebaseNotificationService] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService] Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isInitialized || _firebaseMessaging == null) return;

    try {
      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      debugPrint('🔔 [FirebaseNotificationService] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ [FirebaseNotificationService] Error unsubscribing from topic $topic: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
    _tokenStreamController.close();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 [FirebaseNotificationService] Background message: ${message.messageId}');
}
