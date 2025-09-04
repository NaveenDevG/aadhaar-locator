import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routing/app_router.dart';
import '../providers/location_sharing_providers.dart';
import '../models/location_share.dart';
import '../models/user_location.dart';
import '../services/location_permission_service.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/services/notification_service.dart';
import '../../notifications/services/push_notification_service.dart';
import '../../notifications/services/backend_fcm_service.dart';


class LocationSharingScreen extends ConsumerStatefulWidget {
  final bool autoShare;
  
  const LocationSharingScreen({
    super.key,
    this.autoShare = false,
  });

  @override
  ConsumerState<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends ConsumerState<LocationSharingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Listen to tab changes to auto-send notifications
    _tabController.addListener(_onTabChanged);
    
    // Refresh logged-in users when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationSharingControllerProvider.notifier).refreshLoggedInUsers();
      
      // Initialize notification service if not already initialized
      _initializeNotificationService();
      
      // Auto-share location if requested from quick action
      if (widget.autoShare) {
        _performAutoShare();
      }
    });
  }

  Future<void> _initializeNotificationService() async {
    try {
      print('🔔 LocationSharingScreen: Initializing notification service...');
      await NotificationService.initialize();
      print('✅ LocationSharingScreen: Notification service initialized successfully');
    } catch (e) {
      print('❌ LocationSharingScreen: Failed to initialize notification service: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handle tab changes - auto-send notification when share tab is selected
  void _onTabChanged() {
    if (_tabController.index == 0) { // Share tab (index 0)
      print('📍 LocationSharingScreen: Share tab selected - auto-sending notification to all users');
      _autoSendNotificationToAllUsers();
    }
  }

  /// Perform automatic location sharing when coming from quick action
  Future<void> _performAutoShare() async {
    try {
      print('📍 LocationSharingScreen: Performing auto-share from quick action...');
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Sharing your location automatically...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Perform the same location sharing as the manual button
      await _shareLocation();
      
    } catch (e) {
      print('❌ LocationSharingScreen: Auto-share failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Auto-share failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Automatically send notification to all users when share tab is clicked
  Future<void> _autoSendNotificationToAllUsers() async {
    try {
      print('📢 LocationSharingScreen: Auto-sending notification to all users...');
      
      // Get all logged-in users
      final allUsers = await ref.read(locationSharingServiceProvider).getLoggedInUsers();
      
      if (allUsers.isEmpty) {
        print('ℹ️ LocationSharingScreen: No other users online to notify');
        return;
      }
      
      print('📢 LocationSharingScreen: Found ${allUsers.length} online users for auto-notification');
      
      // Get users with FCM tokens
      final usersWithTokens = allUsers.where((user) => user.fcmToken != null).toList();
      
      if (usersWithTokens.isEmpty) {
        print('⚠️ LocationSharingScreen: No users have FCM tokens for auto-notification');
        return;
      }
      
      // Get current user info
      final currentUser = ref.read(authControllerProvider).profile;
      final userName = currentUser?.name ?? currentUser?.email ?? 'Unknown User';
      
      // Send auto-notification to all users
      final fcmTokens = usersWithTokens.map((user) => user.fcmToken!).toList();
      final result = await BackendFCMService.sendNotificationToMultipleUsers(
        fcmTokens: fcmTokens,
        title: '📍 $userName is sharing location',
        body: 'Tap to view their current location',
        data: {
          'type': 'location_share_auto',
          'senderName': userName,
          'senderUid': currentUser?.uid ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (result['success'] == true) {
        final successCount = result['successCount'] ?? 0;
        print('✅ LocationSharingScreen: Auto-notification sent to $successCount users');
        
        // Show local confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('📢 Notification sent to $successCount users'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('❌ LocationSharingScreen: Auto-notification failed: ${result['error']}');
      }
      
    } catch (e) {
      print('❌ LocationSharingScreen: Auto-notification failed: $e');
    }
  }


  Future<void> _shareLocation() async {
    try {
      print('📍 LocationSharingScreen: Starting automatic location sharing process...');
      
      // Use the enhanced permission service for location sharing
      final hasPermission = await LocationPermissionService.requestLocationSharingPermission(context);
      if (!hasPermission) {
        print('❌ LocationSharingScreen: Location permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to share your location.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      print('✅ LocationSharingScreen: Location permission granted, proceeding with automatic sharing...');

      // Get current user info for automatic message
      final currentUser = ref.read(authControllerProvider).profile;
      final userName = currentUser?.name ?? currentUser?.email ?? 'Unknown User';
      
      // Create automatic message with timestamp
      final timestamp = DateTime.now();
      final formattedTime = DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp);
      final autoMessage = '📍 $userName shared location at $formattedTime';
      
      // Now try to share location automatically
      await ref.read(locationSharingControllerProvider.notifier).shareLocation(
        message: autoMessage,
      );
      
      // Show success dialog with user count
      if (mounted) {
        _showLocationSharedDialog();
      }
    } catch (e) {
      String errorMessage = e.toString();
      
      // Handle specific location errors
      if (errorMessage.contains('Location services are disabled')) {
        errorMessage = 'Location services are disabled. Please enable them in your device settings.';
      } else if (errorMessage.contains('permission denied')) {
        errorMessage = 'Location permission denied. Please grant location permission.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (errorMessage.contains('location unavailable')) {
        errorMessage = 'Location is currently unavailable. Please try again.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share location: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _viewLocationOnMap(LocationShare share) {
    Navigator.of(context).pushNamed(
      AppRouter.map,
      arguments: {
        'senderName': share.senderName,
        'lat': share.latitude,
        'lng': share.longitude,
      },
    );
  }

  Future<void> _openInGoogleMaps(LocationShare share) async {
    try {
      // Try to open in Google Maps app first
      final googleMapsUrl = 'https://www.google.com/maps?q=${share.latitude},${share.longitude}';
      final googleMapsAppUrl = 'comgooglemaps://?q=${share.latitude},${share.longitude}';
      
      // Try to launch Google Maps app
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(Uri.parse(googleMapsAppUrl));
        print('✅ LocationSharingScreen: Opened ${share.senderName}\'s location in Google Maps app');
        return;
      }
      
      // Fallback to web browser
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
        print('✅ LocationSharingScreen: Opened ${share.senderName}\'s location in web browser');
        return;
      }
      
      // If both fail, show dialog with manual option
      _showManualMapDialog(googleMapsUrl, share.senderName);
      
    } catch (e) {
      print('❌ LocationSharingScreen: Failed to open Google Maps: $e');
      _showManualMapDialog('https://www.google.com/maps?q=${share.latitude},${share.longitude}', share.senderName);
    }
  }

  Future<void> _openUserLocationInGoogleMaps(UserLocation user) async {
    try {
      // Try to open in Google Maps app first
      final googleMapsUrl = 'https://www.google.com/maps?q=${user.latitude},${user.longitude}';
      final googleMapsAppUrl = 'comgooglemaps://?q=${user.latitude},${user.longitude}';
      
      // Try to launch Google Maps app
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(Uri.parse(googleMapsAppUrl));
        print('✅ LocationSharingScreen: Opened ${user.name}\'s location in Google Maps app');
        return;
      }
      
      // Fallback to web browser
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
        print('✅ LocationSharingScreen: Opened ${user.name}\'s location in web browser');
        return;
      }
      
      // If both fail, show dialog with manual option
      _showManualMapDialog(googleMapsUrl, user.name);
      
    } catch (e) {
      print('❌ LocationSharingScreen: Failed to open Google Maps: $e');
      _showManualMapDialog('https://www.google.com/maps?q=${user.latitude},${user.longitude}', user.name);
    }
  }

  void _showManualMapDialog(String url, String senderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.map, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text('$senderName\'s Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Unable to open Google Maps automatically. Please copy the link below:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Coordinates: ${url.split('q=')[1]}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copied to clipboard. Please paste it in a new tab.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('Copy URL'),
          ),
        ],
      ),
    );
  }

  void _showLocationSharedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<UserLocation>>(
          future: ref.read(loggedInUsersProvider.future),
          builder: (context, snapshot) {
            final userCount = snapshot.data?.length ?? 0;
            
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  const Text('Location Shared!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📍 Your location has been automatically shared!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userCount > 0 
                                ? 'Sent to $userCount user${userCount == 1 ? '' : 's'}'
                                : 'No other users online',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Other users will see your location in their "Received" tab and can view it on the map.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
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
      },
    );
  }

  void _showPermissionInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Information'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To share your location, the app needs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Location permission granted'),
              Text('• Location services enabled'),
              Text('• GPS signal available'),
              SizedBox(height: 8),
              Text(
                'If you encounter issues:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Check device location settings'),
              Text('• Ensure GPS is enabled'),
              Text('• Grant location permission when prompted'),
            ],
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

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationSharingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showPermissionInfo(context),
            tooltip: 'Permission Info',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Share', icon: Icon(Icons.location_on)),
            Tab(text: 'Received', icon: Icon(Icons.download)),
            Tab(text: 'Users', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShareTab(locationState),
          _buildReceivedTab(locationState),
          _buildUsersTab(locationState),
        ],
      ),
    );
  }

  Widget _buildShareTab(LocationSharingState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Permission Status Card
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'Location Permission Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<bool>(
                    future: LocationPermissionService.hasLocationPermission(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Checking permissions...'),
                          ],
                        );
                      }
                      
                      final hasPermission = snapshot.data ?? false;
                      return Row(
                        children: [
                          Icon(
                            hasPermission ? Icons.check_circle : Icons.error,
                            color: hasPermission ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasPermission 
                                ? 'Location permission granted' 
                                : 'Location permission required',
                            style: TextStyle(
                              color: hasPermission ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<bool>(
                    future: LocationPermissionService.isLocationServiceEnabled(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      
                      final isEnabled = snapshot.data ?? false;
                      return Row(
                        children: [
                          Icon(
                            isEnabled ? Icons.check_circle : Icons.error,
                            color: isEnabled ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEnabled 
                                ? 'Location services enabled' 
                                : 'Location services disabled',
                            style: TextStyle(
                              color: isEnabled ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Share Location Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.autoShare ? 'Auto-Sharing Your Location' : 'Share Your Location',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.autoShare 
                                ? '📍 Location is being automatically shared with ALL logged-in users'
                                : '📍 Location will be automatically shared with ALL logged-in users',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Real-time user count indicator
                  FutureBuilder<List<UserLocation>>(
                    future: ref.read(loggedInUsersProvider.future),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Loading user count...'),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      final users = snapshot.data ?? [];
                      final userCount = users.length;
                      
                      return Card(
                        color: userCount > 0 ? Colors.green.shade50 : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                userCount > 0 ? Icons.people : Icons.person_off,
                                color: userCount > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userCount > 0 
                                          ? '📍 Location will be shared with $userCount user${userCount == 1 ? '' : 's'}'
                                          : '⚠️ No other users online',
                                      style: TextStyle(
                                        color: userCount > 0 ? Colors.green.shade700 : Colors.orange.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (userCount > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap "Share Location Now" to send your current location',
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  if (!widget.autoShare) ...[
                    ElevatedButton.icon(
                      onPressed: state.isSharing ? null : _shareLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: state.isSharing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.location_on, size: 24),
                      label: Text(
                        state.isSharing ? 'Sharing Location...' : '📍 Share Location Now',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Show auto-sharing status when coming from quick action
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          if (state.isSharing) ...[
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              '📍 Auto-sharing your location...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ] else ...[
                            const Icon(Icons.check_circle, color: Colors.green, size: 24),
                            const SizedBox(width: 12),
                            const Text(
                              '✅ Location shared successfully!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildMySharesList(state.myShares),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(LocationSharingState state) {
    if (state.receivedShares.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No location shares received yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When other users share their location,\nit will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.receivedShares.length,
      itemBuilder: (context, index) {
        final share = state.receivedShares[index];
        return _buildLocationShareCard(share, isReceived: true);
      },
    );
  }

  Widget _buildUsersTab(LocationSharingState state) {
    return FutureBuilder<List<UserLocation>>(
      future: ref.read(loggedInUsersProvider.future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(locationSharingControllerProvider.notifier).refreshLoggedInUsers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No other users online',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user);
          },
        );
      },
    );
  }

  Widget _buildLocationShareCard(LocationShare share, {bool isReceived = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isReceived ? Colors.blue : Colors.green,
          child: Icon(
            isReceived ? Icons.download : Icons.upload,
            color: Colors.white,
          ),
        ),
        title: Text(share.senderName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(share.message),
            const SizedBox(height: 4),
            Text(
              '${share.latitude.toStringAsFixed(6)}, ${share.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            Text(
              _dateFormat.format(share.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: () => _viewLocationOnMap(share),
              tooltip: 'View on Map',
            ),
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => _openInGoogleMaps(share),
              tooltip: 'Open in Google Maps',
            ),
          ],
        ),
        onTap: () => _viewLocationOnMap(share),
      ),
    );
  }

  Widget _buildUserCard(UserLocation user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isLoggedIn ? Colors.green : Colors.grey,
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.locationStatus),
            if (user.hasLocation) ...[
              const SizedBox(height: 4),
              Text(
                '${user.latitude!.toStringAsFixed(6)}, ${user.longitude!.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ],
        ),
        trailing: user.hasLocation
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: () => Navigator.of(context).pushNamed(
                      AppRouter.map,
                      arguments: {
                        'senderName': user.name,
                        'lat': user.latitude!,
                        'lng': user.longitude!,
                      },
                    ),
                    tooltip: 'View Location',
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _openUserLocationInGoogleMaps(user),
                    tooltip: 'Open in Google Maps',
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildMySharesList(List<LocationShare> shares) {
    if (shares.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No location shares yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Share your location to see it here',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Shares',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: shares.length,
            itemBuilder: (context, index) {
              final share = shares[index];
              return _buildLocationShareCard(share, isReceived: false);
            },
          ),
        ),
      ],
    );
  }
}
