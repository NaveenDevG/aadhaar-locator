import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/routing/app_router.dart';

class LocationSharingDemo extends ConsumerStatefulWidget {
  const LocationSharingDemo({super.key});

  @override
  ConsumerState<LocationSharingDemo> createState() => _LocationSharingDemoState();
}

class _LocationSharingDemoState extends ConsumerState<LocationSharingDemo> {
  Position? _currentPosition;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _viewOnMap() {
    if (_currentPosition != null) {
      Navigator.of(context).pushNamed(
        AppRouter.map,
        arguments: {
          'senderName': 'My Location',
          'lat': _currentPosition!.latitude,
          'lng': _currentPosition!.longitude,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Sharing Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocation,
            tooltip: 'Refresh Location',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Location Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading) ...[
                      const Center(child: CircularProgressIndicator()),
                      const SizedBox(height: 16),
                    ] else if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        child: const Text('Retry'),
                      ),
                    ] else if (_currentPosition != null) ...[
                      _buildLocationInfo(_currentPosition!),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _viewOnMap,
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
                      ),
                    ] else ...[
                      const Text('No location available'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Location Sharing Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location Sharing Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      'Share Location',
                      'Share your current location with other logged-in users',
                      Icons.location_on,
                      Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      'View Shared Locations',
                      'See locations shared by other users',
                      Icons.download,
                      Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      'Real-time Updates',
                      'Get notified when users share their location',
                      Icons.notifications,
                      Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    _buildFeatureItem(
                      'Interactive Maps',
                      'View all shared locations on interactive maps',
                      Icons.map,
                      Colors.purple,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Buttons
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(AppRouter.locationSharing),
              icon: const Icon(Icons.share_location),
              label: const Text('Open Location Sharing'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(Position position) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Latitude', position.latitude.toStringAsFixed(6)),
        _buildInfoRow('Longitude', position.longitude.toStringAsFixed(6)),
        _buildInfoRow('Accuracy', '${position.accuracy.toStringAsFixed(1)}m'),
        _buildInfoRow('Altitude', position.altitude != null 
            ? '${position.altitude.toStringAsFixed(1)}m' 
            : 'Not available'),
        _buildInfoRow('Speed', position.speed != null 
            ? '${position.speed.toStringAsFixed(1)}m/s' 
            : 'Not available'),
        _buildInfoRow('Timestamp', 
            '${position.timestamp.day}/${position.timestamp.month}/${position.timestamp.year} '
            '${position.timestamp.hour}:${position.timestamp.minute.toString().padLeft(2, '0')}'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
