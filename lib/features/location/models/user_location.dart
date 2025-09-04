import 'package:cloud_firestore/cloud_firestore.dart';

class UserLocation {
  final String uid;
  final String name;
  final String? email;
  final GeoPoint? lastKnownLocation;
  final DateTime? lastLocationShare;
  final String? fcmToken;
  final bool isLoggedIn;
  final DateTime? updatedAt;

  const UserLocation({
    required this.uid,
    required this.name,
    this.email,
    this.lastKnownLocation,
    this.lastLocationShare,
    this.fcmToken,
    required this.isLoggedIn,
    this.updatedAt,
  });

  factory UserLocation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserLocation(
      uid: doc.id,
      name: data['name'] as String? ?? 'Unknown User',
      email: data['email'] as String?,
      lastKnownLocation: data['lastKnownLocation'] as GeoPoint?,
      lastLocationShare: data['lastLocationShare'] != null 
          ? (data['lastLocationShare'] as Timestamp).toDate() 
          : null,
      fcmToken: data['fcmToken'] as String?,
      isLoggedIn: data['isLoggedIn'] as bool? ?? false,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  double? get latitude => lastKnownLocation?.latitude;
  double? get longitude => lastKnownLocation?.longitude;

  bool get hasLocation => lastKnownLocation != null;

  String get locationStatus {
    if (!isLoggedIn) return 'Offline';
    if (hasLocation) return 'Online with location';
    return 'Online';
  }
}


