import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/backend_config.dart';

class BackendFCMService {
  
  /// Send notification to a single user via backend
  static Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 BackendFCM: Sending notification via backend...');
      
      final response = await http.post(
        Uri.parse(BackendConfig.sendPushEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('✅ BackendFCM: Notification sent successfully');
          return true;
        } else {
          print('❌ BackendFCM: Backend returned error: ${responseData['error']}');
          return false;
        }
      } else {
        print('❌ BackendFCM: HTTP error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ BackendFCM: Error sending notification: $e');
      return false;
    }
  }

  /// Send notification to multiple users via backend
  static Future<Map<String, dynamic>> sendNotificationToMultipleUsers({
    required List<String> fcmTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 BackendFCM: Sending notification to ${fcmTokens.length} users via backend...');
      
      final response = await http.post(
        Uri.parse(BackendConfig.sendPushToMultipleEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tokens': fcmTokens,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('✅ BackendFCM: Notification sent to ${responseData['successCount']}/${fcmTokens.length} users');
          return {
            'success': true,
            'successCount': responseData['successCount'],
            'failureCount': responseData['failureCount'],
            'totalCount': fcmTokens.length,
          };
        } else {
          print('❌ BackendFCM: Backend returned error: ${responseData['error']}');
          return {
            'success': false,
            'error': responseData['error'],
          };
        }
      } else {
        print('❌ BackendFCM: HTTP error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ BackendFCM: Error sending notifications: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send location share notification via backend
  static Future<bool> sendLocationShareNotification({
    required String fcmToken,
    required String senderName,
    required double latitude,
    required double longitude,
    required String senderUid,
  }) async {
    return await sendNotification(
      fcmToken: fcmToken,
      title: '📍 $senderName shared location',
      body: '$senderName shared their location with you',
      data: {
        'type': 'location_share',
        'senderName': senderName,
        'senderUid': senderUid,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send location share to all users via backend
  static Future<Map<String, dynamic>> sendLocationShareToAllUsers({
    required List<String> fcmTokens,
    required String senderName,
    required double latitude,
    required double longitude,
    required String senderUid,
  }) async {
    print('📤 BackendFCM: Sending location share to ${fcmTokens.length} users via backend...');
    
    return await sendNotificationToMultipleUsers(
      fcmTokens: fcmTokens,
      title: '📍 $senderName shared location',
      body: '$senderName shared their location with you',
      data: {
        'type': 'location_share',
        'senderName': senderName,
        'senderUid': senderUid,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Test backend connection
  static Future<bool> testConnection() async {
    try {
      print('🔍 BackendFCM: Testing backend connection...');
      
      final response = await http.get(
        Uri.parse('$_backendUrl/'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['status'] == 'OK') {
          print('✅ BackendFCM: Backend is running and accessible');
          return true;
        } else {
          print('❌ BackendFCM: Backend returned unexpected status');
          return false;
        }
      } else {
        print('❌ BackendFCM: Backend not accessible (HTTP ${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ BackendFCM: Backend connection test failed: $e');
      return false;
    }
  }
}
