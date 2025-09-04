import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../data/repositories/location_repository.dart';

final locationRepositoryProvider = Provider<LocationRepository>((ref) => 
  LocationRepository()
);

final locationFutureProvider = FutureProvider<Position>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return await repository.getCurrentPosition();
});

final lastKnownLocationProvider = FutureProvider<Position?>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return await repository.getLastKnownPosition();
});

final locationPermissionProvider = FutureProvider<LocationPermission>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return await repository.checkPermission();
});

final locationServiceEnabledProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return await repository.isLocationServiceEnabled();
});
