// Enhanced mock GPS location service implementation
// This provides realistic GPS simulation until real GPS integration is ready
import 'dart:math';
import 'package:flutter/foundation.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? locality;
  final String? subLocality;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.locality,
    this.subLocality,
  });

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address, city: $city, state: $state, postal: $postalCode)';
  }
}

// Mock permission enum
enum MockLocationPermission {
  denied,
  deniedForever,
  whileInUse,
  always,
}

// Mock position class
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

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Enhanced mock data for different locations
  final List<Map<String, dynamic>> _mockLocations = [
    {
      'name': 'Tura, Meghalaya',
      'lat': 25.5138,
      'lng': 90.2172,
      'address': 'Main Market Road, Tura',
      'city': 'Tura',
      'state': 'Meghalaya',
      'postalCode': '794101',
      'country': 'India',
      'locality': 'Main Market Area',
      'subLocality': 'Commercial District',
    },
    {
      'name': 'Shillong, Meghalaya',
      'lat': 25.5788,
      'lng': 91.8933,
      'address': 'Police Bazar, Shillong',
      'city': 'Shillong',
      'state': 'Meghalaya',
      'postalCode': '793001',
      'country': 'India',
      'locality': 'Police Bazar',
      'subLocality': 'East Khasi Hills',
    },
    {
      'name': 'Guwahati, Assam',
      'lat': 26.1445,
      'lng': 91.7362,
      'address': 'Fancy Bazar, Guwahati',
      'city': 'Guwahati',
      'state': 'Assam',
      'postalCode': '781001',
      'country': 'India',
      'locality': 'Fancy Bazar',
      'subLocality': 'Kamrup Metropolitan',
    },
  ];

  int _currentLocationIndex = 0;

  /// Check if location services are enabled (enhanced mock)
  Future<bool> isLocationServiceEnabled() async {
    // Simulate checking device location services
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: Return true most of the time, occasionally false for testing
    return Random().nextDouble() > 0.1; // 90% chance of being enabled
  }

  /// Check location permission status (enhanced mock)
  Future<MockLocationPermission> checkLocationPermission() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: Return granted most of the time for testing
    final random = Random().nextDouble();
    if (random > 0.8) return MockLocationPermission.denied;
    if (random > 0.9) return MockLocationPermission.deniedForever;
    return MockLocationPermission.whileInUse;
  }

  /// Request location permission (enhanced mock)
  Future<MockLocationPermission> requestLocationPermission() async {
    MockLocationPermission permission = await checkLocationPermission();

    if (permission == MockLocationPermission.denied) {
      // Simulate user granting permission
      await Future.delayed(const Duration(milliseconds: 800));
      permission = MockLocationPermission.whileInUse;
    }

    if (permission == MockLocationPermission.deniedForever) {
      throw LocationPermissionDeniedException();
    }

    return permission;
  }

  /// Get current position with error handling (enhanced mock)
  Future<MockPosition?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Check and request permission
      MockLocationPermission permission = await requestLocationPermission();

      if (permission == MockLocationPermission.denied ||
          permission == MockLocationPermission.deniedForever) {
        throw LocationPermissionDeniedException();
      }

      // Simulate GPS detection delay
      await Future.delayed(const Duration(seconds: 2));

      // Get current mock location (rotate through different locations for testing)
      final location = _mockLocations[_currentLocationIndex % _mockLocations.length];
      _currentLocationIndex++;

      // Add some random variation to coordinates for realism
      final random = Random();
      final latVariation = (random.nextDouble() - 0.5) * 0.001; // ~100m variation
      final lngVariation = (random.nextDouble() - 0.5) * 0.001;

      MockPosition position = MockPosition(
        latitude: location['lat'] + latVariation,
        longitude: location['lng'] + lngVariation,
        accuracy: 5.0 + random.nextDouble() * 10.0, // 5-15m accuracy
      );

      return position;
    } catch (e) {
      // Use logger in production
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Convert coordinates to address using reverse geocoding (enhanced mock)
  Future<LocationData?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // Simulate reverse geocoding delay
      await Future.delayed(const Duration(milliseconds: 1500));

      // Find the closest mock location to the provided coordinates
      Map<String, dynamic>? closestLocation;
      double minDistance = double.infinity;

      for (final location in _mockLocations) {
        final distance = _calculateDistance(
          latitude, longitude,
          location['lat'], location['lng']
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestLocation = location;
        }
      }

      if (closestLocation != null) {
        return LocationData(
          latitude: latitude,
          longitude: longitude,
          address: closestLocation['address'],
          city: closestLocation['city'],
          state: closestLocation['state'],
          postalCode: closestLocation['postalCode'],
          country: closestLocation['country'],
          locality: closestLocation['locality'],
          subLocality: closestLocation['subLocality'],
        );
      }

      // Fallback for unknown coordinates
      return LocationData(
        latitude: latitude,
        longitude: longitude,
        address: 'GPS Location Detected',
        city: 'Unknown City',
        state: 'Unknown State',
        postalCode: '000000',
        country: 'India',
        locality: 'GPS Detected Area',
        subLocality: 'GPS District',
      );
    } catch (e) {
      debugPrint('Error in reverse geocoding: $e');
      return null;
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get current location with full address details
  Future<LocationData?> getCurrentLocationWithAddress() async {
    try {
      MockPosition? position = await getCurrentPosition();
      if (position == null) return null;

      LocationData? locationData = await getAddressFromCoordinates(
        position.latitude,
        position.longitude
      );

      return locationData;
    } catch (e) {
      debugPrint('Error getting current location with address: $e');
      return null;
    }
  }

  /// Open location settings (mock implementation)
  Future<void> openLocationSettings() async {
    try {
      // Mock: Simulate opening location settings
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('Mock: Opening location settings...');
    } catch (e) {
      debugPrint('Error opening location settings: $e');
    }
  }

  /// Open app settings for permissions (mock implementation)
  Future<void> openAppSettings() async {
    try {
      // Mock: Simulate opening app settings
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('Mock: Opening app settings...');
    } catch (e) {
      debugPrint('Error opening app settings: $e');
    }
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
