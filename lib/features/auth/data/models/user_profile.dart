import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String aadhaarName;
  final String aadhaarNumber;
  final DateTime aadhaarDob;
  final bool firstLoginRequired;
  final bool isLoggedIn;
  final GeoPoint? lastKnownLocation;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.aadhaarName,
    required this.aadhaarNumber,
    required this.aadhaarDob,
    this.email,
    this.phone,
    this.firstLoginRequired = true,
    this.isLoggedIn = false,
    this.lastKnownLocation,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'aadhaarName': aadhaarName,
      'aadhaarNumber': aadhaarNumber,
      'aadhaarDob': Timestamp.fromDate(aadhaarDob),
      'firstLoginRequired': firstLoginRequired,
      'isLoggedIn': isLoggedIn,
      'lastKnownLocation': lastKnownLocation,
      'fcmToken': fcmToken,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] as String,
      name: data['name'] as String,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      aadhaarName: data['aadhaarName'] as String,
      aadhaarNumber: data['aadhaarNumber'] as String,
      aadhaarDob: (data['aadhaarDob'] as Timestamp).toDate(),
      firstLoginRequired: data['firstLoginRequired'] as bool? ?? false,
      isLoggedIn: data['isLoggedIn'] as bool? ?? false,
      lastKnownLocation: data['lastKnownLocation'] as GeoPoint?,
      fcmToken: data['fcmToken'] as String?,
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null,
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? aadhaarName,
    String? aadhaarNumber,
    DateTime? aadhaarDob,
    bool? firstLoginRequired,
    bool? isLoggedIn,
    GeoPoint? lastKnownLocation,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      aadhaarName: aadhaarName ?? this.aadhaarName,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarDob: aadhaarDob ?? this.aadhaarDob,
      firstLoginRequired: firstLoginRequired ?? this.firstLoginRequired,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
