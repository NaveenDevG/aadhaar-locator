import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../features/notifications/services/fcm_service.dart';

class DevelopmentHelperService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Check Firebase Auth status
  static Future<Map<String, dynamic>> checkFirebaseAuthStatus() async {
    try {
      print('🔍 Dev Helper: Checking Firebase Auth status...');
      
      final status = <String, dynamic>{};
      
      // Check if Firebase is initialized
      try {
        final currentUser = _auth.currentUser;
        status['firebase_initialized'] = true;
        status['current_user'] = currentUser != null;
        if (currentUser != null) {
          status['user_uid'] = currentUser.uid;
          status['user_email'] = currentUser.email;
          status['user_email_verified'] = currentUser.emailVerified;
        }
      } catch (e) {
        status['firebase_initialized'] = false;
        status['firebase_error'] = e.toString();
      }
      
      // Check Firestore connection
      try {
        await _firestore.collection('test').doc('test').get();
        status['firestore_connected'] = true;
      } catch (e) {
        status['firestore_connected'] = false;
        status['firestore_error'] = e.toString();
      }
      
      // Check FCM status
      try {
        final token = await _messaging.getToken();
        status['fcm_available'] = token != null;
        status['fcm_token'] = token?.substring(0, 10) + '...';
      } catch (e) {
        status['fcm_available'] = false;
        status['fcm_error'] = e.toString();
      }
      
      print('✅ Dev Helper: Firebase status check completed');
      return status;
    } catch (e) {
      print('❌ Dev Helper: Failed to check Firebase status: $e');
      return {'error': e.toString()};
    }
  }

  /// Create a test user for development
  static Future<Map<String, dynamic>> createTestUser({
    required String email,
    required String password,
  }) async {
    try {
      print('🔍 Dev Helper: Creating test user: $email');
      
      // Check if user already exists
      try {
        final existingUser = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        print('✅ Dev Helper: Test user already exists and login successful');
        return {
          'success': true,
          'action': 'login_existing',
          'user_uid': existingUser.user?.uid,
          'message': 'User already exists and login successful',
        };
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // User doesn't exist, create new one
          print('🔍 Dev Helper: User not found, creating new test user...');
          
          final newUser = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          print('✅ Dev Helper: Test user created successfully');
          return {
            'success': true,
            'action': 'created_new',
            'user_uid': newUser.user?.uid,
            'message': 'New test user created successfully',
          };
        } else if (e.code == 'wrong-password') {
          print('❌ Dev Helper: Wrong password for existing user');
          return {
            'success': false,
            'action': 'wrong_password',
            'error': 'Wrong password for existing user',
          };
        } else {
          print('❌ Dev Helper: Firebase auth error: ${e.code}');
          return {
            'success': false,
            'action': 'auth_error',
            'error': 'Firebase auth error: ${e.code}',
          };
        }
      }
    } catch (e) {
      print('❌ Dev Helper: Failed to create test user: $e');
      return {
        'success': false,
        'action': 'unknown_error',
        'error': e.toString(),
      };
    }
  }

  /// Test FCM functionality
  static Future<Map<String, dynamic>> testFcmFunctionality() async {
    try {
      print('🔍 Dev Helper: Testing FCM functionality...');
      
      final results = <String, dynamic>{};
      
      // Test 1: Get FCM token
      try {
        final token = await _messaging.getToken();
        results['fcm_token_available'] = token != null;
        results['fcm_token'] = token?.substring(0, 10) + '...';
        print('✅ Dev Helper: FCM token test passed');
      } catch (e) {
        results['fcm_token_available'] = false;
        results['fcm_token_error'] = e.toString();
        print('❌ Dev Helper: FCM token test failed: $e');
      }
      
      // Test 2: Check permissions
      try {
        final permission = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        results['fcm_permissions'] = permission.authorizationStatus.toString();
        print('✅ Dev Helper: FCM permissions test passed');
      } catch (e) {
        results['fcm_permissions'] = 'error';
        results['fcm_permissions_error'] = e.toString();
        print('❌ Dev Helper: FCM permissions test failed: $e');
      }
      
      // Test 3: Initialize FCM service
      try {
        await FCMService.initialize();
        results['fcm_service_initialized'] = true;
        print('✅ Dev Helper: FCM service initialization test passed');
      } catch (e) {
        results['fcm_service_initialized'] = false;
        results['fcm_service_error'] = e.toString();
        print('❌ Dev Helper: FCM service initialization test failed: $e');
      }
      
      print('✅ Dev Helper: FCM functionality test completed');
      return results;
    } catch (e) {
      print('❌ Dev Helper: Failed to test FCM functionality: $e');
      return {'error': e.toString()};
    }
  }

  /// Run comprehensive development tests
  static Future<Map<String, dynamic>> runComprehensiveTests() async {
    print('🧪 Dev Helper: Starting comprehensive development tests...');
    
    final allResults = <String, dynamic>{};
    
    // Test 1: Firebase Auth status
    print('\n🔍 Test 1: Firebase Auth Status');
    allResults['firebase_auth'] = await checkFirebaseAuthStatus();
    
    // Test 2: FCM functionality
    print('\n🔍 Test 2: FCM Functionality');
    allResults['fcm_functionality'] = await testFcmFunctionality();
    
    // Test 3: Create test user (if no user is logged in)
    if (_auth.currentUser == null) {
      print('\n🔍 Test 3: Test User Creation');
      allResults['test_user_creation'] = await createTestUser(
        email: 'test@example.com',
        password: 'testpass123',
      );
    } else {
      print('\n🔍 Test 3: Test User Creation (skipped - user already logged in)');
      allResults['test_user_creation'] = {
        'skipped': true,
        'reason': 'User already logged in',
        'current_user': _auth.currentUser?.email,
      };
    }
    
    // Print summary
    print('\n🧪 Dev Helper: Comprehensive Test Results Summary:');
    allResults.forEach((testName, results) {
      print('\n📊 $testName:');
      if (results is Map) {
        results.forEach((key, value) {
          print('   $key: $value');
        });
      } else {
        print('   $results');
      }
    });
    
    return allResults;
  }

  /// Get current user profile from Firestore
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('⚠️ Dev Helper: No user logged in');
        return null;
      }
      
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Dev Helper: User profile retrieved successfully');
        return data;
      } else {
        print('⚠️ Dev Helper: User profile not found in Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Dev Helper: Failed to get user profile: $e');
      return null;
    }
  }

  /// Clear all test data (use with caution)
  static Future<bool> clearTestData() async {
    try {
      print('🧹 Dev Helper: Clearing test data...');
      
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user profile from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        await _firestore.collection('fcmTokens').doc(user.uid).delete();
        print('✅ Dev Helper: Test data cleared from Firestore');
      }
      
      // Sign out
      await _auth.signOut();
      print('✅ Dev Helper: User signed out');
      
      return true;
    } catch (e) {
      print('❌ Dev Helper: Failed to clear test data: $e');
      return false;
    }
  }
}

