import 'dart:async';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';
import '../../domain/usecases/geofencing/detect_access_level_usecase.dart';
import '../../domain/entities/geofencing/delivery_zone.dart';
import '../../domain/entities/geofencing/enhanced_zone_detection_result.dart';
import '../../di/dependency_injection.dart';

/// Result of early location readiness check
class LocationReadinessResult {
  final LocationReadinessStatus status;
  final LocationData? locationData;
  final String? errorMessage;
  final bool isServiceAvailable;

  const LocationReadinessResult({
    required this.status,
    this.locationData,
    this.errorMessage,
    this.isServiceAvailable = false,
  });

  bool get isReady => status == LocationReadinessStatus.ready;
  bool get shouldGoToLocationAccess => status == LocationReadinessStatus.needsSetup || 
                                      status == LocationReadinessStatus.error ||
                                      status == LocationReadinessStatus.timeout;
  bool get shouldGoToServiceUnavailable => status == LocationReadinessStatus.outOfService;

  @override
  String toString() => 'LocationReadinessResult(status: $status, hasLocation: ${locationData != null}, serviceAvailable: $isServiceAvailable)';
}

/// Status of location readiness
enum LocationReadinessStatus {
  ready,           // GPS on, permission granted, coordinates obtained, zone validated
  needsSetup,      // GPS off or no permission
  outOfService,    // Outside delivery zones
  error,           // Error during checks
  timeout,         // Timeout during coordinate fetch or zone validation
}

/// Fast location checker for app startup optimization
/// Performs quick checks to determine if user can skip location setup
class EarlyLocationChecker {
  static const Duration _gpsCheckTimeout = Duration(seconds: 2);  // GPS check timeout
  static const Duration _coordinateTimeout = Duration(seconds: 8);  // Increased for better reliability in real-world conditions
  static const Duration _zoneValidationTimeout = Duration(seconds: 3);  // Increased for network calls
  
  static final LocationService _locationService = LocationService();

  /// Check if location is ready for immediate app use
  /// Returns quickly with cached results when possible
  static Future<LocationReadinessResult> checkLocationReadiness() async {
    try {
      // Step 1: Quick GPS and permission check
      final basicChecks = await _performBasicChecks();
      if (!basicChecks.canProceed) {
        return LocationReadinessResult(
          status: LocationReadinessStatus.needsSetup,
          errorMessage: basicChecks.reason,
        );
      }

      // Step 2: Get coordinates with timeout
      final locationData = await _getCoordinatesWithTimeout();
      if (locationData == null) {
        return const LocationReadinessResult(
          status: LocationReadinessStatus.timeout,
          errorMessage: 'Location detection timed out',
        );
      }

      // Step 3: Quick zone validation
      final zoneResult = await _validateZoneWithTimeout(locationData);

      if (zoneResult.isSuccess) {
        return LocationReadinessResult(
          status: LocationReadinessStatus.ready,
          locationData: locationData,
          isServiceAvailable: true,
        );
      } else {
        return LocationReadinessResult(
          status: LocationReadinessStatus.outOfService,
          locationData: locationData,
          errorMessage: 'Service not available in your area',
          isServiceAvailable: false,
        );
      }

    } catch (e) {
      return LocationReadinessResult(
        status: LocationReadinessStatus.error,
        errorMessage: 'Failed to check location: ${e.toString()}',
      );
    }
  }

  /// Perform basic GPS and permission checks with timeout
  static Future<BasicCheckResult> _performBasicChecks() async {
    try {
      return await Future.any([
        _doBasicChecks(),
        Future.delayed(_gpsCheckTimeout, () => BasicCheckResult(false, 'GPS check timed out')),
      ]);
    } catch (e) {
      return BasicCheckResult(false, 'Basic checks failed: ${e.toString()}');
    }
  }

  /// Actual basic checks implementation
  static Future<BasicCheckResult> _doBasicChecks() async {
    // Check GPS status
    final isGPSEnabled = await _locationService.isLocationServiceEnabled();
    if (!isGPSEnabled) {
      return BasicCheckResult(false, 'GPS is disabled');
    }

    // Check permission status
    final permission = await _locationService.checkLocationPermission();

    // Handle different permission states
    switch (permission) {
      case LocationPermission.denied:
        // This includes "ask every time" - needs user interaction
        return BasicCheckResult(false, 'Location permission needs user approval');
      case LocationPermission.deniedForever:
        return BasicCheckResult(false, 'Location permission permanently denied');
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        // Permission granted, can proceed
        return BasicCheckResult(true, 'All basic checks passed');
      default:
        return BasicCheckResult(false, 'Unknown permission state');
    }
  }

  /// Get coordinates with timeout (GPS-first approach)
  static Future<LocationData?> _getCoordinatesWithTimeout() async {
    try {
      // First try GPS-only (no internet required)
      final result = await Future.any([
        _locationService.getCurrentLocationCoordinatesOnly(),
        Future.delayed(_coordinateTimeout, () => null),
      ]);

      if (result != null) {
        // Try to get address if we have coordinates (optional, may fail with poor internet)
        try {
          final locationWithAddress = await Future.any([
            _locationService.getCurrentLocationWithAddress(),
            Future.delayed(const Duration(seconds: 2), () => null), // Shorter timeout for address
          ]);
          if (locationWithAddress != null) {
            return locationWithAddress; // Use full address if available
          }
        } catch (e) {
          // Address fetch failed, continue with coordinates-only
        }
      }

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Validate zone with timeout
  static Future<ZoneValidationResult> _validateZoneWithTimeout(LocationData locationData) async {
    try {
      return await Future.any([
        _performZoneValidation(locationData),
        Future.delayed(_zoneValidationTimeout, () => ZoneValidationResult(false, 'Zone validation timed out')),
      ]);
    } catch (e) {
      return ZoneValidationResult(false, 'Zone validation failed: ${e.toString()}');
    }
  }

  /// Perform actual zone validation using new two-tier system
  static Future<ZoneValidationResult> _performZoneValidation(LocationData locationData) async {
    try {
      final detectAccessLevelUseCase = sl<DetectAccessLevelUseCase>();
      final coordinates = LatLng(locationData.latitude, locationData.longitude);
      final params = DetectAccessLevelParams(coordinates: coordinates);

      final result = await detectAccessLevelUseCase.call(params);

      return result.fold(
        (failure) => ZoneValidationResult(false, 'Access level validation failed: ${failure.toString()}'),
        (accessResult) {
          switch (accessResult.accessLevel) {
            case AccessLevel.fullAccess:
              return ZoneValidationResult(true, 'Full access - delivery available');
            case AccessLevel.viewingOnly:
              return ZoneValidationResult(false, 'Viewing only - outside delivery zone');
            case AccessLevel.noAccess:
              return ZoneValidationResult(false, 'No access - outside service area');
          }
        },
      );
    } catch (e) {
      return ZoneValidationResult(false, 'Zone validation error: ${e.toString()}');
    }
  }
}

/// Result of basic checks
class BasicCheckResult {
  final bool canProceed;
  final String reason;

  BasicCheckResult(this.canProceed, this.reason);
}

/// Result of zone validation
class ZoneValidationResult {
  final bool isSuccess;
  final String message;

  ZoneValidationResult(this.isSuccess, this.message);
}
