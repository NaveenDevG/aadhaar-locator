import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/location_share.dart';
import '../models/user_location.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/services/push_notification_service.dart';
import '../../notifications/services/fcm_service.dart';
import '../../notifications/services/backend_fcm_service.dart';


class LocationSharingService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LocationSharingService(this._firestore, this._auth);

  /// Share current location with other logged-in users
  Future<void> shareLocation({
    required String message,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      String userName = 'Unknown User';
      
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userName = userData['name'] as String? ?? 'Unknown User';
      } else {
        print('⚠️ LocationSharingService: User profile not found, using default name');
        // Use email as fallback
        userName = user.email?.split('@')[0] ?? 'User';
      }

      // Create location share
      final locationShare = LocationShare(
        id: '', // Will be set by Firestore
        senderUid: user.uid,
        senderName: userName,
        latitude: latitude,
        longitude: longitude,
        address: address,
        message: message,
        timestamp: DateTime.now(),
        isActive: true,
      );

      // Save to Firestore with timeout
      await _firestore.collection('locationShares').add(locationShare.toMap())
          .timeout(const Duration(seconds: 15));

      // Update user's last known location with timeout
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastKnownLocation': GeoPoint(latitude, longitude),
          'lastLocationShare': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 15));
        print('✅ LocationSharingService: User location updated successfully');
      } catch (e) {
        print('⚠️ LocationSharingService: Failed to update user location (continuing): $e');
        // Continue even if location update fails
      }

      // Send FCM notification to other logged-in users
      await _notifyOtherUsers(locationShare);
    } catch (e) {
      throw Exception('Failed to share location: $e');
    }
  }

  /// Get all active location shares from other users
  Stream<List<LocationShare>> getActiveLocationShares() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('locationShares')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['isActive'] == true && doc.data()['senderUid'] != user.uid)
            .map((doc) => LocationShare.fromDoc(doc))
            .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  /// Get location shares sent by current user
  Stream<List<LocationShare>> getMyLocationShares() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('locationShares')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((doc) => doc.data()['senderUid'] == user.uid)
            .map((doc) => LocationShare.fromDoc(doc))
            .toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  /// Get all logged-in users except current user
  Future<List<UserLocation>> getLoggedInUsers() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      print('🔍 LocationSharingService: Querying for logged-in users...');
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('isLoggedIn', isEqualTo: true)
          .get();

      print('🔍 LocationSharingService: Found ${querySnapshot.docs.length} total users with isLoggedIn=true');
      
      final filteredUsers = querySnapshot.docs
          .where((doc) => doc.id != user.uid)
          .map((doc) => UserLocation.fromDoc(doc))
          .toList();
      
      print('🔍 LocationSharingService: After filtering current user, ${filteredUsers.length} users remain');
      
      // Debug: Print details of each user found
      for (int i = 0; i < filteredUsers.length; i++) {
        final user = filteredUsers[i];
        print('🔍 LocationSharingService: Found user ${i + 1}: ${user.name} (${user.uid}) - FCM Token: ${user.fcmToken != null ? 'Present' : 'Missing'}');
      }
      
      return filteredUsers;
    } catch (e) {
      print('❌ LocationSharingService: Failed to get logged-in users: $e');
      throw Exception('Failed to get logged-in users: $e');
    }
  }

  /// Deactivate a location share
  Future<void> deactivateLocationShare(String shareId) async {
    try {
      await _firestore
          .collection('locationShares')
          .doc(shareId)
          .update({'isActive': false});
    } catch (e) {
      throw Exception('Failed to deactivate location share: $e');
    }
  }

  /// Get current user's location
  Future<Position> getCurrentLocation() async {
    try {
      print('📍 LocationSharingService: Getting current location...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ LocationSharingService: Location services disabled');
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }
      print('✅ LocationSharingService: Location services enabled');

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 LocationSharingService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 LocationSharingService: Requesting permission...');
        permission = await Geolocator.requestPermission();
        print('📍 LocationSharingService: Permission result: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ LocationSharingService: Permission denied');
          throw Exception('Location permission denied. Please grant location permission to share your location.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ LocationSharingService: Permission denied forever');
        throw Exception('Location permissions permanently denied. Please enable location permissions in your device settings.');
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        print('✅ LocationSharingService: Permission granted, getting current position...');
        
        // Get current position with timeout and fallback
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 20),
          );
          print('✅ LocationSharingService: Current position obtained: ${position.latitude}, ${position.longitude}');
          return position;
        } catch (e) {
          print('⚠️ LocationSharingService: Failed to get current position: $e');
          
          // Fallback to last known position if current position fails
          try {
            final lastKnownPosition = await Geolocator.getLastKnownPosition();
            if (lastKnownPosition != null) {
              print('📍 LocationSharingService: Using last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
              return lastKnownPosition;
            }
          } catch (_) {
            print('❌ LocationSharingService: Fallback to last known position failed');
          }
          
          // If both fail, throw the original error
          if (e.toString().contains('timeout')) {
            throw Exception('Location request timed out. Please try again.');
          } else if (e.toString().contains('location unavailable')) {
            throw Exception('Location is currently unavailable. Please try again in a moment.');
          } else {
            throw Exception('Failed to get current location: $e');
          }
        }
      } else {
        print('❌ LocationSharingService: Permission not granted');
        throw Exception('Location permission not granted. Please grant location permission to share your location.');
      }
    } catch (e) {
      print('❌ LocationSharingService: Error getting current location: $e');
      
      // Provide more specific error messages
      if (e.toString().contains('Location services are disabled')) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      } else if (e.toString().contains('permission denied')) {
        throw Exception('Location permission denied. Please grant location permission in your device settings.');
      } else if (e.toString().contains('permanently denied')) {
        throw Exception('Location permissions permanently denied. Please enable location permissions in your device settings.');
      } else if (e.toString().contains('timeout')) {
        throw Exception('Location request timed out. Please try again.');
      } else if (e.toString().contains('location unavailable')) {
        throw Exception('Location is currently unavailable. Please try again in a moment.');
      } else {
        throw Exception('Failed to get current location: $e');
      }
    }
  }

  /// Send FCM notification to other users
  Future<void> _notifyOtherUsers(LocationShare locationShare) async {
    try {
      print('🔔 LocationSharingService: Starting notification process...');
      
      // Get all logged-in users except current user
      final otherUsers = await getLoggedInUsers();
      
      if (otherUsers.isEmpty) {
        print('ℹ️ LocationSharingService: No other users online to notify');
        return;
      }
      
      print('🔔 LocationSharingService: Found ${otherUsers.length} other logged-in users');
      
      // Debug: Print details of each user
      for (int i = 0; i < otherUsers.length; i++) {
        final user = otherUsers[i];
        print('🔍 LocationSharingService: User ${i + 1}: ${user.name} (${user.uid}) - FCM Token: ${user.fcmToken != null ? 'Present' : 'Missing'}');
      }
      
      // OPTION 1: Send to ALL users at once using Direct FCM (RECOMMENDED)
      final usersWithTokens = otherUsers.where((user) => user.fcmToken != null).toList();
      if (usersWithTokens.isNotEmpty) {
        print('📤 LocationSharingService: Sending location share to ALL ${usersWithTokens.length} users at once...');
        
        final fcmTokens = usersWithTokens.map((user) => user.fcmToken!).toList();
        final result = await BackendFCMService.sendLocationShareToAllUsers(
          fcmTokens: fcmTokens,
          senderName: locationShare.senderName,
          latitude: locationShare.latitude,
          longitude: locationShare.longitude,
          senderUid: locationShare.senderUid,
        );
        
        if (result['success'] == true) {
          final successCount = result['successCount'] ?? 0;
          print('✅ LocationSharingService: Location shared with ALL users successfully! $successCount/${usersWithTokens.length} received');
          
          // Show local confirmation notification
          await NotificationService.showNotification(
            title: '📍 Location Shared with Everyone',
            body: 'Location shared with $successCount online users',
            payload: {
              'type': 'location_shared_all',
              'recipients': successCount,
            },
          );
        } else {
          print('❌ LocationSharingService: Failed to share with all users: ${result['error']}');
          // Fallback to individual notifications
          await _sendIndividualNotifications(otherUsers, locationShare);
        }
      } else {
        print('⚠️ LocationSharingService: No users have FCM tokens, cannot send notifications');
        await _sendIndividualNotifications(otherUsers, locationShare);
      }
      
    } catch (e) {
      print('❌ LocationSharingService: Error in notification process: $e');
    }
  }

  /// Fallback method: Send individual notifications
  Future<void> _sendIndividualNotifications(List<UserLocation> users, LocationShare locationShare) async {
    print('📤 LocationSharingService: Using fallback - sending individual notifications...');
    
    int successCount = 0;
    for (final user in users) {
      try {
        print('📤 LocationSharingService: Attempting to send notification to ${user.name} (${user.uid})');
        
        if (user.fcmToken == null) {
          print('⚠️ LocationSharingService: User ${user.name} has no FCM token, skipping');
          continue;
        }
        
        final success = await PushNotificationService.sendLocationShareNotification(
          recipientUid: user.uid,
          senderName: locationShare.senderName,
          latitude: locationShare.latitude,
          longitude: locationShare.longitude,
          senderUid: locationShare.senderUid,
        );
        
        if (success) {
          successCount++;
          print('✅ LocationSharingService: Push notification sent to ${user.name}');
        } else {
          print('⚠️ LocationSharingService: Failed to send push notification to ${user.name}');
        }
      } catch (e) {
        print('❌ LocationSharingService: Error sending push notification to ${user.name}: $e');
      }
    }
    
    print('✅ LocationSharingService: Individual notifications completed - $successCount/${users.length} sent successfully');
    
    // Show local confirmation notification
    await NotificationService.showNotification(
      title: '📍 Location Shared',
      body: 'Location shared with $successCount users',
      payload: {
        'type': 'location_shared',
        'recipients': successCount,
      },
    );
  }

  /// Test notification functionality
  Future<void> testNotification() async {
    try {
      print('🧪 LocationSharingService: Testing notification functionality...');
      
      await NotificationService.showNotification(
        title: '🧪 Test Notification',
        body: 'This is a test notification from LocationSharingService',
        payload: {
          'type': 'test',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      print('✅ LocationSharingService: Test notification shown successfully');
    } catch (e) {
      print('❌ LocationSharingService: Test notification failed: $e');
    }
  }

  /// Test sending notification to ALL online users at once
  Future<void> testNotificationToAllUsers() async {
    try {
      print('🧪 LocationSharingService: Testing notification to ALL online users...');
      
      // Get all logged-in users
      final allUsers = await getLoggedInUsers();
      
      if (allUsers.isEmpty) {
        print('ℹ️ LocationSharingService: No online users to test with');
        return;
      }
      
      print('🧪 LocationSharingService: Found ${allUsers.length} online users for testing');
      
      // Get users with FCM tokens
      final usersWithTokens = allUsers.where((user) => user.fcmToken != null).toList();
      
      if (usersWithTokens.isEmpty) {
        print('⚠️ LocationSharingService: No users have FCM tokens for testing');
        return;
      }
      
      print('🧪 LocationSharingService: Testing with ${usersWithTokens.length} users who have FCM tokens');
      
      // Send test notification to all users
      final fcmTokens = usersWithTokens.map((user) => user.fcmToken!).toList();
      final result = await BackendFCMService.sendNotificationToMultipleUsers(
        fcmTokens: fcmTokens,
        title: '🧪 Test Notification to All Users',
        body: 'This is a test notification sent to all online users',
        data: {
          'type': 'test_all_users',
          'timestamp': DateTime.now().toIso8601String(),
          'message': 'Testing direct FCM to all users',
        },
      );
      
      if (result['success'] == true) {
        final successCount = result['successCount'] ?? 0;
        final failureCount = result['failureCount'] ?? 0;
        
        print('✅ LocationSharingService: Test notification sent to $successCount users, failed for $failureCount users');
        
        // Show local confirmation
        await NotificationService.showNotification(
          title: '🧪 Test Complete',
          body: 'Test notification sent to $successCount online users',
          payload: {
            'type': 'test_all_complete',
            'successCount': successCount,
            'failureCount': failureCount,
          },
        );
      } else {
        print('❌ LocationSharingService: Test notification failed: ${result['error']}');
        
        await NotificationService.showNotification(
          title: '🧪 Test Failed',
          body: 'Failed to send test notification: ${result['error']}',
          payload: {
            'type': 'test_all_failed',
            'error': result['error'],
          },
        );
      }
      
    } catch (e) {
      print('❌ LocationSharingService: Test notification to all users failed: $e');
    }
  }

  /// Debug method to check current state
  Future<void> debugCurrentState() async {
    try {
      print('🔍 LocationSharingService: === DEBUGGING CURRENT STATE ===');
      
      final currentUser = _auth.currentUser;
      print('🔍 LocationSharingService: Current user: ${currentUser?.uid ?? 'None'}');
      
      // Check logged-in users
      final loggedInUsers = await getLoggedInUsers();
      print('🔍 LocationSharingService: Logged-in users count: ${loggedInUsers.length}');
      
      // Check FCM tokens collection
      try {
        final fcmTokensSnapshot = await _firestore.collection('fcmTokens').get();
        print('🔍 LocationSharingService: FCM tokens collection count: ${fcmTokensSnapshot.docs.length}');
        
        for (final doc in fcmTokensSnapshot.docs) {
          final data = doc.data();
          print('🔍 LocationSharingService: FCM Token for ${doc.id}: ${data['token'] != null ? 'Present' : 'Missing'}');
        }
      } catch (e) {
        print('❌ LocationSharingService: Error checking FCM tokens collection: $e');
      }
      
      // Check users collection
      try {
        final usersSnapshot = await _firestore.collection('users').get();
        print('🔍 LocationSharingService: Users collection count: ${usersSnapshot.docs.length}');
        
        for (final doc in usersSnapshot.docs) {
          final data = doc.data();
          final isLoggedIn = data['isLoggedIn'] ?? false;
          final hasFcmToken = data['fcmToken'] != null;
          print('🔍 LocationSharingService: User ${doc.id}: isLoggedIn=$isLoggedIn, hasFcmToken=$hasFcmToken');
        }
      } catch (e) {
        print('❌ LocationSharingService: Error checking users collection: $e');
      }
      
      // Check FCM service status
      try {
        print('🔍 LocationSharingService: FCM Service available: ${FCMService.isAvailable}');
        print('🔍 LocationSharingService: FCM Current token: ${FCMService.currentToken != null ? 'Present' : 'Missing'}');
      } catch (e) {
        print('❌ LocationSharingService: Error checking FCM service: $e');
      }
      
      print('🔍 LocationSharingService: === END DEBUGGING ===');
    } catch (e) {
      print('❌ LocationSharingService: Debug failed: $e');
    }
  }

  /// Force refresh FCM token for current user
  Future<void> refreshFcmToken() async {
    try {
      print('🔄 LocationSharingService: Refreshing FCM token...');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ LocationSharingService: No user logged in');
        return;
      }
      
      await FCMService.updateTokenForUser(currentUser.uid);
      print('✅ LocationSharingService: FCM token refreshed successfully');
      
      // Also update the user document
      await _firestore.collection('users').doc(currentUser.uid).update({
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('✅ LocationSharingService: User document updated');
    } catch (e) {
      print('❌ LocationSharingService: Failed to refresh FCM token: $e');
    }
  }

  /// Check notification permissions and FCM status
  Future<Map<String, dynamic>> checkNotificationStatus() async {
    try {
      print('🔍 LocationSharingService: Checking notification status...');
      
      final status = <String, dynamic>{};
      
      // Check FCM service
      status['fcmAvailable'] = FCMService.isAvailable;
      status['fcmToken'] = FCMService.currentToken != null;
      
      // Check current user
      final currentUser = _auth.currentUser;
      status['userLoggedIn'] = currentUser != null;
      status['userId'] = currentUser?.uid;
      
      if (currentUser != null) {
        // Check user document
        try {
          final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            status['userHasFcmToken'] = userData['fcmToken'] != null;
            status['userIsLoggedIn'] = userData['isLoggedIn'] ?? false;
            status['userName'] = userData['name'] ?? 'Unknown';
          } else {
            status['userDocumentExists'] = false;
          }
        } catch (e) {
          status['userDocumentError'] = e.toString();
        }
        
        // Check FCM tokens collection
        try {
          final fcmDoc = await _firestore.collection('fcmTokens').doc(currentUser.uid).get();
          status['fcmTokenDocumentExists'] = fcmDoc.exists;
        } catch (e) {
          status['fcmTokenDocumentError'] = e.toString();
        }
      }
      
      print('🔍 LocationSharingService: Notification status: $status');
      return status;
    } catch (e) {
      print('❌ LocationSharingService: Failed to check notification status: $e');
      return {'error': e.toString()};
    }
  }
}
