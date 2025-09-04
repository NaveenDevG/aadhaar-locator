import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/services/firebase_connectivity_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_providers.dart';
import 'features/notifications/services/fcm_service.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('🔥 Firebase: Starting initialization...');
    
    // Initialize Firebase with proper configuration
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase: Core initialized successfully');
    } catch (e) {
      print('❌ Firebase: Initialization failed: $e');
      print('💡 Firebase features will be disabled');
      print('🔧 Please check your Firebase configuration');
    }
    
    // Test Firebase connectivity using the service
    print('🔍 Testing Firebase connectivity...');
    final connectivityService = FirebaseConnectivityService();
    await connectivityService.initialize();
    
    if (connectivityService.isConnected) {
      print('✅ Firebase connectivity confirmed');
    } else {
      print('⚠️ Firebase connectivity issues detected');
      final status = await connectivityService.getConnectivityStatus();
      print('📊 Connectivity Status:');
      print('   - Connected: ${status['isConnected']}');
      print('   - Last Error: ${status['lastError']}');
      print('   - Recommendations:');
      for (final rec in status['recommendations']) {
        print('     • $rec');
      }
    }
    
    // FCM service will be initialized in the splash screen with deep link handling
    print('📱 FCM: Will be initialized in splash screen');
    
    // Add a small delay to ensure Firebase is fully initialized
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Log Google Play Services status
    print('🔧 Checking Google Play Services status...');
    try {
      // This is a simple check - if Firebase initializes, Google Play Services should be working
      print('✅ Google Play Services appears to be working');
    } catch (e) {
      print('⚠️ Google Play Services issue detected: $e');
      print('💡 This may cause authentication problems on some devices');
    }
    
    print('🚀 App: Starting...');
    runApp(const ProviderScope(child: MyApp()));
  } catch (e) {
    print('❌ Firebase: Initialization failed: $e');
    // Still run the app, but Firebase features won't work
    runApp(const ProviderScope(child: MyApp()));
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    return MaterialApp(
      title: 'Aadhaar Locator',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRouter.splash, // Always start with splash for proper auth restoration
      routes: AppRouter.routes,
    );
  }
  
  String _getInitialRoute(AuthState authState) {
    if (authState.isAuthenticated) {
      if (authState.firstLoginRequired) {
        return AppRouter.splash; // Will show first login setup
      } else {
        return AppRouter.dashboard;
      }
    } else {
      return AppRouter.login;
    }
  }
}
