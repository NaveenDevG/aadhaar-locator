import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_sharing_service.dart';
import '../models/location_share.dart';
import '../models/user_location.dart';
import '../../auth/providers/auth_providers.dart';

// Providers
final locationSharingServiceProvider = Provider<LocationSharingService>((ref) {
  return LocationSharingService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

// State classes
class LocationSharingState {
  final bool isLoading;
  final String? error;
  final List<LocationShare> receivedShares;
  final List<LocationShare> myShares;
  final List<UserLocation> loggedInUsers;
  final bool isSharing;

  const LocationSharingState({
    this.isLoading = false,
    this.error,
    this.receivedShares = const [],
    this.myShares = const [],
    this.loggedInUsers = const [],
    this.isSharing = false,
  });

  LocationSharingState copyWith({
    bool? isLoading,
    String? error,
    List<LocationShare>? receivedShares,
    List<LocationShare>? myShares,
    List<UserLocation>? loggedInUsers,
    bool? isSharing,
  }) {
    return LocationSharingState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      receivedShares: receivedShares ?? this.receivedShares,
      myShares: myShares ?? this.myShares,
      loggedInUsers: loggedInUsers ?? this.loggedInUsers,
      isSharing: isSharing ?? this.isSharing,
    );
  }
}

// Controller
class LocationSharingController extends StateNotifier<LocationSharingState> {
  final LocationSharingService _service;

  LocationSharingController(this._service) : super(const LocationSharingState()) {
    _init();
  }

  void _init() {
    // Listen to received location shares
    _service.getActiveLocationShares().listen((shares) {
      state = state.copyWith(receivedShares: shares);
    });

    // Listen to my location shares
    _service.getMyLocationShares().listen((shares) {
      state = state.copyWith(myShares: shares);
    });
  }

  /// Share current location
  Future<void> shareLocation({
    required String message,
    String? address,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null, isSharing: true);

      // Get current location
      final position = await _service.getCurrentLocation();

      // Share location
      await _service.shareLocation(
        message: message,
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
      );

      state = state.copyWith(isLoading: false, isSharing: false);
    } catch (e) {
      print('❌ LocationSharingController: Failed to share location: $e');
      
      // Provide more specific error messages
      String errorMessage = e.toString();
      if (errorMessage.contains('User profile not found')) {
        errorMessage = 'User profile not found. Please try logging out and logging back in.';
      } else if (errorMessage.contains('permission denied')) {
        errorMessage = 'Location permission denied. Please grant location permission.';
      } else if (errorMessage.contains('timeout')) {
        errorMessage = 'Location request timed out. Please try again.';
      } else if (errorMessage.contains('location unavailable')) {
        errorMessage = 'Location is currently unavailable. Please try again.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isSharing: false,
      );
      rethrow;
    }
  }

  /// Refresh logged-in users
  Future<void> refreshLoggedInUsers() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final users = await _service.getLoggedInUsers();
      state = state.copyWith(loggedInUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Deactivate a location share
  Future<void> deactivateShare(String shareId) async {
    try {
      await _service.deactivateLocationShare(shareId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final locationSharingControllerProvider = StateNotifierProvider<LocationSharingController, LocationSharingState>((ref) {
  return LocationSharingController(
    ref.watch(locationSharingServiceProvider),
  );
});

// Individual stream providers
final receivedLocationSharesProvider = StreamProvider<List<LocationShare>>((ref) {
  final service = ref.watch(locationSharingServiceProvider);
  return service.getActiveLocationShares();
});

final myLocationSharesProvider = StreamProvider<List<LocationShare>>((ref) {
  final service = ref.watch(locationSharingServiceProvider);
  return service.getMyLocationShares();
});

final loggedInUsersProvider = FutureProvider<List<UserLocation>>((ref) {
  final service = ref.watch(locationSharingServiceProvider);
  return service.getLoggedInUsers();
});
