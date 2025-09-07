import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionService {
  static const List<Permission> _requiredPermissions = [
    Permission.location,
    Permission.notification,
  ];

  /// Request all required permissions for the app
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions(BuildContext context) async {
    print('🔐 PermissionService: Requesting all permissions...');
    
    Map<Permission, PermissionStatus> statuses = {};
    
    // Show permission explanation dialog first
    await _showPermissionExplanationDialog(context);
    
    // Request each permission
    for (Permission permission in _requiredPermissions) {
      try {
        print('🔐 Requesting ${permission.toString()}...');
        final status = await permission.request();
        statuses[permission] = status;
        print('🔐 ${permission.toString()}: $status');
      } catch (e) {
        print('❌ Error requesting ${permission.toString()}: $e');
        statuses[permission] = PermissionStatus.denied;
      }
    }
    
    // Check if all critical permissions are granted
    final criticalPermissions = [Permission.location, Permission.notification];
    final allCriticalGranted = criticalPermissions.every(
      (permission) => statuses[permission] == PermissionStatus.granted
    );
    
    if (!allCriticalGranted) {
      await _showPermissionDeniedDialog(context, statuses);
    }
    
    return statuses;
  }

  /// Check if all required permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    for (Permission permission in _requiredPermissions) {
      final status = await permission.status;
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  /// Check specific permission status
  static Future<PermissionStatus> checkPermission(Permission permission) async {
    return await permission.status;
  }

  /// Request specific permission
  static Future<PermissionStatus> requestPermission(Permission permission) async {
    return await permission.request();
  }

  /// Open app settings for permission management
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Show explanation dialog for why permissions are needed
  static Future<void> _showPermissionExplanationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.security, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text('App Permissions Required'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Rakshak needs the following permissions to function properly:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                _buildPermissionItem(
                  Icons.location_on,
                  'Location',
                  'Share your location with trusted contacts and receive location updates',
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                _buildPermissionItem(
                  Icons.notifications,
                  'Notifications',
                  'Receive real-time alerts when someone shares their location with you',
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can change these permissions later in your device settings.',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Grant Permissions'),
            ),
          ],
        );
      },
    );
  }

  /// Build permission item widget
  static Widget _buildPermissionItem(IconData icon, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Show dialog when permissions are denied
  static Future<void> _showPermissionDeniedDialog(BuildContext context, Map<Permission, PermissionStatus> statuses) async {
    final deniedPermissions = statuses.entries
        .where((entry) => entry.value == PermissionStatus.denied || entry.value == PermissionStatus.permanentlyDenied)
        .map((entry) => entry.key)
        .toList();

    if (deniedPermissions.isEmpty) return;

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade600),
              const SizedBox(width: 8),
              const Text('Some Permissions Denied'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The following permissions were denied:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...deniedPermissions.map((permission) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Text(_getPermissionName(permission)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              const Text(
                'Some features may not work properly without these permissions. You can grant them later in your device settings.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Get user-friendly permission name
  static String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Location Access';
      case Permission.notification:
        return 'Notifications';
      default:
        return permission.toString();
    }
  }

  /// Request location permission specifically
  static Future<LocationPermission> requestLocationPermission(BuildContext context) async {
    try {
      print('📍 PermissionService: Requesting location permission...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('⚠️ PermissionService: Location services disabled');
        await _showLocationServicesDialog(context);
        return LocationPermission.deniedForever;
      }
      
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 PermissionService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        print('📍 PermissionService: Requesting permission...');
        permission = await Geolocator.requestPermission();
        print('📍 PermissionService: Permission result: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ PermissionService: Permission denied forever');
        await _showLocationPermissionDeniedForeverDialog(context);
      }

      return permission;
    } catch (e) {
      print('❌ PermissionService: Error requesting location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Show dialog for location services disabled
  static Future<void> _showLocationServicesDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are disabled. Please enable location services in your device settings to use location features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog for location permission permanently denied
  static Future<void> _showLocationPermissionDeniedForeverDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission has been permanently denied. To share your location, please enable location permissions in your device settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      print('🔔 PermissionService: Requesting notification permission...');
      
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      
      // Request permission for notifications
      final result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      print('🔔 PermissionService: Notification permission result: $result');
      return result ?? false;
    } catch (e) {
      print('❌ PermissionService: Error requesting notification permission: $e');
      return false;
    }
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

  /// Check if notification permission is granted
  static Future<bool> hasNotificationPermission() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }
}
