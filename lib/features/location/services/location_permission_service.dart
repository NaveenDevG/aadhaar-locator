import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationPermissionService {
  /// Check and request location permissions with user guidance
  static Future<LocationPermission> checkAndRequestPermission(BuildContext context) async {
    try {
      print('📍 LocationPermissionService: Checking location services...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ LocationPermissionService: Location services disabled');
        // Show dialog to guide user to enable location services
        await _showLocationServicesDialog(context);
        return LocationPermission.deniedForever;
      }
      
      print('✅ LocationPermissionService: Location services enabled');

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 LocationPermissionService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 LocationPermissionService: Requesting permission...');
        // Request permission
        permission = await Geolocator.requestPermission();
        print('📍 LocationPermissionService: Permission result: $permission');
        
        if (permission == LocationPermission.denied) {
          print('❌ LocationPermissionService: Permission denied');
          // Show dialog explaining why permission is needed
          await _showPermissionDeniedDialog(context);
          return LocationPermission.denied;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ LocationPermissionService: Permission denied forever');
        // Show dialog to guide user to app settings
        await _showPermissionDeniedForeverDialog(context);
        return LocationPermission.deniedForever;
      }

      print('✅ LocationPermissionService: Permission granted: $permission');
      return permission;
    } catch (e) {
      print('❌ LocationPermissionService: Error checking permission: $e');
      // Show generic error dialog
      await _showErrorDialog(context, 'Permission Error', e.toString());
      return LocationPermission.denied;
    }
  }

  /// Get current location with permission handling
  static Future<Position?> getCurrentLocationWithPermission(BuildContext context) async {
    try {
      final permission = await checkAndRequestPermission(context);
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        return null;
      }

      // Try to get current position
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } catch (e) {
        // Fallback to last known position
        try {
          final lastKnownPosition = await Geolocator.getLastKnownPosition();
          if (lastKnownPosition != null) {
            return lastKnownPosition;
          }
        } catch (_) {
          // Ignore fallback errors
        }
        
        // Show error dialog
        await _showErrorDialog(
          context, 
          'Location Error', 
          'Unable to get your current location. Please try again.'
        );
        return null;
      }
    } catch (e) {
      await _showErrorDialog(context, 'Error', e.toString());
      return null;
    }
  }

  /// Show dialog for location services disabled
  static Future<void> _showLocationServicesDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are currently disabled on your device. '
            'To share your location, please enable location services in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog for permission denied
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required to share your location with other users. '
            'Please grant location permission when prompted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog for permission permanently denied
  static Future<void> _showPermissionDeniedForeverDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission has been permanently denied. '
            'To share your location, please enable location permissions in your device settings:\n\n'
            '1. Go to Settings > Apps > Aadhaar Locator\n'
            '2. Tap Permissions\n'
            '3. Enable Location permission',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show generic error dialog
  static Future<void> _showErrorDialog(BuildContext context, String title, String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Check if location permission is granted
  static Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      return false;
    }
  }

  /// Check and request permission specifically for location sharing
  static Future<bool> requestLocationSharingPermission(BuildContext context) async {
    try {
      print('📍 LocationPermissionService: Requesting location sharing permission...');
      
      final permission = await checkAndRequestPermission(context);
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        print('✅ LocationPermissionService: Location sharing permission granted');
        return true;
      } else {
        print('❌ LocationPermissionService: Location sharing permission denied');
        return false;
      }
    } catch (e) {
      print('❌ LocationPermissionService: Error requesting location sharing permission: $e');
      return false;
    }
  }

  /// Get current location specifically for location sharing
  static Future<Position?> getLocationForSharing(BuildContext context) async {
    try {
      print('📍 LocationPermissionService: Getting location for sharing...');
      
      // First check permission
      if (!await requestLocationSharingPermission(context)) {
        print('❌ LocationPermissionService: No permission for location sharing');
        return null;
      }
      
      print('📍 LocationPermissionService: Permission granted, getting current location...');
      
      // Try to get current position with high accuracy
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
        print('✅ LocationPermissionService: Current location obtained: ${position.latitude}, ${position.longitude}');
        return position;
      } catch (e) {
        print('⚠️ LocationPermissionService: Failed to get current position: $e');
        
        // Fallback to last known position
        try {
          final lastKnownPosition = await Geolocator.getLastKnownPosition();
          if (lastKnownPosition != null) {
            print('📍 LocationPermissionService: Using last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}');
            return lastKnownPosition;
          }
        } catch (fallbackError) {
          print('❌ LocationPermissionService: Fallback to last known position failed: $fallbackError');
        }
        
        // Show error dialog
        await _showErrorDialog(
          context, 
          'Location Error', 
          'Unable to get your current location. Please check your GPS settings and try again.'
        );
        return null;
      }
    } catch (e) {
      print('❌ LocationPermissionService: Error in getLocationForSharing: $e');
      await _showErrorDialog(context, 'Error', 'Failed to get location: $e');
      return null;
    }
  }
}
