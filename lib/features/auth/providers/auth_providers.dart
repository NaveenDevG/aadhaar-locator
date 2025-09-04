import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_profile.dart';
import '../../notifications/services/fcm_service.dart';

// Firebase instances
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) => 
  AuthRepository(ref.watch(firebaseAuthProvider))
);

final userRepositoryProvider = Provider<UserRepository>((ref) => 
  UserRepository(ref.watch(firestoreProvider))
);

// Auth state
class AuthState {
  final bool isAuthenticated;
  final bool firstLoginRequired;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.firstLoginRequired = false,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? firstLoginRequired,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      firstLoginRequired: firstLoginRequired ?? this.firstLoginRequired,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth controller
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  AuthController(this._authRepo, this._userRepo) 
    : super(const AuthState(isLoading: true)) {
    _init();
  }

  void _init() {
    _authRepo.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        state = const AuthState(isAuthenticated: false);
      }
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      print('🔐 Auth: Loading user profile for UID: $uid');
      state = state.copyWith(isLoading: true, error: null);
      
      final profile = await _userRepo.getUserProfile(uid)
          .timeout(const Duration(seconds: 15));
      
      if (profile != null) {
        print('✅ Auth: User profile loaded successfully');
        
        // Update FCM token if user is logged in
        if (profile.isLoggedIn) {
          print('🔔 Auth: Updating FCM token for logged-in user...');
          try {
            await FCMService.updateTokenForUser(uid);
            print('✅ Auth: FCM token updated successfully');
          } catch (e) {
            print('⚠️ Auth: Failed to update FCM token (continuing): $e');
            // Continue even if FCM token update fails
          }
        }
        
        state = AuthState(
          isAuthenticated: true,
          firstLoginRequired: profile.firstLoginRequired,
          profile: profile,
          isLoading: false,
        );
      } else {
        print('⚠️ Auth: User profile is null, creating default profile...');
        // Create a default profile for existing users
        try {
          final currentUser = _authRepo.currentUser;
          if (currentUser != null) {
            final defaultProfile = UserProfile(
              uid: uid,
              name: currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User',
              email: currentUser.email ?? '',
              aadhaarName: currentUser.displayName ?? 'Not Set',
              aadhaarNumber: 'Not Set',
              aadhaarDob: DateTime.now(),
              firstLoginRequired: false,
              isLoggedIn: true,
            );
            
            await _userRepo.createUserProfile(defaultProfile);
            print('✅ Auth: Default user profile created successfully');
            
            state = AuthState(
              isAuthenticated: true,
              firstLoginRequired: false,
              profile: defaultProfile,
              isLoading: false,
            );
          } else {
            print('❌ Auth: No current user found for profile creation');
            state = const AuthState(isAuthenticated: false, isLoading: false);
          }
        } catch (profileError) {
          print('❌ Auth: Failed to create default profile: $profileError');
          // Set a basic authenticated state even if profile creation fails
          state = AuthState(
            isAuthenticated: true,
            firstLoginRequired: false,
            profile: null,
            isLoading: false,
          );
        }
      }
    } catch (e) {
      print('❌ Auth: Failed to load user profile: $e');
      // Set a basic authenticated state even if profile loading fails
      state = AuthState(
        isAuthenticated: true,
        firstLoginRequired: false,
        profile: null,
        isLoading: false,
      );
    }
  }

  Future<void> restoreSession() async {
    try {
      print('🔐 Auth: Starting session restoration...');
      final user = _authRepo.currentUser;
      if (user == null) {
        print('🔐 Auth: No current user, setting unauthenticated state');
        state = const AuthState(isAuthenticated: false, isLoading: false);
        return;
      }
      
      print('🔐 Auth: Current user found, loading profile...');
      await _loadUserProfile(user.uid).timeout(const Duration(seconds: 15));
      print('✅ Auth: Session restoration completed');
    } catch (e) {
      print('❌ Auth: Session restoration failed: $e');
      // Set a basic authenticated state even if profile loading fails
      state = AuthState(
        isAuthenticated: true,
        firstLoginRequired: false,
        profile: null,
        isLoading: false,
      );
    }
  }

  Future<void> completeFirstLogin() async {
    final user = _authRepo.currentUser;
    if (user == null) return;

    try {
      print('🔐 Auth: Starting first login completion...');
      state = state.copyWith(isLoading: true, error: null);
      
                      // Set first login required to false
        print('🔐 Auth: Setting first login required to false...');
        try {
          await _userRepo.setFirstLoginRequired(user.uid, false)
              .timeout(const Duration(seconds: 25));
          print('✅ Auth: First login required set to false');
        } catch (e) {
          print('⚠️ Auth: Failed to set first login required (continuing): $e');
          // Continue even if this fails
        }
      
      // Set user as logged in
      print('🔐 Auth: Setting user as logged in...');
      try {
        await _userRepo.setLoggedIn(user.uid, true)
            .timeout(const Duration(seconds: 25));
        print('✅ Auth: User marked as logged in');
      } catch (e) {
        print('⚠️ Auth: Failed to set login status (continuing): $e');
        // Continue even if this fails
      }
      
      // Get updated profile
      print('🔐 Auth: Getting updated user profile...');
      final updated = await _userRepo.getUserProfile(user.uid)
          .timeout(const Duration(seconds: 25));
      
      if (updated != null) {
        print('✅ Auth: User profile retrieved successfully');
        state = AuthState(
          isAuthenticated: true,
          firstLoginRequired: false,
          profile: updated,
          isLoading: false,
        );
      } else {
        print('⚠️ Auth: User profile is null, creating basic state');
        state = AuthState(
          isAuthenticated: true,
          firstLoginRequired: false,
          profile: null,
          isLoading: false,
        );
      }
      
      print('✅ Auth: First login completion finished');
    } catch (e) {
      print('❌ Auth: First login completion failed: $e');
      // Set a basic authenticated state even if profile loading fails
      state = AuthState(
        isAuthenticated: true,
        firstLoginRequired: false,
        profile: null,
        isLoading: false,
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String aadhaarName,
    required String aadhaarNumber,
    required DateTime aadhaarDob,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final cred = await _authRepo.registerWithEmail(
        email: email,
        password: password,
      );
      
      final profile = UserProfile(
        uid: cred.user!.uid,
        name: name,
        email: email,
        aadhaarName: aadhaarName,
        aadhaarNumber: aadhaarNumber,
        aadhaarDob: aadhaarDob,
        firstLoginRequired: true,
        isLoggedIn: false,
      );
      
      await _userRepo.createUserProfile(profile);
      
      // Enforce first-time login: sign out immediately after registration
      await _authRepo.logout();
      
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Auth: Starting login process...');
      state = state.copyWith(isLoading: true, error: null);
      
      // Login with timeout
      print('🔐 Auth: Authenticating with Firebase...');
      await _authRepo.loginWithEmail(email: email, password: password)
          .timeout(const Duration(seconds: 20));
      print('✅ Auth: Firebase authentication successful');
      
      // Set user as logged in
      final user = _authRepo.currentUser;
      if (user != null) {
        print('🔐 Auth: Setting user as logged in...');
        try {
          await _userRepo.setLoggedIn(user.uid, true)
              .timeout(const Duration(seconds: 25));
          print('✅ Auth: User marked as logged in');
        } catch (e) {
          print('⚠️ Auth: Failed to set login status (continuing): $e');
          // Continue even if this fails
        }
        
        // Generate and save FCM token
        print('🔔 Auth: Generating FCM token for user...');
        try {
          await FCMService.updateTokenForUser(user.uid);
          print('✅ Auth: FCM token generated and saved successfully');
        } catch (e) {
          print('⚠️ Auth: Failed to generate FCM token (continuing): $e');
          // Continue even if FCM token generation fails
        }
      }
      
      print('🔐 Auth: Completing first login...');
      await completeFirstLogin();
      print('✅ Auth: Login process completed');
    } catch (e) {
      print('❌ Auth: Login failed: $e');
      
      // Provide more specific error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('timeout')) {
        errorMessage = 'Login request timed out. Please check your internet connection and try again.';
      } else if (errorMessage.contains('network') || errorMessage.contains('UNAVAILABLE')) {
        errorMessage = 'Network connection issue. Please check your internet connection and try again.';
      } else if (errorMessage.contains('recaptcha')) {
        errorMessage = 'reCAPTCHA verification failed. Please check your internet connection and try again.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final user = _authRepo.currentUser;
      if (user != null) {
        await _userRepo.setLoggedIn(user.uid, false);
        
        // Clean up FCM token on logout
        print('🔔 Auth: Cleaning up FCM token on logout...');
        try {
          await FCMService.deleteToken();
          print('✅ Auth: FCM token cleaned up successfully');
        } catch (e) {
          print('⚠️ Auth: Failed to clean up FCM token (continuing): $e');
          // Continue even if FCM cleanup fails
        }
      }
      
      await _authRepo.logout();
      state = const AuthState(isAuthenticated: false, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Auth controller provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});
