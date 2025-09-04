import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'fcm_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Initialize FCM service
    try {
      await FCMService.initialize();
      print('✅ NotificationService: FCM service initialized');
    } catch (e) {
      print('❌ NotificationService: Failed to initialize FCM service: $e');
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print('Notification tapped: ${response.payload}');
  }

  /// Handle FCM message and show local notification
  static Future<void> handleFcmMessage(RemoteMessage message) async {
    try {
      print('📱 NotificationService: Handling FCM message: ${message.messageId}');
      
      final notification = message.notification;
      if (notification != null) {
        await showNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? '',
          payload: message.data,
        );
      } else if (message.data.isNotEmpty) {
        // Handle data-only messages
        final title = message.data['title'] ?? 'New Message';
        final body = message.data['body'] ?? '';
        
        await showNotification(
          title: title,
          body: body,
          payload: message.data,
        );
      }
      
      print('✅ NotificationService: FCM message handled successfully');
    } catch (e) {
      print('❌ NotificationService: Failed to handle FCM message: $e');
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload?.toString(),
    );
  }

  static Future<void> showLocationShareNotification({
    required String senderName,
    required double latitude,
    required double longitude,
  }) async {
    await showNotification(
      title: 'Location Shared',
      body: '$senderName has shared their location with you',
      payload: {
        'type': 'location_share',
        'senderName': senderName,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    );
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}

class NotificationPayload {
  final String senderName;
  final double latitude;
  final double longitude;
  final String? senderUid;

  const NotificationPayload({
    required this.senderName,
    required this.latitude,
    required this.longitude,
    this.senderUid,
  });

  factory NotificationPayload.fromMap(Map<String, dynamic> data) {
    return NotificationPayload(
      senderName: data['senderName'] as String? ?? 'User',
      latitude: double.tryParse(data['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(data['lng']?.toString() ?? '0') ?? 0.0,
      senderUid: data['senderUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'lat': latitude,
      'lng': longitude,
      if (senderUid != null) 'senderUid': senderUid,
    };
  }
}
