import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _currentToken;
  static bool _isInitialized = false;

  /// Initialize FCM service
  static Future<void> initialize({Function(Map<String, dynamic>)? onDeepLinkToMap}) async {
    if (_isInitialized) return;

    try {
      print('🔔 FCM: Initializing FCM service...');

      // Request notification permissions
      final permission = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 FCM: Permission status: ${permission.authorizationStatus}');

      if (permission.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM: Notification permissions granted');
      } else if (permission.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ FCM: Provisional notification permissions granted');
      } else {
        print('❌ FCM: Notification permissions denied');
      }

      // Get the token
      await _getAndSaveToken();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((token) {
        print('🔄 FCM: Token refreshed: ${token.substring(0, 10)}...');
        _currentToken = token;
        _saveTokenToFirestore(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _handleNotificationTap(message);
        if (onDeepLinkToMap != null) {
          _handleDeepLink(message, onDeepLinkToMap);
        }
      });

      // Handle initial message if app was terminated
      try {
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null && onDeepLinkToMap != null) {
          _handleDeepLink(initialMessage, onDeepLinkToMap);
        }
      } catch (e) {
        print('⚠️ FCM: Initial message check failed: $e');
      }

      _isInitialized = true;
      print('✅ FCM: Service initialized successfully');
    } catch (e) {
      print('❌ FCM: Failed to initialize: $e');
      rethrow;
    }
  }

  /// Get current FCM token
  static String? get currentToken => _currentToken;

  /// Get and save FCM token
  static Future<String?> _getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print('🔔 FCM: Got token: ${token.substring(0, 10)}...');
        _currentToken = token;
        await _saveTokenToFirestore(token);
        return token;
      } else {
        print('⚠️ FCM: Failed to get token');
        return null;
      }
    } catch (e) {
      print('❌ FCM: Error getting token: $e');
      return null;
    }
  }

  /// Save token to Firestore
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('💾 FCM: Saving token to Firestore for user: ${user.uid}');
        
        // Update user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update FCM tokens collection
        await FirebaseFirestore.instance
            .collection('fcmTokens')
            .doc(user.uid)
            .set({
          'token': token,
          'uid': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.toString(),
          'appVersion': '1.0.0', // You can make this dynamic
        }, SetOptions(merge: true));

        print('✅ FCM: Token saved to Firestore successfully');
      } else {
        print('⚠️ FCM: No user logged in, skipping token save');
      }
    } catch (e) {
      print('❌ FCM: Failed to save token to Firestore: $e');
    }
  }

  /// Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    print('📱 FCM: Received foreground message: ${message.messageId}');
    print('📱 FCM: Message data: ${message.data}');
    print('📱 FCM: Message notification: ${message.notification?.title}');

    // Show local notification for foreground messages
    NotificationService.handleFcmMessage(message);
  }

  /// Handle notification taps
  static void _handleNotificationTap(RemoteMessage message) {
    print('👆 FCM: Notification tapped: ${message.messageId}');
    print('👆 FCM: Message data: ${message.data}');

    // Handle direct maps opening for location share notifications
    if (message.data['type'] == 'location_share') {
      _openLocationDirectlyInMapsFromNotification(message.data);
    }
  }

  /// Open location directly in Google Maps from notification tap
  static Future<void> _openLocationDirectlyInMapsFromNotification(Map<String, dynamic> data) async {
    try {
      final latitude = double.tryParse(data['latitude'] ?? '0') ?? 0.0;
      final longitude = double.tryParse(data['longitude'] ?? '0') ?? 0.0;
      final senderName = data['senderName'] ?? 'User';
      
      print('🗺️ FCM: Opening location directly in Google Maps from notification...');
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
            print('✅ FCM: Opened in maps app: $url');
            opened = true;
            break;
          }
        } catch (e) {
          print('⚠️ FCM: Failed to open $url: $e');
          continue;
        }
      }
      
      if (!opened) {
        print('❌ FCM: Could not open any maps app from notification');
      }
    } catch (e) {
      print('❌ FCM: Failed to open location in maps from notification: $e');
    }
  }

  /// Handle deep links from notifications
  static void _handleDeepLink(RemoteMessage message, Function(Map<String, dynamic>) onDeepLinkToMap) {
    try {
      print('🔗 FCM: Handling deep link from notification: ${message.messageId}');
      
      final data = message.data;
      if (data['type'] == 'location_share') {
        final payload = {
          'senderName': data['senderName'] ?? 'User',
          'latitude': double.tryParse(data['latitude'] ?? '0') ?? 0.0,
          'longitude': double.tryParse(data['longitude'] ?? '0') ?? 0.0,
        };
        
        print('🔗 FCM: Deep linking to map with payload: $payload');
        onDeepLinkToMap(payload);
      } else {
        print('🔗 FCM: Unknown deep link type: ${data['type']}');
      }
    } catch (e) {
      print('❌ FCM: Failed to handle deep link: $e');
    }
  }

  /// Update FCM token for a specific user
  static Future<void> updateTokenForUser(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        _currentToken = token;
        await _saveTokenToFirestore(token);
        print('✅ FCM: Token updated for user: $uid');
      }
    } catch (e) {
      print('❌ FCM: Failed to update token for user $uid: $e');
    }
  }

  /// Delete FCM token (useful for logout)
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      print('🗑️ FCM: Token deleted successfully');
    } catch (e) {
      print('❌ FCM: Failed to delete token: $e');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ FCM: Subscribed to topic: $topic');
    } catch (e) {
      print('❌ FCM: Failed to subscribe to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ FCM: Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ FCM: Failed to unsubscribe from topic $topic: $e');
    }
  }

  /// Get all FCM tokens for logged-in users except the specified user
  static Future<List<String>> getFcmTokensExcept(String excludeUid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('fcmTokens')
          .where('uid', isNotEqualTo: excludeUid)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .where((token) => token.isNotEmpty)
          .toList();
    } catch (e) {
      print('❌ FCM: Failed to fetch FCM tokens: $e');
      return [];
    }
  }

  /// Check if FCM is available
  static bool get isAvailable => _isInitialized && _currentToken != null;
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔄 FCM: Handling background message: ${message.messageId}');
  print('🔄 FCM: Message data: ${message.data}');
  
  // You can perform background tasks here
  // For example, updating local storage, making API calls, etc.
}
