import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/routing/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../notifications/services/fcm_service.dart';

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

  Future<void> _bootstrap() async {
    try {
      print('🔄 Starting bootstrap process...');
      
      // Add timeout to prevent infinite loading
      final timeoutDuration = const Duration(seconds: 10);
      
      // Check Firebase connectivity first
      print('🔥 Checking Firebase connectivity...');
      try {
        final firestore = ref.read(firestoreProvider);
        await firestore.collection('test').limit(1).get().timeout(const Duration(seconds: 30));
        print('✅ Firebase connectivity confirmed');
      } catch (e) {
        print('⚠️ Firebase connectivity check failed: $e');
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
      try {
        await FCMService.initialize(
          onDeepLinkToMap: (payload) {
            if (!mounted) return;
            Navigator.of(context).pushNamed(
              AppRouter.map,
              arguments: {
                'senderName': payload['senderName'],
                'lat': payload['latitude'],
                'lng': payload['longitude'],
              },
            );
          },
        );
        print('✅ FCM service initialized successfully');
      } catch (e) {
        print('⚠️ FCM service initialization failed (continuing): $e');
        // Continue even if FCM fails
      }

      // Wait for splash animation
      print('⏳ Waiting for splash animation...');
      await Future.delayed(const Duration(milliseconds: 1500));
      print('✅ Splash animation completed');

      // Restore auth session with timeout
      print('🔐 Restoring auth session...');
      try {
        await ref.read(authControllerProvider.notifier).restoreSession()
            .timeout(timeoutDuration);
        print('✅ Auth session restored');
      } catch (e) {
        print('⚠️ Auth session restoration failed: $e');
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
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
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
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        size: 60,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // App Name
                    const Text(
                      'Aadhaar Locator',
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
                    const SizedBox(height: 48),
                    
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
    );
  }
}
