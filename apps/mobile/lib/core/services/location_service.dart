// Production-ready GPS location service implementation
// Supports both real GPS and mock GPS for development/testing
import 'package:geolocator/geolocator.dart';
import 'real_location_service.dart';

// Export LocationData from real_location_service for backward compatibility
export 'real_location_service.dart' show LocationData;

// Mock permission enum (for development/testing)
enum MockLocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
}

// Mock position class (for development/testing)
class MockPosition {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  MockPosition({
    required this.latitude,
    required this.longitude,
    this.accuracy = 10.0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Wrapper class for backward compatibility
/// Delegates to RealLocationService for production-ready GPS functionality
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final RealLocationService _realService = RealLocationService();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _realService.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await _realService.checkLocationPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    return await _realService.requestLocationPermission();
  }

  /// Request GPS service to be enabled via Android system dialog
  Future<bool> requestLocationService() async {
    return await _realService.requestLocationService();
  }

  /// Get current position with error handling
  Future<Position?> getCurrentPosition() async {
    return await _realService.getCurrentPosition();
  }

  /// Legacy method for backward compatibility
  Future<MockPosition?> getCurrentPositionMock() async {
    Position? position = await getCurrentPosition();
    if (position == null) return null;

    return MockPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  /// Convert coordinates to address using reverse geocoding
  Future<LocationData?> getAddressFromCoordinates(double latitude, double longitude) async {
    return await _realService.getAddressFromCoordinates(latitude, longitude);
  }

  /// Get current location with coordinates only (no internet required)
  Future<LocationData?> getCurrentLocationCoordinatesOnly() async {
    return await _realService.getCurrentLocationCoordinatesOnly();
  }

  /// Get current location with full address details (requires internet)
  Future<LocationData?> getCurrentLocationWithAddress() async {
    return await _realService.getCurrentLocationWithAddress();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    return await _realService.openLocationSettings();
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    return await _realService.openAppSettings();
  }
}

// Custom exceptions
class LocationServiceDisabledException implements Exception {
  final String message = 'Location services are disabled. Please enable location services.';

  @override
  String toString() => message;
}

class LocationPermissionDeniedException implements Exception {
  final String message = 'Location permission denied. Please grant location permission to use this feature.';

  @override
  String toString() => message;
}
