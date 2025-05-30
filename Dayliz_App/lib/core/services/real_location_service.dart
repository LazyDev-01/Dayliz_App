// Production-ready GPS location service implementation
// Supports both real GPS and mock GPS for development/testing
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

/// Location data model for consistent data structure
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? locality;
  final String? subLocality;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.locality,
    this.subLocality,
  });

  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, address: $address, city: $city, state: $state, postal: $postalCode)';
  }
}

/// Production-ready Location Service with real GPS functionality
class RealLocationService {
  static final RealLocationService _instance = RealLocationService._internal();
  factory RealLocationService() => _instance;
  RealLocationService._internal();

  // Mock data for development/testing
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

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    if (AppConfig.useRealGPS) {
      return await Geolocator.isLocationServiceEnabled();
    } else {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 500));
      return Random().nextDouble() > 0.1; // 90% chance of being enabled
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    if (AppConfig.useRealGPS) {
      return await Geolocator.checkPermission();
    } else {
      // Mock implementation
      await Future.delayed(const Duration(milliseconds: 300));
      final random = Random().nextDouble();
      if (random > 0.8) return LocationPermission.denied;
      if (random > 0.9) return LocationPermission.deniedForever;
      return LocationPermission.whileInUse;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    if (AppConfig.useRealGPS) {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException();
      }
      
      return permission;
    } else {
      // Mock implementation
      LocationPermission permission = await checkLocationPermission();
      
      if (permission == LocationPermission.denied) {
        await Future.delayed(const Duration(milliseconds: 800));
        permission = LocationPermission.whileInUse;
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException();
      }
      
      return permission;
    }
  }

  /// Get current position with error handling
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Check and request permission
      LocationPermission permission = await requestLocationPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException();
      }

      if (AppConfig.useRealGPS) {
        // Real GPS implementation
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } else {
        // Mock implementation
        await Future.delayed(const Duration(seconds: 2));
        
        final location = _mockLocations[_currentLocationIndex % _mockLocations.length];
        _currentLocationIndex++;
        
        final random = Random();
        final latVariation = (random.nextDouble() - 0.5) * 0.001;
        final lngVariation = (random.nextDouble() - 0.5) * 0.001;
        
        return Position(
          longitude: location['lng'] + lngVariation,
          latitude: location['lat'] + latVariation,
          timestamp: DateTime.now(),
          accuracy: 5.0 + random.nextDouble() * 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Convert coordinates to address using reverse geocoding
  Future<LocationData?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      if (AppConfig.useRealGPS) {
        // Real reverse geocoding implementation
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
        
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          
          return LocationData(
            latitude: latitude,
            longitude: longitude,
            address: '${placemark.street ?? ''}, ${placemark.locality ?? ''}',
            city: placemark.locality ?? 'Unknown City',
            state: placemark.administrativeArea ?? 'Unknown State',
            postalCode: placemark.postalCode ?? '000000',
            country: placemark.country ?? 'India',
            locality: placemark.locality,
            subLocality: placemark.subLocality,
          );
        }
      } else {
        // Mock reverse geocoding implementation
        await Future.delayed(const Duration(milliseconds: 1500));
        
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
      Position? position = await getCurrentPosition();
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

  /// Open location settings
  Future<void> openLocationSettings() async {
    try {
      if (AppConfig.useRealGPS) {
        await Geolocator.openLocationSettings();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('Mock: Opening location settings...');
      }
    } catch (e) {
      debugPrint('Error opening location settings: $e');
    }
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    try {
      if (AppConfig.useRealGPS) {
        await Geolocator.openAppSettings();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        debugPrint('Mock: Opening app settings...');
      }
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
