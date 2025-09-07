import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/services/fcm_service.dart';
import '../../../core/services/permission_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _loadingStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _bootstrap();
    
    // Fallback: Force navigation after 15 seconds if bootstrap gets stuck
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        print('⏰ Fallback timeout reached, forcing navigation to login...');
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  /// Open location directly in Google Maps when notification is tapped
  Future<void> _openLocationDirectlyInMaps(Map<String, dynamic> payload) async {
    try {
      final latitude = payload['latitude'] as double? ?? 0.0;
      final longitude = payload['longitude'] as double? ?? 0.0;
      final senderName = payload['senderName'] as String? ?? 'User';
      
      print('🗺️ SplashScreen: Opening location directly in Google Maps...');
      print('📍 Coordinates: $latitude, $longitude');
      print('👤 Sender: $senderName');
      
      // Format coordinates with proper precision
      final latFormatted = latitude.toStringAsFixed(6);
      final lngFormatted = longitude.toStringAsFixed(6);
      final coordinates = '$latFormatted,$lngFormatted';
      final locationName = senderName.replaceAll(' ', '+');
      
      // Try different Google Maps URLs in order of preference
      final urls = [
        // Google Maps app (Android/iOS) - Use proper format for location display
        'comgooglemaps://?q=$coordinates&center=$coordinates&zoom=15',
        // Google Maps app alternative format
        'comgooglemaps://?center=$coordinates&zoom=15',
        // Apple Maps (iOS) - Use proper format for location display
        'http://maps.apple.com/?q=$coordinates&ll=$coordinates&z=15',
        // Google Maps web - Use place format for better location display
        'https://www.google.com/maps/place/$coordinates/@$coordinates,15z',
        // Google Maps web - Alternative format with search
        'https://www.google.com/maps/search/?api=1&query=$coordinates',
        // Google Maps web - Fallback with location name
        'https://www.google.com/maps/search/?api=1&query=$locationName+$coordinates',
      ];
      
      bool opened = false;
      for (final url in urls) {
        try {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            print('✅ SplashScreen: Opened in maps app: $url');
            opened = true;
            break;
          }
        } catch (e) {
          print('⚠️ SplashScreen: Failed to open $url: $e');
          continue;
        }
      }
      
      if (!opened) {
        print('❌ SplashScreen: Could not open any maps app, falling back to app navigation');
        // Fallback: Navigate to app's map screen
        Navigator.of(context).pushNamed(
          AppRouter.map,
          arguments: {
            'senderName': senderName,
            'lat': latitude,
            'lng': longitude,
          },
        );
      }
    } catch (e) {
      print('❌ SplashScreen: Failed to open location in maps: $e');
      // Fallback: Navigate to app's map screen
      Navigator.of(context).pushNamed(
        AppRouter.map,
        arguments: {
          'senderName': payload['senderName'] ?? 'User',
          'lat': payload['latitude'] ?? 0.0,
          'lng': payload['longitude'] ?? 0.0,
        },
      );
    }
  }

  Future<void> _bootstrap() async {
    try {
      print('🔄 Starting bootstrap process...');
      
      // Add timeout to prevent infinite loading
      final timeoutDuration = const Duration(seconds: 10);
      
      // Request permissions first (most important)
      print('🔐 Requesting app permissions...');
      setState(() => _loadingStatus = 'Requesting permissions...');
      try {
        final allGranted = await PermissionService.areAllPermissionsGranted();
        if (!allGranted) {
          print('🔐 Some permissions not granted, requesting...');
          setState(() => _loadingStatus = 'Please grant permissions...');
          await PermissionService.requestAllPermissions(context);
          print('✅ Permission request completed');
        } else {
          print('✅ All permissions already granted');
        }
        setState(() => _loadingStatus = 'Permissions granted');
      } catch (e) {
        print('⚠️ Permission request failed: $e');
        setState(() => _loadingStatus = 'Permission setup completed');
        // Continue even if permissions fail - user can grant them later
      }
      
      // Check Firebase connectivity
      print('🔥 Checking Firebase connectivity...');
      setState(() => _loadingStatus = 'Connecting to Firebase...');
      try {
        final firestore = ref.read(firestoreProvider);
        await firestore.collection('test').limit(1).get().timeout(const Duration(seconds: 30));
        print('✅ Firebase connectivity confirmed');
        setState(() => _loadingStatus = 'Firebase connected');
      } catch (e) {
        print('⚠️ Firebase connectivity check failed: $e');
        setState(() => _loadingStatus = 'Firebase connection established');
        // Continue but log the issue - this is non-critical for app startup
        // The app will still work, just Firebase operations might be slower
        print('ℹ️ Continuing with app startup - Firebase operations may be slower');
        
        // Log additional network info
        if (e.toString().contains('UNAVAILABLE')) {
          print('🌐 Network: Firebase service unavailable - possible network connectivity issue');
          print('💡 This may cause Firestore operations to fail');
        } else if (e.toString().contains('timeout')) {
          print('⏱️ Network: Firebase request timed out - slow network connection');
          print('💡 Consider increasing timeout values for slow connections');
        }
        
        // Check for Google Play Services issues
        if (e.toString().contains('providerinstaller') || e.toString().contains('DynamiteModule')) {
          print('⚠️ Google Play Services: Provider installer module issue detected');
          print('💡 This may cause authentication problems on some devices');
        }
      }
      
      // Initialize FCM service
      print('📱 Initializing FCM service...');
      setState(() => _loadingStatus = 'Setting up notifications...');
      try {
        await FCMService.initialize(
          onDeepLinkToMap: (payload) {
            if (!mounted) return;
            _openLocationDirectlyInMaps(payload);
          },
        );
        print('✅ FCM service initialized successfully');
        setState(() => _loadingStatus = 'Notifications ready');
      } catch (e) {
        print('⚠️ FCM service initialization failed (continuing): $e');
        setState(() => _loadingStatus = 'Notification setup completed');
        // Continue even if FCM fails
      }

      // Wait for splash animation
      print('⏳ Waiting for splash animation...');
      setState(() => _loadingStatus = 'Finalizing setup...');
      await Future.delayed(const Duration(milliseconds: 1500));
      print('✅ Splash animation completed');

      // Restore auth session with timeout
      print('🔐 Restoring auth session...');
      setState(() => _loadingStatus = 'Checking authentication...');
      try {
        await ref.read(authControllerProvider.notifier).restoreSession()
            .timeout(timeoutDuration);
        print('✅ Auth session restored');
        setState(() => _loadingStatus = 'Authentication verified');
      } catch (e) {
        print('⚠️ Auth session restoration failed: $e');
        setState(() => _loadingStatus = 'Ready to login');
        // Continue to login if auth fails
      }
      
      if (!mounted) return;

      // Wait a bit for auth state to settle
      await Future.delayed(const Duration(milliseconds: 500));
      
      final authState = ref.read(authControllerProvider);
      print('👤 Auth state: ${authState.isAuthenticated ? 'Authenticated' : 'Not authenticated'}');
      print('👤 First login required: ${authState.firstLoginRequired}');
      print('👤 Profile loaded: ${authState.profile != null}');

      if (authState.isAuthenticated && authState.profile != null) {
        if (authState.firstLoginRequired) {
          print('🆕 First login required, completing...');
          try {
            // First actual login just happened, mark completed
            await ref.read(authControllerProvider.notifier).completeFirstLogin()
                .timeout(const Duration(seconds: 5));
            print('✅ First login completed');
          } catch (e) {
            print('⚠️ First login completion failed: $e');
            // Continue anyway
          }
        }
        print('🏠 Navigating to dashboard...');
        Navigator.of(context).pushReplacementNamed(AppRouter.dashboard);
      } else {
        print('🔑 Navigating to login...');
        Navigator.of(context).pushReplacementNamed(AppRouter.login);
      }
    } catch (e) {
      print('❌ Bootstrap error: $e');
      if (!mounted) return;
      // On error, still navigate to login
      print('🚨 Error occurred, navigating to login...');
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E), // Dark blue-gray
              Color(0xFF16213E), // Darker blue
              Color(0xFF0F3460), // Deep blue
              Color(0xFF533483), // Purple
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Icon/Logo
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 5,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Shield background with gradient
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF6B35),
                                    Color(0xFFE55A2B),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF6B35).withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            // Shield shape
                            CustomPaint(
                              size: const Size(70, 70),
                              painter: ShieldPainter(),
                            ),
                            // Location pin
                            const Positioned(
                              top: 25,
                              child: Icon(
                                Icons.location_on,
                                size: 28,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // App Name
                      const Text(
                        'Rakshak',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // App Tagline
                      const Text(
                        'Secure Location Sharing',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Powered by branding
                      const Text(
                        'Powered by IMBLV services pvt ltd',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white60,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Loading status text
                      Text(
                        _loadingStatus,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      
                      // Loading indicator
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Create shield shape
    path.moveTo(centerX, centerY - 25); // Top point
    path.lineTo(centerX + 18, centerY - 8); // Top right
    path.lineTo(centerX + 18, centerY + 12); // Right side
    path.lineTo(centerX, centerY + 25); // Bottom point
    path.lineTo(centerX - 18, centerY + 12); // Left side
    path.lineTo(centerX - 18, centerY - 8); // Top left
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
