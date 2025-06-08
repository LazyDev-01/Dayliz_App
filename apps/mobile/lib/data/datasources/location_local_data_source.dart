import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/exceptions.dart';
import '../models/zone_model.dart';

/// Abstract interface for location local data source
abstract class LocationLocalDataSource {
  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();

  /// Check location permission status
  Future<PermissionStatus> checkLocationPermission();

  /// Request location permission
  Future<PermissionStatus> requestLocationPermission();

  /// Get current GPS coordinates
  Future<LocationCoordinatesModel> getCurrentLocation();

  /// Check if location setup is completed for current session
  bool isLocationSetupCompleted();

  /// Mark location setup as completed for current session
  void markLocationSetupCompleted();

  /// Mark location setup as completed for specific user
  void markLocationSetupCompletedForUser(String userId);

  /// Check if location setup is completed for specific user
  bool isLocationSetupCompletedForUser(String userId);

  /// Clear location setup status
  void clearLocationSetupStatus();
}

/// Implementation of location local data source using geolocator
class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  // In-memory flag for location setup status (session-based)
  bool _isLocationSetupCompleted = false;
  String? _lastCompletedUserId; // Track which user completed setup

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      throw CacheException(message: 'Failed to check location service: $e');
    }
  }

  @override
  Future<PermissionStatus> checkLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      return permission;
    } catch (e) {
      throw CacheException(message: 'Failed to check location permission: $e');
    }
  }

  @override
  Future<PermissionStatus> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      return permission;
    } catch (e) {
      throw CacheException(message: 'Failed to request location permission: $e');
    }
  }

  @override
  Future<LocationCoordinatesModel> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Check permission
      final permission = await checkLocationPermission();
      if (permission == PermissionStatus.denied) {
        throw LocationPermissionDeniedException();
      }

      if (permission == PermissionStatus.permanentlyDenied) {
        throw LocationPermissionPermanentlyDeniedException();
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return LocationCoordinatesModel(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (e) {
      if (e is LocationServiceDisabledException ||
          e is LocationPermissionDeniedException ||
          e is LocationPermissionPermanentlyDeniedException) {
        rethrow;
      }
      throw CacheException(message: 'Failed to get current location: $e');
    }
  }

  @override
  bool isLocationSetupCompleted() {
    return _isLocationSetupCompleted;
  }

  @override
  void markLocationSetupCompleted() {
    _isLocationSetupCompleted = true;
  }

  @override
  void markLocationSetupCompletedForUser(String userId) {
    _isLocationSetupCompleted = true;
    _lastCompletedUserId = userId;
  }

  @override
  bool isLocationSetupCompletedForUser(String userId) {
    // Return true only if setup was completed for this specific user
    return _isLocationSetupCompleted && _lastCompletedUserId == userId;
  }

  @override
  void clearLocationSetupStatus() {
    _isLocationSetupCompleted = false;
    _lastCompletedUserId = null;
  }
}

/// Custom exceptions for location operations
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException({
    this.message = 'Location services are disabled',
  });
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException({
    this.message = 'Location permission denied',
  });
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  final String message;
  LocationPermissionPermanentlyDeniedException({
    this.message = 'Location permission permanently denied',
  });
}
