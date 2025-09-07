import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/location_range_service.dart';
import 'fcm_service.dart';
import 'push_notification_service.dart';

class RangeNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send location share notification to users within 10km range
  static Future<Map<String, dynamic>> sendLocationShareNotification({
    required double latitude,
    required double longitude,
    required String senderName,
    String? message,
    double rangeKm = 10.0,
  }) async {
    try {
      print('📡 RangeNotificationService: Sending location share notification...');
      print('📍 Location: $latitude, $longitude');
      print('👤 Sender: $senderName');
      print('📏 Range: ${rangeKm}km');

      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get all users with their locations
      final allUsers = await _getAllUsersWithLocations();
      print('👥 Found ${allUsers.length} users with locations');

      // Filter users within range
      final nearbyUsers = LocationRangeService.filterUsersWithinRange(
        latitude, longitude, allUsers, rangeKm: rangeKm
      );
      
      print('🎯 Found ${nearbyUsers.length} users within ${rangeKm}km range');

      if (nearbyUsers.isEmpty) {
        return {
          'success': true,
          'message': 'No users found within ${rangeKm}km range',
          'notificationsSent': 0,
          'nearbyUsers': [],
        };
      }

      // Prepare notification data
      final notificationData = {
        'type': 'location_share',
        'senderId': currentUser.uid,
        'senderName': senderName,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'range': rangeKm,
        'message': message ?? 'Location shared nearby',
      };

      // Send notifications to nearby users
      int notificationsSent = 0;
      List<Map<String, dynamic>> notifiedUsers = [];

      for (var user in nearbyUsers) {
        try {
          // Skip current user
          if (user['uid'] == currentUser.uid) continue;

          // Get user's FCM token
          String? fcmToken = user['fcmToken'];
          final userName = user['displayName'] ?? user['name'] ?? user['email'] ?? 'Unknown';
          print('🔍 User $userName - FCM Token: ${fcmToken != null ? 'Present (${fcmToken.substring(0, 20)}...)' : 'Missing'}');
          
          if (fcmToken == null || fcmToken.isEmpty) {
            print('⚠️ No FCM token for user $userName - skipping notification');
            continue;
          }

          // Prepare notification data
          final notificationTitle = '📍 Location Shared Nearby';
          final notificationBody = '$senderName shared their location (${LocationRangeService.formatDistance(user['distance_km'])} away)';
          final notificationData = {
            'type': 'location_share',
            'senderId': currentUser.uid,
            'senderName': senderName,
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            'distance': user['distance_km'].toString(),
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          };

          // Send notification
          print('📤 Attempting to send notification to $userName...');
          final success = await PushNotificationService.sendToToken(
            fcmToken: fcmToken,
            title: notificationTitle,
            body: notificationBody,
            data: notificationData,
          );

          print('📤 Notification result for $userName: $success');

          if (success) {
            notificationsSent++;
            notifiedUsers.add({
              'uid': user['uid'],
              'displayName': userName,
              'distance': user['distance_km'],
            });
            print('✅ Notification sent to $userName (${LocationRangeService.formatDistance(user['distance_km'])})');
          } else {
            print('❌ Failed to send notification to $userName');
          }
        } catch (e) {
          print('❌ Error sending notification to user: $e');
          continue;
        }
      }

      // Save notification record to Firestore
      await _saveNotificationRecord(notificationData, notifiedUsers);

      print('✅ RangeNotificationService: Sent $notificationsSent notifications');

      return {
        'success': true,
        'message': 'Location share notification sent to $notificationsSent users',
        'notificationsSent': notificationsSent,
        'nearbyUsers': notifiedUsers,
        'range': rangeKm,
      };

    } catch (e) {
      print('❌ RangeNotificationService: Error sending location share notification: $e');
      return {
        'success': false,
        'message': 'Failed to send location share notification: $e',
        'notificationsSent': 0,
        'nearbyUsers': [],
      };
    }
  }

  /// Get all users with their current locations
  static Future<List<Map<String, dynamic>>> _getAllUsersWithLocations() async {
    try {
      print('🔍 RangeNotificationService: Querying for logged-in users...');
      
      // Query users collection for logged-in users (same as location sharing service)
      final usersQuery = await _firestore
          .collection('users')
          .where('isLoggedIn', isEqualTo: true)
          .get();

      print('🔍 RangeNotificationService: Found ${usersQuery.docs.length} total users with isLoggedIn=true');

      List<Map<String, dynamic>> users = [];
      
      for (var doc in usersQuery.docs) {
        try {
          final userData = doc.data();
          userData['uid'] = doc.id;
          
          // Check if user has valid location data in different possible structures
          bool hasLocation = false;
          double? latitude;
          double? longitude;
          
          // Try lastLocation structure first
          if (userData['lastLocation'] != null) {
            final location = userData['lastLocation'];
            if (location['latitude'] != null && location['longitude'] != null) {
              latitude = location['latitude'].toDouble();
              longitude = location['longitude'].toDouble();
              hasLocation = true;
            }
          }
          
          // Try lastKnownLocation structure (GeoPoint)
          if (!hasLocation && userData['lastKnownLocation'] != null) {
            final geoPoint = userData['lastKnownLocation'];
            // Check if it's a GeoPoint object
            if (geoPoint is GeoPoint) {
              latitude = geoPoint.latitude;
              longitude = geoPoint.longitude;
              hasLocation = true;
            } else {
              // Fallback for other structures
              try {
                if (geoPoint['latitude'] != null && geoPoint['longitude'] != null) {
                  latitude = geoPoint['latitude'].toDouble();
                  longitude = geoPoint['longitude'].toDouble();
                  hasLocation = true;
                }
              } catch (e) {
                print('⚠️ Error accessing GeoPoint data: $e');
              }
            }
          }
          
          // Try direct latitude/longitude fields
          if (!hasLocation && userData['latitude'] != null && userData['longitude'] != null) {
            latitude = userData['latitude'].toDouble();
            longitude = userData['longitude'].toDouble();
            hasLocation = true;
          }
          
          if (hasLocation && latitude != null && longitude != null) {
            // Flatten location data for easier processing
            userData['latitude'] = latitude;
            userData['longitude'] = longitude;
            users.add(userData);
            print('🔍 RangeNotificationService: User ${userData['displayName'] ?? userData['name'] ?? userData['email']} has location: $latitude, $longitude');
          } else {
            print('⚠️ RangeNotificationService: User ${userData['displayName'] ?? userData['name'] ?? userData['email']} has no valid location data');
          }
        } catch (e) {
          print('⚠️ Error processing user data: $e');
          continue;
        }
      }

      print('🔍 RangeNotificationService: Found ${users.length} users with valid location data');
      return users;
    } catch (e) {
      print('❌ Error fetching users with locations: $e');
      return [];
    }
  }

  /// Save notification record to Firestore
  static Future<void> _saveNotificationRecord(
    Map<String, dynamic> notificationData,
    List<Map<String, dynamic>> notifiedUsers,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        ...notificationData,
        'notifiedUsers': notifiedUsers.map((user) => {
          'uid': user['uid'],
          'displayName': user['displayName'],
          'distance': user['distance'],
        }).toList(),
        'totalNotified': notifiedUsers.length,
      });
      print('✅ Notification record saved to Firestore');
    } catch (e) {
      print('❌ Error saving notification record: $e');
    }
  }

  /// Get notification history for current user
  static Future<List<Map<String, dynamic>>> getNotificationHistory() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final notificationsQuery = await _firestore
          .collection('notifications')
          .where('senderId', isEqualTo: currentUser.uid)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return notificationsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching notification history: $e');
      return [];
    }
  }

  /// Get nearby users count for a location
  static Future<int> getNearbyUsersCount({
    required double latitude,
    required double longitude,
    double rangeKm = 10.0,
  }) async {
    try {
      final allUsers = await _getAllUsersWithLocations();
      final nearbyUsers = LocationRangeService.filterUsersWithinRange(
        latitude, longitude, allUsers, rangeKm: rangeKm
      );
      
      // Exclude current user from count
      final currentUser = _auth.currentUser;
      return nearbyUsers.where((user) => user['uid'] != currentUser?.uid).length;
    } catch (e) {
      print('❌ Error getting nearby users count: $e');
      return 0;
    }
  }

  /// Send emergency notification to all users within range
  static Future<Map<String, dynamic>> sendEmergencyNotification({
    required double latitude,
    required double longitude,
    required String emergencyType,
    String? message,
    double rangeKm = 10.0,
  }) async {
    try {
      print('🚨 RangeNotificationService: Sending emergency notification...');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get user's display name
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final senderName = userDoc.data()?['displayName'] ?? 'Unknown User';

      // Get nearby users
      final allUsers = await _getAllUsersWithLocations();
      final nearbyUsers = LocationRangeService.filterUsersWithinRange(
        latitude, longitude, allUsers, rangeKm: rangeKm
      );

      if (nearbyUsers.isEmpty) {
        return {
          'success': true,
          'message': 'No users found within ${rangeKm}km range',
          'notificationsSent': 0,
        };
      }

      // Send emergency notifications
      int notificationsSent = 0;
      for (var user in nearbyUsers) {
        if (user['uid'] == currentUser.uid) continue;

        String? fcmToken = user['fcmToken'];
        if (fcmToken == null || fcmToken.isEmpty) continue;

        final success = await PushNotificationService.sendToToken(
          fcmToken: fcmToken,
          title: '🚨 Emergency Alert Nearby',
          body: '$senderName needs help: ${message ?? emergencyType}',
          data: {
            'type': 'emergency',
            'senderId': currentUser.uid,
            'senderName': senderName,
            'latitude': latitude.toString(),
            'longitude': longitude.toString(),
            'emergencyType': emergencyType,
            'distance': user['distance_km'].toString(),
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        if (success) notificationsSent++;
      }

      return {
        'success': true,
        'message': 'Emergency notification sent to $notificationsSent users',
        'notificationsSent': notificationsSent,
      };

    } catch (e) {
      print('❌ Error sending emergency notification: $e');
      return {
        'success': false,
        'message': 'Failed to send emergency notification: $e',
        'notificationsSent': 0,
      };
    }
  }
}
