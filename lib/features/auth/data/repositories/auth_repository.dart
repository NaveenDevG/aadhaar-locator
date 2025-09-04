import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/config/app_config.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository(this._auth);

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Register with email and password
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e.code),
        code: e.code,
        details: e.message,
      );
    }
  }

  /// Login with email and password
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 AuthRepository: Attempting login for $email');
      
      // Check if we're in development mode and should bypass reCAPTCHA
      if (AppConfig.isDevelopment && AppConfig.enableRecaptcha == false) {
        print('🔐 AuthRepository: Development mode - attempting login without reCAPTCHA');
      }
      
      // Add retry logic for Google Play Services issues
      int retryCount = 0;
      const maxRetries = AppConfig.maxRetryAttempts;
      
      while (retryCount < maxRetries) {
        try {
          print('🔐 AuthRepository: Login attempt ${retryCount + 1} of $maxRetries');
          
          final result = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          print('✅ AuthRepository: Login successful for $email');
          return result;
        } on FirebaseAuthException catch (e) {
          print('❌ AuthRepository: Firebase auth error: ${e.code} - ${e.message}');
          
          // Handle specific reCAPTCHA errors
          if (e.code == 'recaptcha-check-failed' || e.code == 'network-request-failed') {
            throw AuthException(
              'Network or reCAPTCHA verification failed. Please check your internet connection and try again.',
              code: e.code,
              details: e.message,
            );
          }
          
          // Handle Google Play Services issues
          if (e.code == 'internal-error' || e.message?.contains('providerinstaller') == true) {
            retryCount++;
            if (retryCount < maxRetries) {
              print('⚠️ AuthRepository: Google Play Services issue detected, retrying in ${AppConfig.retryDelaySeconds} seconds...');
              await Future.delayed(Duration(seconds: AppConfig.retryDelaySeconds));
              continue;
            } else {
              throw AuthException(
                'Google Play Services issue detected. Please update Google Play Services or try again later.',
                code: e.code,
                details: e.message,
              );
            }
          }
          
          throw AuthException(
            _getAuthErrorMessage(e.code),
            code: e.code,
            details: e.message,
          );
        }
      }
      
      throw AuthException(
        'Maximum retry attempts reached. Please try again later.',
        code: 'max_retries',
        details: 'Failed after $maxRetries attempts',
      );
    } catch (e) {
      print('❌ AuthRepository: Unexpected error during login: $e');
      throw AuthException(
        'An unexpected error occurred during login. Please try again.',
        code: 'unknown',
        details: e.toString(),
      );
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e.code),
        code: e.code,
        details: e.message,
      );
    }
  }

  /// Stream of auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Get user ID token
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        _getAuthErrorMessage(e.code),
        code: e.code,
        details: e.message,
      );
    }
  }

  /// Create test user for development (bypasses reCAPTCHA)
  Future<UserCredential> createTestUser({
    required String email,
    required String password,
  }) async {
    try {
      // In development mode, we can try to create a user with a different approach
      if (email.contains('test') || email.contains('dev')) {
        // Try to create user with minimal verification
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // For non-test emails, use regular registration
        return await registerWithEmail(email: email, password: password);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // If user exists, try to sign in instead
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      rethrow;
    }
  }

  /// Check if current environment supports reCAPTCHA
  bool get supportsRecaptcha {
    // In emulator, reCAPTCHA often fails
    return !_isEmulator();
  }

  /// Check if running in emulator
  bool _isEmulator() {
    // Simple check for emulator
    return _auth.app.options.projectId.contains('demo') ||
           _auth.app.options.projectId.contains('test');
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
