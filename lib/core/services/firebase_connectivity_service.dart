import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseConnectivityService {
  static final FirebaseConnectivityService _instance = FirebaseConnectivityService._internal();
  factory FirebaseConnectivityService() => _instance;
  FirebaseConnectivityService._internal();

  bool _isConnected = false;
  bool _isInitialized = false;
  String? _lastError;

  bool get isConnected => _isConnected;
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;

  /// Test Firebase connectivity with multiple fallback methods
  Future<bool> testConnectivity({Duration timeout = const Duration(seconds: 30)}) async {
    print('🔍 FirebaseConnectivityService: Testing connectivity...');
    
    try {
      // Method 1: Test Firestore basic connection
      print('📝 Method 1: Testing Firestore basic connection...');
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_test_connection').limit(1).get().timeout(timeout);
      print('✅ Method 1: Firestore connection successful');
      _isConnected = true;
      _lastError = null;
      return true;
    } catch (e) {
      print('❌ Method 1: Firestore connection failed: $e');
      _lastError = e.toString();
      
      // Method 2: Test Firebase Auth connection
      try {
        print('🔐 Method 2: Testing Firebase Auth connection...');
        final auth = FirebaseAuth.instance;
        // Just check if auth is available, don't actually sign in
        await auth.authStateChanges().first.timeout(const Duration(seconds: 10));
        print('✅ Method 2: Firebase Auth connection successful');
        _isConnected = true;
        _lastError = null;
        return true;
      } catch (e2) {
        print('❌ Method 2: Firebase Auth connection failed: $e2');
        _lastError = e2.toString();
        
        // Method 3: Test with a simple document creation (will fail but shows connectivity)
        try {
          print('📄 Method 3: Testing with document creation...');
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('_test_connection').add({
            'timestamp': FieldValue.serverTimestamp(),
            'test': true,
          }).timeout(const Duration(seconds: 15));
          print('✅ Method 3: Document creation successful');
          _isConnected = true;
          _lastError = null;
          return true;
        } catch (e3) {
          print('❌ Method 3: Document creation failed: $e3');
          _lastError = e3.toString();
          
          // Method 4: Check if it's a permissions issue
          if (e3.toString().contains('permission-denied') || e3.toString().contains('unauthenticated')) {
            print('🔒 Method 4: Detected permissions issue - Firebase is connected but rules are blocking');
            _isConnected = true;
            _lastError = 'Permissions issue - Firebase connected but access denied';
            return true;
          }
        }
      }
    }
    
    _isConnected = false;
    print('❌ FirebaseConnectivityService: All connectivity tests failed');
    return false;
  }

  /// Get detailed connectivity status
  Future<Map<String, dynamic>> getConnectivityStatus() async {
    final isConnected = await testConnectivity();
    
    return {
      'isConnected': isConnected,
      'isInitialized': _isInitialized,
      'lastError': _lastError,
      'timestamp': DateTime.now().toIso8601String(),
      'recommendations': _getRecommendations(),
    };
  }

  /// Get recommendations based on current status
  List<String> _getRecommendations() {
    final recommendations = <String>[];
    
    if (!_isConnected) {
      recommendations.add('Check internet connection');
      recommendations.add('Verify Firebase project configuration');
      recommendations.add('Check Google Play Services status');
      
      if (_lastError?.contains('UNAVAILABLE') == true) {
        recommendations.add('Firebase service unavailable - try again later');
      } else if (_lastError?.contains('timeout') == true) {
        recommendations.add('Network timeout - check connection speed');
      } else if (_lastError?.contains('providerinstaller') == true) {
        recommendations.add('Google Play Services issue detected - may need device restart');
      }
    }
    
    return recommendations;
  }

  /// Initialize the service
  Future<void> initialize() async {
    print('🚀 FirebaseConnectivityService: Initializing...');
    _isInitialized = true;
    await testConnectivity();
  }

  /// Check if Firebase is ready for operations
  bool get isReady => _isConnected && _isInitialized;
}





