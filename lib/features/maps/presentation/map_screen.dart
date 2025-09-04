import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  final String senderName;
  final double latitude;
  final double longitude;

  const MapScreen({
    super.key,
    required this.senderName,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.senderName}\'s Location'),
        centerTitle: true,
      ),
      body: _buildLocationDisplay(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openInGoogleMaps(),
        child: const Icon(Icons.open_in_new),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Icon(
                Icons.location_on,
                size: 80,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '📍 ${widget.senderName}\'s Location',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.explore, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Latitude: ${widget.latitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.navigation, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Longitude: ${widget.longitude.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openInGoogleMaps(),
              icon: const Icon(Icons.open_in_new),
              label: const Text('🌐 Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Click the button above to view this location in Google Maps.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openInGoogleMaps() async {
    try {
      print('🗺️ MapScreen: Attempting to open location in Google Maps...');
      
      // Try different URL schemes for better compatibility
      final coordinates = '${widget.latitude},${widget.longitude}';
      final locationName = widget.senderName.replaceAll(' ', '+');
      
      // 1. Try Google Maps app with coordinates
      final googleMapsAppUrl = 'comgooglemaps://?q=$coordinates&center=$coordinates&zoom=15';
      
      // 2. Try Apple Maps (iOS)
      final appleMapsUrl = 'http://maps.apple.com/?q=$coordinates&ll=$coordinates&z=15';
      
      // 3. Try Google Maps web with better formatting
      final googleMapsWebUrl = 'https://www.google.com/maps/search/?api=1&query=$coordinates&zoom=15';
      
      // 4. Try Google Maps with location name
      final googleMapsWithName = 'https://www.google.com/maps/search/?api=1&query=$locationName+$coordinates';
      
      // Try Google Maps app first
      try {
        if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
          await launchUrl(Uri.parse(googleMapsAppUrl));
          print('✅ MapScreen: Opened in Google Maps app');
          return;
        }
      } catch (e) {
        print('⚠️ MapScreen: Google Maps app not available: $e');
      }
      
      // Try Apple Maps (iOS)
      try {
        if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
          await launchUrl(Uri.parse(appleMapsUrl));
          print('✅ MapScreen: Opened in Apple Maps');
          return;
        }
      } catch (e) {
        print('⚠️ MapScreen: Apple Maps not available: $e');
      }
      
      // Try Google Maps web with better formatting
      try {
        if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
          await launchUrl(
            Uri.parse(googleMapsWebUrl),
            mode: LaunchMode.externalApplication,
          );
          print('✅ MapScreen: Opened in web browser (Google Maps)');
          return;
        }
      } catch (e) {
        print('⚠️ MapScreen: Google Maps web not available: $e');
      }
      
      // Try Google Maps with location name
      try {
        if (await canLaunchUrl(Uri.parse(googleMapsWithName))) {
          await launchUrl(
            Uri.parse(googleMapsWithName),
            mode: LaunchMode.externalApplication,
          );
          print('✅ MapScreen: Opened in web browser (with location name)');
          return;
        }
      } catch (e) {
        print('⚠️ MapScreen: Google Maps with name not available: $e');
      }
      
      // If all fail, show dialog with manual option
      _showManualMapDialog(googleMapsWebUrl);
      
    } catch (e) {
      print('❌ MapScreen: Failed to open any maps app: $e');
      _showManualMapDialog('https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}');
    }
  }

  void _showManualMapDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.map, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('Open in Google Maps'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maps app not found. You can:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.download, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Install Google Maps or Apple Maps'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.open_in_browser, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                const Text('Open in web browser'),
              ],
            ),
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
              'Coordinates: ${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
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
            onPressed: () async {
              Navigator.of(context).pop();
              // Try to open in web browser as fallback
              try {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to open maps. Please install a maps app.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open maps. Please install a maps app.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Open in Browser'),
          ),
        ],
      ),
    );
  }
}

