import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _db;

  UserRepository(this._db);

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _fcmTokens => _db.collection('fcmTokens');

  /// Create or update user profile
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      print('📝 UserRepository: Creating/updating user profile for ${profile.uid}');
      await _users.doc(profile.uid).set(
        profile.toMap(),
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 25));
      print('✅ UserRepository: User profile created/updated successfully');
    } catch (e) {
      print('❌ UserRepository: Failed to create/update user profile: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Firestore operation timed out. Please check your internet connection.');
      } else if (e.toString().contains('UNAVAILABLE')) {
        throw Exception('Firestore service unavailable. Please check your internet connection and try again.');
      }
      throw Exception('Failed to create user profile: $e');
    }
  }

  /// Get user profile by UID
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      print('📝 UserRepository: Fetching user profile for $uid');
      final doc = await _users.doc(uid).get().timeout(const Duration(seconds: 25));
      if (!doc.exists) {
        print('⚠️ UserRepository: User profile does not exist for $uid');
        return null;
      }
      print('✅ UserRepository: User profile fetched successfully');
      return UserProfile.fromDoc(doc);
    } catch (e) {
      print('❌ UserRepository: Failed to fetch user profile: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Firestore operation timed out. Please check your internet connection.');
      } else if (e.toString().contains('UNAVAILABLE')) {
        throw Exception('Firestore service unavailable. Please check your internet connection and try again.');
      }
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  /// Update first login required flag
  Future<void> setFirstLoginRequired(String uid, bool required) async {
    try {
      print('📝 UserRepository: Setting first login required for $uid to $required');
      await _users.doc(uid).update({
        'firstLoginRequired': required,
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 25));
      print('✅ UserRepository: First login required updated successfully');
    } catch (e) {
      print('❌ UserRepository: Failed to update first login required: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Firestore operation timed out. Please check your internet connection.');
      } else if (e.toString().contains('UNAVAILABLE')) {
        throw Exception('Firestore service unavailable. Please check your internet connection and try again.');
      }
      throw Exception('Failed to update first login required: $e');
    }
  }

  /// Update logged in status
  Future<void> setLoggedIn(String uid, bool value) async {
    try {
      print('📝 UserRepository: Setting login status for $uid to $value');
      await _users.doc(uid).update({
        'isLoggedIn': value,
        'updatedAt': FieldValue.serverTimestamp(),
        if (value) 'lastLoginAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 25));
      print('✅ UserRepository: Login status updated successfully');
    } catch (e) {
      print('❌ UserRepository: Failed to update login status: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Firestore operation timed out. Please check your internet connection.');
      } else if (e.toString().contains('UNAVAILABLE')) {
        throw Exception('Firestore service unavailable. Please check your internet connection and try again.');
      }
      throw Exception('Failed to update login status: $e');
    }
  }

  /// Update FCM token
  Future<void> updateFcmToken(String uid, String token) async {
    // Update in user document
    await _users.doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update in fcmTokens collection for easier querying
    await _fcmTokens.doc(uid).set({
      'token': token,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': 'flutter',
    }, SetOptions(merge: true));
  }

  /// Update user's last known location
  Future<void> updateLastKnownLocation(String uid, GeoPoint location) async {
    await _users.doc(uid).update({
      'lastKnownLocation': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get all logged-in users except the specified user
  Future<List<UserProfile>> getLoggedInUsersExcept(String excludeUid) async {
    try {
      final querySnapshot = await _users
          .where('isLoggedIn', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .where((doc) => doc.id != excludeUid)
          .map((doc) => UserProfile.fromDoc(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch logged-in users: $e');
    }
  }

  /// Get all FCM tokens for logged-in users except the specified user
  Future<List<String>> getFcmTokensExcept(String excludeUid) async {
    try {
      final querySnapshot = await _fcmTokens
          .where('uid', isNotEqualTo: excludeUid)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data()['token'] as String)
          .where((token) => token.isNotEmpty)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch FCM tokens: $e');
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    await _users.doc(uid).delete();
    await _fcmTokens.doc(uid).delete();
  }
}
