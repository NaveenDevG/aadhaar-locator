import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_service.dart';

class FCMTestService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Test FCM token generation and storage
  static Future<bool> testFcmTokenGeneration() async {
    try {
      print('🧪 FCM Test: Testing FCM token generation...');
      
      // Check if FCM service is initialized
      if (!FCMService.isAvailable) {
        print('❌ FCM Test: FCM service not available');
        return false;
      }
      
      // Get current token
      final token = FCMService.currentToken;
      if (token == null) {
        print('❌ FCM Test: No FCM token available');
        return false;
      }
      
      print('✅ FCM Test: FCM token available: ${token.substring(0, 10)}...');
      
      // Test token update
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FCMService.updateTokenForUser(user.uid);
        print('✅ FCM Test: FCM token updated successfully');
      }
      
      return true;
    } catch (e) {
      print('❌ FCM Test: Failed to test FCM token generation: $e');
      return false;
    }
  }

  /// Test sending a test notification
  static Future<bool> testNotificationSending() async {
    try {
      print('🧪 FCM Test: Testing notification sending...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ FCM Test: No user logged in');
        return false;
      }
      
      // Send test notification to self
      final result = await _functions
          .httpsCallable('sendTestNotification')
          .call({
        'recipientToken': FCMService.currentToken,
        'title': 'Test Notification',
        'body': 'This is a test notification from FCM',
        'data': {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      });
      
      print('✅ FCM Test: Test notification sent successfully');
      return true;
    } catch (e) {
      print('❌ FCM Test: Failed to send test notification: $e');
      return false;
    }
  }

  /// Test FCM permissions
  static Future<bool> testFcmPermissions() async {
    try {
      print('🧪 FCM Test: Testing FCM permissions...');
      
      // This will be handled by the FCM service
      // We just need to check if it's working
      if (FCMService.isAvailable) {
        print('✅ FCM Test: FCM permissions are working');
        return true;
      } else {
        print('❌ FCM Test: FCM permissions are not working');
        return false;
      }
    } catch (e) {
      print('❌ FCM Test: Failed to test FCM permissions: $e');
      return false;
    }
  }

  /// Run all FCM tests
  static Future<Map<String, bool>> runAllTests() async {
    print('🧪 FCM Test: Starting all FCM tests...');
    
    final results = <String, bool>{};
    
    // Test 1: Token generation
    results['token_generation'] = await testFcmTokenGeneration();
    
    // Test 2: Permissions
    results['permissions'] = await testFcmPermissions();
    
    // Test 3: Notification sending (only if other tests pass)
    if (results['token_generation'] == true && results['permissions'] == true) {
      results['notification_sending'] = await testNotificationSending();
    } else {
      results['notification_sending'] = false;
    }
    
    // Print summary
    print('🧪 FCM Test: Test Results Summary:');
    results.forEach((test, result) {
      final status = result ? '✅ PASS' : '❌ FAIL';
      print('   $test: $status');
    });
    
    return results;
  }
}

