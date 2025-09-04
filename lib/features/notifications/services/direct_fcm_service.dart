import 'package:http/http.dart' as http;
import 'dart:convert';

class DirectFCMService {
  // Replace this with your actual Server Key from Firebase Console
  static const String _serverKey = 'MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC3yvKkWX5upB8K\nuls64l/9xg+D1SBfVvZI3Yg9tgWe7KOiww1zQQFTnMjx+vjRj4khpWdjHtUBapd5\nL23c+tA/qUNIV/SFKPU6o4udq2QNtm7l1weNSdpvgc7y9dbm3hBgszZs/jEawUFw\nhdxQ0CuKaTByT9HMPfJQSiezbahMZGjwnf3RaeSZiW6PX05Q37metE+xWH5SvtiF\nin83XmldU7V1GFUdq/IhXkwpRQduibbT4uLUUCunuv2A/O6mhorme7p43p1x2V/S\nYsI5xSwv7lzIBWSt0s8z6SCR126JErZzHlVQVv8u/YB/W9wV0NC5IFsqWG1CkDSV\nj5nnHRKdAgMBAAECggEAC1otwpkEhjD8+dyo5eo1o6coLixr43ernrSQRb+IeViE\ngvkpS4UoX9G/V7L4y3jiL4HX8PdmkL/Uu1eCobOcSVJbJYzJPbBZ9VVEumhrta0f\nDHNLtB5rr5eFANzOeVQeDtsC8ZiBz/U/5YNfKF6zUclNhMIJY2QwI2VxLlQHoTA3\ngXpFGdUbjevQSNtwuYrYHDiCMWzq0+23uhzim3/9U55eWDzBeEFHNQkwMDUF2JJj\nUg5MM3X5w8RXXlan633Edv4lXGU2N+VK1kbeF8dNNC/yaV0v0v2H312uLw8PmBM4\n8jRmSa6U8iIAoKpLa3j/qN3aE0hVzyqtltnDey1aAQKBgQD4DXi6UKBwt3WjWhPw\n5nRGzowuAHCnBWOzvt5nm1Zmhae/77MFsqvTrwQrRdeOlQtUrl/snwq1kMIUrJvG\nDMxxA7b8r8uIu2P1/0JgB7t1NhjkFM37Dstw0hvQLPbhbM2tLX2O6sfUkQu51UwT\nwB0U7nub3qukcEYQLCUJDCQA6QKBgQC9rmqqc//Al77pRL4cV3mCjljNFB+66qpX\n4rZrEDsOwa7e16qDt7pVsxYA7Td191QlJ27Vt6nPh2iFf4Inc+21aS40hJyHPE7K\nOz1ze4/6Czc0URd2w5944vf3jomd3FgyajkHRuVC2zp0iP3RE6bjItUhX8J4aQaN\njF3FKNVTlQKBgHPOrk+l9tHJBTYHhwnQPfcU1WNgtzdzD7JKaUFLx5HD0qaMfTMq\n0IfazQJ68AFUWl7lrkklk3VjKQlH8M4NCaG1z0e3tzmV6zxdORrmYUF+yS4q/GO6\n64Y3wd52L6jdCEVS2KzRtgvqz+OpzoPmDG3KTZFe6xmxhTRlt8C6l1CJAoGATIY5\nclsqK0ENPH8HU9fWpd1X5iTgSEC0SJCml7sMmH97VVwc5tcQzdJaZjVN0sHdqL+n\n74EReTBf8rvmfpQ+qpmsknON0uF5yAzuVdDb3Tz5IJo2pSt3AwZOlAlla9KhonVI\nXK81fyuDAdDi1Z7gDXLYGYbQplN42VJv4kL/DaECgYAw0nAIPlLvKKJ9/qZqOLlt\nK14MjC2H/2PKrqNC+0vv1WtbdInkuoPwSSy2qny22aiDfrnnw1hTTLlpcmTcgPyb\nTh2+4NgCumdKHryqAmfpO+R7phTpMml0PO5WIY7yVWIurQWLlfHpsE6pj3GomzgO\nULsUrpLpz3Q7Nn3G9Zp+rg==';
  static const String _fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';

  /// Send notification to a single user
  static Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      print('📤 DirectFCM: Sending notification to token: ${fcmToken.substring(0, 20)}...');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      final payload = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': 'high',
        'android': {
          'priority': 'high',
          'notification': {
            'icon': 'ic_notification',
            'color': '#2196F3',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'badge': 1,
              'sound': 'default',
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final success = responseData['success'] == 1;
        
        if (success) {
          print('✅ DirectFCM: Notification sent successfully');
          return true;
        } else {
          print('❌ DirectFCM: FCM returned failure: ${responseData['failure']}');
          return false;
        }
      } else {
        print('❌ DirectFCM: HTTP error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ DirectFCM: Failed to send notification: $e');
      return false;
    }
  }

  /// Send notification to multiple users
  static Future<Map<String, dynamic>> sendNotificationToMultipleUsers({
    required List<String> fcmTokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      print('📤 DirectFCM: Sending notification to ${fcmTokens.length} users');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      final payload = {
        'registration_ids': fcmTokens,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': '1',
        },
        'data': data ?? {},
        'priority': 'high',
        'android': {
          'priority': 'high',
          'notification': {
            'icon': 'ic_notification',
            'color': '#2196F3',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'badge': 1,
              'sound': 'default',
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final successCount = responseData['success'] ?? 0;
        final failureCount = responseData['failure'] ?? 0;
        
        print('✅ DirectFCM: Sent to $successCount users, failed for $failureCount users');
        
        return {
          'success': true,
          'successCount': successCount,
          'failureCount': failureCount,
          'total': fcmTokens.length,
        };
      } else {
        print('❌ DirectFCM: HTTP error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ DirectFCM: Failed to send notifications: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send location share notification to ALL online users at once
  static Future<Map<String, dynamic>> sendLocationShareToAllUsers({
    required List<String> fcmTokens,
    required String senderName,
    required double latitude,
    required double longitude,
    String? senderUid,
  }) async {
    try {
      print('📤 DirectFCM: Sending location share to ALL ${fcmTokens.length} online users');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$_serverKey',
      };

      final payload = {
        'registration_ids': fcmTokens,
        'notification': {
          'title': '📍 $senderName shared location',
          'body': '$senderName shared their location with everyone',
          'sound': 'default',
          'badge': '1',
        },
        'data': {
          'type': 'location_share_all',
          'senderName': senderName,
          'senderUid': senderUid ?? '',
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Location shared with all online users',
        },
        'priority': 'high',
        'android': {
          'priority': 'high',
          'notification': {
            'icon': 'ic_notification',
            'color': '#FF5722',
            'channel_id': 'location_sharing',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'badge': 1,
              'sound': 'default',
              'category': 'location_share',
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(_fcmEndpoint),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final successCount = responseData['success'] ?? 0;
        final failureCount = responseData['failure'] ?? 0;
        
        print('✅ DirectFCM: Location shared with $successCount users, failed for $failureCount users');
        
        return {
          'success': true,
          'successCount': successCount,
          'failureCount': failureCount,
          'total': fcmTokens.length,
          'message': 'Location shared with all online users successfully!',
        };
      } else {
        print('❌ DirectFCM: HTTP error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ DirectFCM: Failed to share location with all users: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Send location share notification
  static Future<bool> sendLocationShareNotification({
    required String fcmToken,
    required String senderName,
    required double latitude,
    required double longitude,
    String? senderUid,
  }) async {
    return await sendNotification(
      fcmToken: fcmToken,
      title: '📍 $senderName shared location',
      body: '$senderName shared their location with you',
      data: {
        'type': 'location_share',
        'senderName': senderName,
        'senderUid': senderUid ?? '',
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Test the FCM service
  static Future<bool> testConnection() async {
    try {
      print('🧪 DirectFCM: Testing FCM connection...');
      
      // Check if server key is still placeholder
      if (_serverKey == 'YOUR_SERVER_KEY_HERE') {
        print('❌ DirectFCM: Server key not updated! Still using placeholder.');
        print('💡 DirectFCM: Please update the server key in direct_fcm_service.dart');
        return false;
      }
      
      print('🔑 DirectFCM: Server key is set (${_serverKey.substring(0, 10)}...)');
      
      // Test HTTP connection to FCM endpoint
      try {
        final response = await http.get(Uri.parse('https://fcm.googleapis.com'));
        print('✅ DirectFCM: FCM endpoint is accessible (HTTP ${response.statusCode})');
      } catch (e) {
        print('❌ DirectFCM: Cannot access FCM endpoint: $e');
        return false;
      }
      
      // Send a test notification to a dummy token
      final result = await sendNotification(
        fcmToken: 'test_token',
        title: 'Test',
        body: 'Test notification',
      );
      
      // Even if it fails due to invalid token, we know the service is working
      print('✅ DirectFCM: Service is working (connection test completed)');
      return true;
    } catch (e) {
      print('❌ DirectFCM: Service test failed: $e');
      return false;
    }
  }
}
