import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';
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
    
    // Parse payload and open location directly in maps if it's a location share
    if (response.payload != null) {
      try {
        // Parse the payload string back to Map
        final payloadString = response.payload!;
        print('📱 NotificationService: Parsing payload: $payloadString');
        
        // Simple parsing for location share notifications
        if (payloadString.contains('type') && payloadString.contains('location_share')) {
          _openLocationDirectlyInMapsFromPayload(payloadString);
        }
      } catch (e) {
        print('❌ NotificationService: Failed to parse notification payload: $e');
      }
    }
  }

  /// Open location directly in Google Maps from notification payload
  static Future<void> _openLocationDirectlyInMapsFromPayload(String payloadString) async {
    try {
      // Extract coordinates from payload string
      // This is a simple extraction - in production you might want more robust parsing
      final latMatch = RegExp(r'latitude[^0-9-]*([0-9.-]+)').firstMatch(payloadString);
      final lngMatch = RegExp(r'longitude[^0-9-]*([0-9.-]+)').firstMatch(payloadString);
      final nameMatch = RegExp(r'senderName[^a-zA-Z]*([a-zA-Z\s]+)').firstMatch(payloadString);
      
      if (latMatch != null && lngMatch != null) {
        final latitude = double.tryParse(latMatch.group(1) ?? '0') ?? 0.0;
        final longitude = double.tryParse(lngMatch.group(1) ?? '0') ?? 0.0;
        final senderName = nameMatch?.group(1)?.trim() ?? 'User';
        
        print('🗺️ NotificationService: Opening location directly in Google Maps...');
        print('📍 Coordinates: $latitude, $longitude');
        print('👤 Sender: $senderName');
        
        // Format coordinates with proper precision
        final latFormatted = latitude.toStringAsFixed(6);
        final lngFormatted = longitude.toStringAsFixed(6);
        final coordinates = '$latFormatted,$lngFormatted';
        final locationName = senderName.replaceAll(' ', '+');
        
        // Try different Google Maps URLs in order of preference
        final urls = [
          // Google Maps app (Android/iOS) - Use proper format for location display
          'comgooglemaps://?q=$coordinates&center=$coordinates&zoom=15',
          // Google Maps app alternative format
          'comgooglemaps://?center=$coordinates&zoom=15',
          // Apple Maps (iOS) - Use proper format for location display
          'http://maps.apple.com/?q=$coordinates&ll=$coordinates&z=15',
          // Google Maps web - Use place format for better location display
          'https://www.google.com/maps/place/$coordinates/@$coordinates,15z',
          // Google Maps web - Alternative format with search
          'https://www.google.com/maps/search/?api=1&query=$coordinates',
          // Google Maps web - Fallback with location name
          'https://www.google.com/maps/search/?api=1&query=$locationName+$coordinates',
        ];
        
        bool opened = false;
        for (final url in urls) {
          try {
            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              print('✅ NotificationService: Opened in maps app: $url');
              opened = true;
              break;
            }
          } catch (e) {
            print('⚠️ NotificationService: Failed to open $url: $e');
            continue;
          }
        }
        
        if (!opened) {
          print('❌ NotificationService: Could not open any maps app from notification');
        }
      } else {
        print('⚠️ NotificationService: Could not extract coordinates from payload');
      }
    } catch (e) {
      print('❌ NotificationService: Failed to open location in maps from payload: $e');
    }
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
