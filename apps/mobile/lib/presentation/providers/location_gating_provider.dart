import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';
import '../../core/services/connectivity_checker.dart';
import '../../domain/entities/geofencing/zone_detection_result.dart';
import '../../domain/entities/geofencing/delivery_zone.dart';
import '../../domain/entities/geofencing/enhanced_zone_detection_result.dart';
import '../../domain/usecases/geofencing/detect_access_level_usecase.dart';
import '../../di/dependency_injection.dart';


/// Location gating status enum
enum LocationGatingStatus {
  notStarted,
  gpsDisabled,           // GPS/Location service is disabled
  gpsEnabling,           // User is enabling GPS (opened settings)
  permissionRequesting,  // Requesting app permission
  locationDetecting,     // Getting GPS coordinates
  zoneValidating,        // Validating coordinates against zones
  completed,             // Success - can proceed to app with full access
  viewingModeReady,      // In city but outside delivery zone - viewing only
  failed,                // Failed to get GPS coordinates
  serviceNotAvailable,   // Outside delivery zones
}

/// Location gating state
class LocationGatingState {
  final LocationGatingStatus status;
  final bool isLocationRequired;
  final bool isLocationPermissionGranted;
  final LocationData? currentLocationData;
  final ZoneDetectionResult? zoneDetectionResult;
  final bool isLoading;
  final String? errorMessage;
  final bool hasCompletedInSession;
  final AccessLevel accessLevel;
  final bool canOrder;
  final bool isViewingMode;

  const LocationGatingState({
    this.status = LocationGatingStatus.notStarted,
    this.isLocationRequired = true,
    this.isLocationPermissionGranted = false,
    this.currentLocationData,
    this.zoneDetectionResult,
    this.isLoading = false,
    this.errorMessage,
    this.hasCompletedInSession = false,
    this.accessLevel = AccessLevel.noAccess,
    this.canOrder = false,
    this.isViewingMode = false,
  });

  LocationGatingState copyWith({
    LocationGatingStatus? status,
    bool? isLocationRequired,
    bool? isLocationPermissionGranted,
    LocationData? currentLocationData,
    ZoneDetectionResult? zoneDetectionResult,
    bool? isLoading,
    String? errorMessage,
    bool? hasCompletedInSession,
    AccessLevel? accessLevel,
    bool? canOrder,
    bool? isViewingMode,
    bool clearError = false,
    bool clearLocationData = false,
    bool clearZoneResult = false,
  }) {
    return LocationGatingState(
      status: status ?? this.status,
      isLocationRequired: isLocationRequired ?? this.isLocationRequired,
      isLocationPermissionGranted: isLocationPermissionGranted ?? this.isLocationPermissionGranted,
      currentLocationData: clearLocationData ? null : (currentLocationData ?? this.currentLocationData),
      zoneDetectionResult: clearZoneResult ? null : (zoneDetectionResult ?? this.zoneDetectionResult),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasCompletedInSession: hasCompletedInSession ?? this.hasCompletedInSession,
      accessLevel: accessLevel ?? this.accessLevel,
      canOrder: canOrder ?? this.canOrder,
      isViewingMode: isViewingMode ?? this.isViewingMode,
    );
  }

  /// Check if location gating is completed and user can proceed
  bool get canProceedToApp => hasCompletedInSession &&
                              (status == LocationGatingStatus.completed ||
                               status == LocationGatingStatus.viewingModeReady) &&
                              (accessLevel == AccessLevel.fullAccess ||
                               accessLevel == AccessLevel.viewingOnly);

  /// Check if service is available in current location
  bool get isServiceAvailable => zoneDetectionResult?.isSuccess ?? false;

  @override
  String toString() {
    return 'LocationGatingState(status: $status, canProceed: $canProceedToApp, hasLocation: ${currentLocationData != null}, hasZone: ${zoneDetectionResult != null})';
  }
}

/// Location gating notifier
class LocationGatingNotifier extends StateNotifier<LocationGatingState> {
  final LocationService _locationService;

  LocationGatingNotifier({
    required LocationService locationService,
  }) : _locationService = locationService,
       super(const LocationGatingState());

  /// Initialize location gating - check if already completed in session
  void initialize() {
    // For now, always require location setup
    // In future, this could check shared preferences for persistent state
    state = state.copyWith(
      status: LocationGatingStatus.notStarted,
      isLocationRequired: true,
    );
  }

  /// Request location permission and detect location
  /// This is the main method that handles the complete flow
  Future<void> requestLocationPermissionWithDialog() async {

    try {
      // Set initial loading state
      state = state.copyWith(
        status: LocationGatingStatus.permissionRequesting,
        isLoading: true,
        clearError: true,
      );

      // Step 0: Check network connectivity (for zone validation later)
      debugPrint('🌐 LocationGating: Checking network connectivity...');
      final hasConnection = await ConnectivityChecker.hasConnection();
      if (!hasConnection) {
        debugPrint('⚠️ LocationGating: No network connection - proceeding with GPS-only mode');
        // Continue with GPS-only mode, we'll handle zone validation later
      }

      // Step 1: Check current permission status
      LocationPermission permission = await _locationService.checkLocationPermission();

      // Step 2: Request permission if needed (this shows Android dialog for new permissions)
      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestLocationPermission();
      }

      // Check if permission was denied
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: LocationGatingStatus.failed,
          isLoading: false,
          errorMessage: permission == LocationPermission.deniedForever
            ? 'Location permission is permanently denied. Please enable it in app settings.'
            : 'Location permission is required to check service availability in your area.',
        );
        return;
      }

      // Step 3: Check if GPS/Location services are enabled
      final isGPSEnabled = await _locationService.isLocationServiceEnabled();

      if (!isGPSEnabled) {
        // Show Android's system GPS enable dialog
        final gpsEnabled = await _locationService.requestLocationService();

        if (!gpsEnabled) {
          state = state.copyWith(
            status: LocationGatingStatus.gpsDisabled,
            isLoading: false,
            errorMessage: 'Location services are required. Please enable location services to continue.',
          );
          return;
        }

      }

      // Step 3: Start location detection
      state = state.copyWith(
        status: LocationGatingStatus.locationDetecting,
        isLoading: true,
      );

      // First try to get coordinates only (no internet required)
      LocationData? locationData = await _locationService.getCurrentLocationCoordinatesOnly();

      // If we got coordinates, try to get address (requires internet)
      if (locationData != null) {
        final locationWithAddress = await _locationService.getCurrentLocationWithAddress();
        if (locationWithAddress != null) {
          locationData = locationWithAddress; // Use full address if available
        }
        // If address fetch fails, continue with coordinates-only data
      }

      if (locationData == null) {
        state = state.copyWith(
          status: LocationGatingStatus.failed,
          isLoading: false,
          errorMessage: 'Failed to retrieve your current GPS coordinates. Please try again.',
        );
        return;
      }

      // Step 4: Validate zone
      await _validateZone(locationData);

    } catch (e) {
      state = state.copyWith(
        status: LocationGatingStatus.failed,
        isLoading: false,
        errorMessage: 'Failed to get your location: ${e.toString()}',
      );
    }
  }

  /// Request location permission and get current location (legacy method)
  /// Use requestLocationPermissionWithDialog() for new implementations
  Future<void> requestLocationAndDetect() async {
    // Redirect to the new method
    await requestLocationPermissionWithDialog();
  }



  /// Validate zone for manual address entry
  Future<void> validateManualAddress(String address, double latitude, double longitude) async {
    
    state = state.copyWith(
      status: LocationGatingStatus.zoneValidating,
      isLoading: true,
      clearError: true,
    );

    try {
      final locationData = LocationData(
        latitude: latitude,
        longitude: longitude,
        address: address,
        city: 'Manual Entry',
        state: 'Manual Entry',
        postalCode: '000000',
        country: 'India',
      );

      await _validateZone(locationData);
    } catch (e) {
      state = state.copyWith(
        status: LocationGatingStatus.failed,
        isLoading: false,
        errorMessage: 'Failed to validate address: ${e.toString()}',
      );
    }
  }

  /// Internal method to validate zone for given location data with two-tier validation
  Future<void> _validateZone(LocationData locationData) async {

    state = state.copyWith(
      status: LocationGatingStatus.zoneValidating,
      currentLocationData: locationData,
      isLoading: true,
    );

    try {
      // Two-tier validation: City boundaries first, then delivery zones
      final detectAccessLevelUseCase = sl<DetectAccessLevelUseCase>();
      final coordinates = LatLng(locationData.latitude, locationData.longitude);



      final result = await detectAccessLevelUseCase(DetectAccessLevelParams(coordinates: coordinates));

      result.fold(
        (failure) {
          debugPrint('❌ LocationGating: Access level detection failed: ${failure.message}');
          state = state.copyWith(
            status: LocationGatingStatus.failed,
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (enhancedResult) {
          debugPrint('✅ LocationGating: Access level detected: ${enhancedResult.accessLevel}');

          // Note: Viewing mode will be updated by the UI layer when it reads the state

          switch (enhancedResult.accessLevel) {
            case AccessLevel.fullAccess:
              debugPrint('✅ LocationGating: Full access - delivery available');
              state = state.copyWith(
                status: LocationGatingStatus.completed,
                isLoading: false,
                hasCompletedInSession: true,
                accessLevel: AccessLevel.fullAccess,
                canOrder: true,
                isViewingMode: false,
                clearError: true,
              );
              break;

            case AccessLevel.viewingOnly:
              debugPrint('👁️ LocationGating: Viewing mode - in city but no delivery');
              state = state.copyWith(
                status: LocationGatingStatus.viewingModeReady,
                isLoading: false,
                hasCompletedInSession: true,
                accessLevel: AccessLevel.viewingOnly,
                canOrder: false,
                isViewingMode: true,
                clearError: true,
              );
              break;

            case AccessLevel.noAccess:
              state = state.copyWith(
                status: LocationGatingStatus.serviceNotAvailable,
                isLoading: false,
                accessLevel: AccessLevel.noAccess,
                canOrder: false,
                isViewingMode: false,
                errorMessage: enhancedResult.message,
              );
              break;
          }
        },
      );
    } catch (e) {
      state = state.copyWith(
        status: LocationGatingStatus.failed,
        isLoading: false,
        errorMessage: 'Failed to validate location: ${e.toString()}',
      );
    }
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Open app settings
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }

  /// Reset location gating state
  void reset() {

    state = const LocationGatingState();
  }

  /// Mark location as completed with early check results
  void markLocationAsCompleted(LocationData locationData) {


    state = state.copyWith(
      status: LocationGatingStatus.completed,
      currentLocationData: locationData,
      hasCompletedInSession: true,
      isLoading: false,
      clearError: true,
    );


  }

  /// Skip location gating (for testing or fallback)
  void skip() {

    state = state.copyWith(
      status: LocationGatingStatus.completed,
      hasCompletedInSession: true,
      isLocationRequired: false,
    );
  }

  /// Retry the current operation with improved error handling
  Future<void> retry() async {
    debugPrint('🔄 LocationGating: Retry requested for status: ${state.status}');

    // Reset error state first
    state = state.copyWith(
      clearError: true,
      isLoading: false,
      status: LocationGatingStatus.notStarted, // Reset to initial state
    );

    // Add a small delay to ensure UI updates
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      switch (state.status) {
        case LocationGatingStatus.failed:
        case LocationGatingStatus.gpsDisabled:
        case LocationGatingStatus.notStarted:
          // Always restart the complete flow for failed states
          debugPrint('🔄 LocationGating: Restarting complete location flow');
          await requestLocationPermissionWithDialog();
          break;
        case LocationGatingStatus.serviceNotAvailable:
          // For service not available, also restart (user might have moved)
          debugPrint('🔄 LocationGating: Retrying location detection for service availability');
          await requestLocationPermissionWithDialog();
          break;
        default:
          // For other states, restart the process
          debugPrint('🔄 LocationGating: Default retry - restarting location flow');
          await requestLocationPermissionWithDialog();
          break;
      }
    } catch (e) {
      debugPrint('❌ LocationGating: Retry failed: $e');
      state = state.copyWith(
        status: LocationGatingStatus.failed,
        isLoading: false,
        errorMessage: 'Retry failed: ${e.toString()}',
      );
    }
  }
}

/// Provider for location gating
final locationGatingProvider = StateNotifierProvider<LocationGatingNotifier, LocationGatingState>((ref) {
  return LocationGatingNotifier(
    locationService: LocationService(),
  );
});

/// Convenience provider to check if location gating is required
final isLocationGatingRequiredProvider = Provider<bool>((ref) {
  final state = ref.watch(locationGatingProvider);
  return state.isLocationRequired && !state.hasCompletedInSession;
});

/// Convenience provider to check if user can proceed to app
final canProceedToAppProvider = Provider<bool>((ref) {
  final state = ref.watch(locationGatingProvider);
  return state.canProceedToApp;
});
