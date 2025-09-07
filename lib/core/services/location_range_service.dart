import 'dart:math';

class LocationRangeService {
  static const double _earthRadiusKm = 6371.0; // Earth's radius in kilometers
  static const double _defaultRangeKm = 10.0; // Default 10km range

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1, double lon1, // First point
    double lat2, double lon2, // Second point
  ) {
    // Convert degrees to radians
    double lat1Rad = lat1 * pi / 180;
    double lon1Rad = lon1 * pi / 180;
    double lat2Rad = lat2 * pi / 180;
    double lon2Rad = lon2 * pi / 180;

    // Haversine formula
    double dLat = lat2Rad - lat1Rad;
    double dLon = lon2Rad - lon1Rad;
    
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(dLon / 2) * sin(dLon / 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return _earthRadiusKm * c;
  }

  /// Check if two coordinates are within specified range
  /// Returns true if distance is within rangeKm
  static bool isWithinRange(
    double lat1, double lon1,
    double lat2, double lon2,
    double rangeKm,
  ) {
    double distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= rangeKm;
  }

  /// Check if coordinates are within 10km range
  static bool isWithin10KmRange(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return isWithinRange(lat1, lon1, lat2, lon2, _defaultRangeKm);
  }

  /// Get all users within 10km range from a given location
  static List<Map<String, dynamic>> filterUsersWithinRange(
    double centerLat, double centerLon,
    List<Map<String, dynamic>> allUsers,
    {double rangeKm = _defaultRangeKm}
  ) {
    List<Map<String, dynamic>> nearbyUsers = [];
    
    for (var user in allUsers) {
      try {
        // Extract coordinates from user data
        double? userLat = _extractLatitude(user);
        double? userLon = _extractLongitude(user);
        
        if (userLat != null && userLon != null) {
          // Check if user is within range
          if (isWithinRange(centerLat, centerLon, userLat, userLon, rangeKm)) {
            // Add distance to user data for reference
            double distance = calculateDistance(centerLat, centerLon, userLat, userLon);
            user['distance_km'] = distance;
            nearbyUsers.add(user);
          }
        }
      } catch (e) {
        print('⚠️ LocationRangeService: Error processing user location: $e');
        continue;
      }
    }
    
    // Sort by distance (closest first)
    nearbyUsers.sort((a, b) {
      double distA = a['distance_km'] ?? double.infinity;
      double distB = b['distance_km'] ?? double.infinity;
      return distA.compareTo(distB);
    });
    
    return nearbyUsers;
  }

  /// Extract latitude from user data
  static double? _extractLatitude(Map<String, dynamic> user) {
    // Try different possible field names for latitude
    if (user['latitude'] != null) return user['latitude'].toDouble();
    if (user['lat'] != null) return user['lat'].toDouble();
    if (user['location'] != null && user['location']['latitude'] != null) {
      return user['location']['latitude'].toDouble();
    }
    if (user['lastLocation'] != null && user['lastLocation']['latitude'] != null) {
      return user['lastLocation']['latitude'].toDouble();
    }
    return null;
  }

  /// Extract longitude from user data
  static double? _extractLongitude(Map<String, dynamic> user) {
    // Try different possible field names for longitude
    if (user['longitude'] != null) return user['longitude'].toDouble();
    if (user['lng'] != null) return user['lng'].toDouble();
    if (user['lon'] != null) return user['lon'].toDouble();
    if (user['location'] != null && user['location']['longitude'] != null) {
      return user['location']['longitude'].toDouble();
    }
    if (user['lastLocation'] != null && user['lastLocation']['longitude'] != null) {
      return user['lastLocation']['longitude'].toDouble();
    }
    return null;
  }

  /// Get bounding box coordinates for efficient database queries
  /// This helps optimize Firestore queries by filtering at database level
  static Map<String, double> getBoundingBox(
    double centerLat, double centerLon, double rangeKm
  ) {
    // Calculate the approximate bounding box
    double latDelta = rangeKm / 111.0; // Rough conversion: 1 degree ≈ 111 km
    double lonDelta = rangeKm / (111.0 * cos(centerLat * pi / 180));
    
    return {
      'minLat': centerLat - latDelta,
      'maxLat': centerLat + latDelta,
      'minLon': centerLon - lonDelta,
      'maxLon': centerLon + lonDelta,
    };
  }

  /// Format distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()}m';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km';
    }
  }

  /// Get range description
  static String getRangeDescription(double rangeKm) {
    if (rangeKm < 1.0) {
      return '${(rangeKm * 1000).round()} meters';
    } else {
      return '${rangeKm.toStringAsFixed(1)} kilometers';
    }
  }

  /// Validate coordinates
  static bool isValidCoordinate(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  /// Get default range in kilometers
  static double getDefaultRangeKm() => _defaultRangeKm;
}
