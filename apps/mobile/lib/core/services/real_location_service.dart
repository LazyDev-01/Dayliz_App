// Production-ready GPS location service implementation
// Supports both real GPS and mock GPS for development/testing
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
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
  final String? thoroughfare; // Street name
  final String? subThoroughfare; // House number

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
    this.thoroughfare,
    this.subThoroughfare,
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

  // Mock data for development/testing (only used when AppConfig.useRealGPS = false)
  final List<Map<String, dynamic>> _mockLocations = [
    {
      'name': 'Test Location',
      'lat': 25.5138,
      'lng': 90.2172,
      'address': 'Test Address',
      'city': 'Test City',
      'state': 'Test State',
      'postalCode': '000000',
      'country': 'India',
      'locality': 'Test Locality',
      'subLocality': 'Test SubLocality',
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
      // First, check if location services are enabled (GPS on/off)
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationServiceDisabledException();
      }

      // Then check and request app permission
      LocationPermission permission = await requestLocationPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException();
      }

      if (AppConfig.useRealGPS) {
        // Real GPS implementation
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 6),  // Reduced from 10s to 6s for faster response
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

          // Build a comprehensive address string
          final addressParts = <String>[];

          // Add street/thoroughfare (this will be address_line_1)
          if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
            addressParts.add(placemark.thoroughfare!);
          } else if (placemark.street != null && placemark.street!.isNotEmpty) {
            addressParts.add(placemark.street!);
          }

          // Add sub-locality/area (this will be address_line_2)
          if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
            addressParts.add(placemark.subLocality!);
          } else if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            addressParts.add(placemark.locality!);
          }

          final fullAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : 'Location detected';

          return LocationData(
            latitude: latitude,
            longitude: longitude,
            address: fullAddress,
            city: placemark.locality ?? placemark.subAdministrativeArea ?? 'Unknown City',
            state: placemark.administrativeArea ?? 'Unknown State',
            postalCode: placemark.postalCode ?? '000000',
            country: placemark.country ?? 'India',
            locality: placemark.locality,
            subLocality: placemark.subLocality,
            thoroughfare: placemark.thoroughfare,
            subThoroughfare: placemark.subThoroughfare,
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

  /// Get current location with coordinates only (no internet required)
  Future<LocationData?> getCurrentLocationCoordinatesOnly() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) return null;

      // Return location data with coordinates only, no address resolution
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Location detected', // Placeholder address
        city: '',
        state: '',
        postalCode: '',
        country: '',
        locality: '',
        subLocality: '',
      );
    } catch (e) {
      return null;
    }
  }

  /// Get current location with full address details (requires internet)
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
      return null;
    }
  }

  /// Request GPS service to be enabled via Android system dialog
  /// This shows the "Location services are off" dialog with OK/Cancel
  Future<bool> requestLocationService() async {
    try {
      if (AppConfig.useRealGPS) {
        loc.Location location = loc.Location();
        return await location.requestService();
      } else {
        // Mock implementation
        await Future.delayed(const Duration(milliseconds: 1000));
        return true; // Simulate user enabling GPS
      }
    } catch (e) {
      return false;
    }
  }

  /// Open location settings (fallback method)
  Future<void> openLocationSettings() async {
    try {
      if (AppConfig.useRealGPS) {
        await Geolocator.openLocationSettings();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    try {
      if (AppConfig.useRealGPS) {
        await Geolocator.openAppSettings();
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      // Silently handle errors
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
