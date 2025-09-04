import 'package:flutter/material.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/maps/presentation/map_screen.dart';
import '../../features/location/presentation/location_sharing_screen.dart';
import '../../features/location/presentation/location_sharing_demo.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String map = '/map';
  static const String locationSharing = '/location-sharing';
  static const String locationSharingDemo = '/location-sharing-demo';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    dashboard: (context) => const DashboardScreen(),
    map: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MapScreen(
        senderName: args?['senderName'] ?? 'User',
        latitude: args?['lat'] as double? ?? 0.0,
        longitude: args?['lng'] as double? ?? 0.0,
      );
    },
    locationSharing: (context) => const LocationSharingScreen(),
    locationSharingDemo: (context) => const LocationSharingDemo(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case map:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => MapScreen(
            senderName: args?['senderName'] ?? 'User',
            latitude: args?['lat'] as double? ?? 0.0,
            longitude: args?['lng'] as double? ?? 0.0,
          ),
        );
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
