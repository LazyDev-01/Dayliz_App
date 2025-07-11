import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/early_location_checker.dart';
import '../../core/services/location_service.dart';

/// State for location readiness
class LocationReadinessState {
  final LocationReadinessStatus status;
  final LocationData? locationData;
  final String? errorMessage;
  final bool isChecking;
  final bool hasChecked;

  const LocationReadinessState({
    this.status = LocationReadinessStatus.needsSetup,
    this.locationData,
    this.errorMessage,
    this.isChecking = false,
    this.hasChecked = false,
  });

  LocationReadinessState copyWith({
    LocationReadinessStatus? status,
    LocationData? locationData,
    String? errorMessage,
    bool? isChecking,
    bool? hasChecked,
    bool clearError = false,
    bool clearLocationData = false,
  }) {
    return LocationReadinessState(
      status: status ?? this.status,
      locationData: clearLocationData ? null : (locationData ?? this.locationData),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isChecking: isChecking ?? this.isChecking,
      hasChecked: hasChecked ?? this.hasChecked,
    );
  }

  bool get isReady => status == LocationReadinessStatus.ready;
  bool get shouldGoToLocationAccess => status == LocationReadinessStatus.needsSetup || 
                                      status == LocationReadinessStatus.error ||
                                      status == LocationReadinessStatus.timeout;
  bool get shouldGoToServiceUnavailable => status == LocationReadinessStatus.outOfService;

  @override
  String toString() => 'LocationReadinessState(status: $status, isChecking: $isChecking, hasChecked: $hasChecked, hasLocation: ${locationData != null})';
}

/// Notifier for location readiness
class LocationReadinessNotifier extends StateNotifier<LocationReadinessState> {
  LocationReadinessNotifier() : super(const LocationReadinessState());

  /// Perform early location check for app startup optimization
  Future<void> performEarlyLocationCheck() async {
    if (state.isChecking || state.hasChecked) {
      debugPrint('🔄 LocationReadiness: Check already performed or in progress');
      return;
    }

    debugPrint('🚀 LocationReadiness: Starting early location check...');
    
    state = state.copyWith(
      isChecking: true,
      clearError: true,
    );

    try {
      final result = await EarlyLocationChecker.checkLocationReadiness();
      
      debugPrint('✅ LocationReadiness: Check completed - ${result.toString()}');
      
      state = state.copyWith(
        status: result.status,
        locationData: result.locationData,
        errorMessage: result.errorMessage,
        isChecking: false,
        hasChecked: true,
      );

    } catch (e) {
      debugPrint('❌ LocationReadiness: Error during early check - $e');
      
      state = state.copyWith(
        status: LocationReadinessStatus.error,
        errorMessage: 'Failed to check location readiness: ${e.toString()}',
        isChecking: false,
        hasChecked: true,
      );
    }
  }

  /// Reset the state for fresh check
  void reset() {
    debugPrint('🔄 LocationReadiness: Resetting state');
    state = const LocationReadinessState();
  }

  /// Get cached location data if available
  LocationData? getCachedLocationData() {
    return state.locationData;
  }

  /// Check if location is ready without performing new check
  bool isLocationReady() {
    return state.hasChecked && state.isReady;
  }

  /// Get the route that should be navigated to based on current state
  String? getTargetRoute() {
    if (!state.hasChecked) {
      return null; // Still checking or not checked yet
    }

    if (state.isReady) {
      return null; // Can proceed to intended route
    } else if (state.shouldGoToServiceUnavailable) {
      return '/service-not-available';
    } else if (state.shouldGoToLocationAccess) {
      return '/location-access';
    }

    return '/location-access'; // Default fallback
  }
}

/// Provider for location readiness
final locationReadinessProvider = StateNotifierProvider<LocationReadinessNotifier, LocationReadinessState>((ref) {
  return LocationReadinessNotifier();
});

/// Provider for quick location readiness check
final quickLocationCheckProvider = FutureProvider<LocationReadinessResult>((ref) async {
  return await EarlyLocationChecker.checkLocationReadiness();
});
