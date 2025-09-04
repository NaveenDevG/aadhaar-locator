import 'package:cloud_firestore/cloud_firestore.dart';

class LocationShare {
  final String id;
  final String senderUid;
  final String senderName;
  final double latitude;
  final double longitude;
  final String? address;
  final String message;
  final DateTime timestamp;
  final bool isActive;

  const LocationShare({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.message,
    required this.timestamp,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderUid': senderUid,
      'senderName': senderName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isActive': isActive,
    };
  }

  factory LocationShare.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return LocationShare(
      id: doc.id,
      senderUid: data['senderUid'] as String,
      senderName: data['senderName'] as String,
      latitude: data['latitude'] as double,
      longitude: data['longitude'] as double,
      address: data['address'] as String?,
      message: data['message'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  LocationShare copyWith({
    String? id,
    String? senderUid,
    String? senderName,
    double? latitude,
    double? longitude,
    String? address,
    String? message,
    DateTime? timestamp,
    bool? isActive,
  }) {
    return LocationShare(
      id: id ?? this.id,
      senderUid: senderUid ?? this.senderUid,
      senderName: senderName ?? this.senderName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }
}


