import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/backend_config.dart';
import 'fcm_service.dart';

class PushNotificationService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send location share notification to a specific user
  static Future<bool> sendLocationShareNotification({
    required String recipientUid,
    required String senderName,
    required double latitude,
    required double longitude,
    String? senderUid,
  }) async {
    try {
      print('📤 Push: Sending location share notification to user: $recipientUid');
      
      // Get recipient's FCM token
      final recipientDoc = await _firestore
          .collection('users')
          .doc(recipientUid)
          .get();
      
      if (!recipientDoc.exists) {
        print('❌ Push: Recipient user not found: $recipientUid');
        return false;
      }
      
      final recipientData = recipientDoc.data()!;
      final fcmToken = recipientData['fcmToken'] as String?;
      
      print('🔍 Push: Recipient ${recipientUid} - FCM Token: ${fcmToken != null ? 'Present (${fcmToken.substring(0, 20)}...)' : 'Missing'}');
      
      if (fcmToken == null || fcmToken.isEmpty) {
        print('⚠️ Push: Recipient has no FCM token: $recipientUid');
        return false;
      }
      
      // Try Cloud Function first
      try {
        print('📤 Push: Attempting to call Cloud Function sendLocationShareNotification...');
        
        final result = await _functions
            .httpsCallable('sendLocationShareNotification')
            .call({
          'recipientToken': fcmToken,
          'senderName': senderName,
          'latitude': latitude,
          'longitude': longitude,
          'senderUid': senderUid ?? FirebaseAuth.instance.currentUser?.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        print('✅ Push: Location share notification sent via Cloud Function');
        print('📤 Push: Cloud Function result: $result');
        return true;
      } catch (cloudFunctionError) {
        print('⚠️ Push: Cloud Function failed, trying fallback method: $cloudFunctionError');
        
        // Check if it's a "not found" error (function not deployed)
        if (cloudFunctionError.toString().contains('not-found') || 
            cloudFunctionError.toString().contains('NOT_FOUND') ||
            cloudFunctionError.toString().contains('function not found')) {
          print('❌ Push: Cloud Function not deployed. Please deploy the functions first.');
          print('💡 Push: Run: firebase deploy --only functions');
        }
        
        // Fallback: Send via FCM HTTP API
        return await _sendNotificationViaFirebaseAdmin(
          fcmToken: fcmToken,
          title: '📍 $senderName shared location',
          body: '$senderName shared their location with you',
          data: {
            'type': 'location_share',
            'senderName': senderName,
            'senderUid': senderUid ?? FirebaseAuth.instance.currentUser?.uid ?? '',
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      print('❌ Push: Failed to send location share notification: $e');
      return false;
    }
  }

  /// Send notification to multiple users
  static Future<bool> sendNotificationToMultipleUsers({
    required List<String> recipientUids,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Push: Sending notification to ${recipientUids.length} users');
      
      // Get FCM tokens for all recipients
      final tokens = <String>[];
      for (final uid in recipientUids) {
        try {
          final doc = await _firestore
              .collection('users')
              .doc(uid)
              .get();
          
          if (doc.exists) {
            final userData = doc.data()!;
            final fcmToken = userData['fcmToken'] as String?;
            if (fcmToken != null && fcmToken.isNotEmpty) {
              tokens.add(fcmToken);
            }
          }
        } catch (e) {
          print('⚠️ Push: Failed to get FCM token for user $uid: $e');
        }
      }
      
      if (tokens.isEmpty) {
        print('⚠️ Push: No valid FCM tokens found for recipients');
        return false;
      }
      
      // Send notification using Cloud Function
      final result = await _functions
          .httpsCallable('sendNotificationToMultipleUsers')
          .call({
        'recipientTokens': tokens,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('✅ Push: Notification sent to ${tokens.length} users successfully');
      return true;
    } catch (e) {
      print('❌ Push: Failed to send notification to multiple users: $e');
      return false;
    }
  }

  /// Send notification to all logged-in users except the sender
  static Future<bool> sendNotificationToAllLoggedInUsers({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? excludeUid,
  }) async {
    try {
      print('📤 Push: Sending notification to all logged-in users');
      
      // Get FCM tokens for all logged-in users
      final tokens = await FCMService.getFcmTokensExcept(
        excludeUid ?? FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      
      if (tokens.isEmpty) {
        print('⚠️ Push: No logged-in users found with FCM tokens');
        return false;
      }
      
      // Send notification using Cloud Function
      final result = await _functions
          .httpsCallable('sendNotificationToMultipleUsers')
          .call({
        'recipientTokens': tokens,
        'title': title,
        'body': body,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('✅ Push: Notification sent to ${tokens.length} users successfully');
      return true;
    } catch (e) {
      print('❌ Push: Failed to send notification to all logged-in users: $e');
      return false;
    }
  }

  /// Send emergency notification
  static Future<bool> sendEmergencyNotification({
    required String title,
    required String body,
    required String emergencyType,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('🚨 Push: Sending emergency notification: $emergencyType');
      
      // Get FCM tokens for all users (including offline ones for emergencies)
      final querySnapshot = await _firestore
          .collection('fcmTokens')
          .get();
      
      final tokens = querySnapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .where((token) => token.isNotEmpty)
          .toList();
      
      if (tokens.isEmpty) {
        print('⚠️ Push: No FCM tokens found for emergency notification');
        return false;
      }
      
      // Send emergency notification using Cloud Function
      final result = await _functions
          .httpsCallable('sendEmergencyNotification')
          .call({
        'recipientTokens': tokens,
        'title': title,
        'body': body,
        'emergencyType': emergencyType,
        'data': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'priority': 'high',
      });
      
      print('✅ Push: Emergency notification sent to ${tokens.length} users successfully');
      return true;
    } catch (e) {
      print('❌ Push: Failed to send emergency notification: $e');
      return false;
    }
  }

  /// Subscribe user to a topic
  static Future<bool> subscribeToTopic(String topic) async {
    try {
      print('📱 Push: Subscribing to topic: $topic');
      await FCMService.subscribeToTopic(topic);
      print('✅ Push: Successfully subscribed to topic: $topic');
      return true;
    } catch (e) {
      print('❌ Push: Failed to subscribe to topic $topic: $e');
      return false;
    }
  }

  /// Unsubscribe user from a topic
  static Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      print('📱 Push: Unsubscribing from topic: $topic');
      await FCMService.unsubscribeFromTopic(topic);
      print('✅ Push: Successfully unsubscribed from topic: $topic');
      return true;
    } catch (e) {
      print('❌ Push: Failed to unsubscribe from topic $topic: $e');
      return false;
    }
  }

  /// Get notification statistics
  static Future<Map<String, dynamic>> getNotificationStats() async {
    try {
      print('📊 Push: Getting notification statistics');
      
      final result = await _functions
          .httpsCallable('getNotificationStats')
          .call();
      
      final stats = result.data as Map<String, dynamic>;
      print('✅ Push: Notification statistics retrieved successfully');
      return stats;
    } catch (e) {
      print('❌ Push: Failed to get notification statistics: $e');
      return {};
    }
  }

  /// Fallback method when Cloud Functions are not available
  /// This uses the local FCM backend server as a fallback
  static Future<bool> _sendNotificationViaFirebaseAdmin({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      print('📤 Push: Cloud Functions not available - trying local FCM backend...');
      
      // Use local FCM backend server as fallback
      final success = await _sendViaLocalBackend(
        fcmToken: fcmToken,
        title: title,
        body: body,
        data: data,
      );
      
      if (success) {
        print('✅ Push: Notification sent successfully via local FCM backend');
        return true;
      } else {
        print('❌ Push: Local FCM backend failed');
        return false;
      }
    } catch (e) {
      print('❌ Push: Fallback method failed: $e');
      return false;
    }
  }

  /// Send notification directly to a specific FCM token
  static Future<bool> sendToToken({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 Push: Sending notification to token: ${fcmToken.substring(0, 20)}...');
      
      // Try Cloud Function first
      try {
        final result = await _functions
            .httpsCallable('sendNotificationToToken')
            .call({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
          'timestamp': FieldValue.serverTimestamp(),
        });
        
        print('✅ Push: Notification sent via Cloud Function');
        return true;
      } catch (cloudFunctionError) {
        print('⚠️ Push: Cloud Function failed, trying fallback: $cloudFunctionError');
        
        // Fallback: Send via local backend
        return await _sendViaLocalBackend(
          fcmToken: fcmToken,
          title: title,
          body: body,
          data: data?.map((key, value) => MapEntry(key, value.toString())),
        );
      }
    } catch (e) {
      print('❌ Push: Failed to send notification to token: $e');
      return false;
    }
  }

  /// Send notification via local FCM backend server
  static Future<bool> _sendViaLocalBackend({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(BackendConfig.sendPushEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] == true;
      } else {
        print('❌ Local Backend: HTTP error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Local Backend: Failed to send notification: $e');
      return false;
    }
  }
}

