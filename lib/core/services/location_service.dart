// Real GPS location service implementation using geolocator plugin
// This provides actual GPS functionality with Flutter 3.22.3 compatibility
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

// Real GPS location service using geolocator plugin
// No need for mock classes - using real geolocator types

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('Error checking location service: $e');
      return false;
    }
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      return LocationPermission.denied;
    }
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    try {
      LocationPermission permission = await checkLocationPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedException();
      }

      return permission;
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      throw LocationPermissionDeniedException();
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

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Convert coordinates to address using reverse geocoding
  Future<LocationData?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        return LocationData(
          latitude: latitude,
          longitude: longitude,
          address: '${place.street ?? ''}, ${place.locality ?? ''}',
          city: place.locality ?? place.administrativeArea ?? 'Unknown City',
          state: place.administrativeArea ?? 'Unknown State',
          postalCode: place.postalCode ?? '000000',
          country: place.country ?? 'India',
          locality: place.locality ?? 'Unknown Locality',
          subLocality: place.subLocality ?? place.subAdministrativeArea ?? 'Unknown Area',
        );
      }

      // Fallback for when no placemark is found
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
      await Geolocator.openLocationSettings();
    } catch (e) {
      debugPrint('Error opening location settings: $e');
    }
  }

  /// Open app settings for permissions
  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
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
