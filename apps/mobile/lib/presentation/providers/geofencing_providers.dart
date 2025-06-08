import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/geofencing_remote_data_source.dart';
import '../../data/repositories/geofencing_repository_impl.dart';
import '../../domain/entities/geofencing/delivery_zone.dart';
import '../../domain/entities/geofencing/town.dart';
import '../../domain/entities/geofencing/zone_detection_result.dart';
import '../../domain/repositories/geofencing_repository.dart';
import '../../domain/usecases/geofencing/detect_zone_usecase.dart';
import '../../domain/usecases/geofencing/save_user_location_usecase.dart';
import 'supabase_providers.dart';

// =====================================================
// DATA SOURCE PROVIDERS
// =====================================================

final geofencingRemoteDataSourceProvider = Provider<GeofencingRemoteDataSource>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return GeofencingSupabaseDataSource(client: supabaseClient);
});

// =====================================================
// REPOSITORY PROVIDERS
// =====================================================

final geofencingRepositoryProvider = Provider<GeofencingRepository>((ref) {
  final remoteDataSource = ref.watch(geofencingRemoteDataSourceProvider);
  return GeofencingRepositoryImpl(remoteDataSource: remoteDataSource);
});

// =====================================================
// USE CASE PROVIDERS
// =====================================================

final detectZoneUseCaseProvider = Provider<DetectZoneUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return DetectZoneUseCase(repository);
});

final checkDeliveryAvailabilityUseCaseProvider = Provider<CheckDeliveryAvailabilityUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return CheckDeliveryAvailabilityUseCase(repository);
});

final findClosestZoneUseCaseProvider = Provider<FindClosestZoneUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return FindClosestZoneUseCase(repository);
});

final saveUserLocationUseCaseProvider = Provider<SaveUserLocationUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return SaveUserLocationUseCase(repository);
});

final getUserLocationsUseCaseProvider = Provider<GetUserLocationsUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return GetUserLocationsUseCase(repository);
});

final updatePrimaryLocationUseCaseProvider = Provider<UpdatePrimaryLocationUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return UpdatePrimaryLocationUseCase(repository);
});

final deleteUserLocationUseCaseProvider = Provider<DeleteUserLocationUseCase>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return DeleteUserLocationUseCase(repository);
});

// =====================================================
// STATE PROVIDERS
// =====================================================

/// Provider for zone detection result
final zoneDetectionProvider = FutureProvider.family<ZoneDetectionResult, LatLng>((ref, coordinates) async {
  final useCase = ref.watch(detectZoneUseCaseProvider);
  final result = await useCase(DetectZoneParams(coordinates: coordinates));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (detectionResult) => detectionResult,
  );
});

/// Provider for delivery availability check
final deliveryAvailabilityProvider = FutureProvider.family<bool, LatLng>((ref, coordinates) async {
  final useCase = ref.watch(checkDeliveryAvailabilityUseCaseProvider);
  final result = await useCase(DetectZoneParams(coordinates: coordinates));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (isAvailable) => isAvailable,
  );
});

/// Provider for closest zone
final closestZoneProvider = FutureProvider.family<DeliveryZone?, LatLng>((ref, coordinates) async {
  final useCase = ref.watch(findClosestZoneUseCaseProvider);
  final result = await useCase(DetectZoneParams(coordinates: coordinates));

  return result.fold(
    (failure) => throw Exception(failure.message),
    (zone) => zone,
  );
});

/// Provider for user locations
final userLocationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final useCase = ref.watch(getUserLocationsUseCaseProvider);
  final result = await useCase(userId);

  return result.fold(
    (failure) => throw Exception(failure.message),
    (locations) => locations,
  );
});

/// Provider for all active zones
final allActiveZonesProvider = FutureProvider<List<DeliveryZone>>((ref) async {
  final repository = ref.watch(geofencingRepositoryProvider);
  final result = await repository.getAllActiveZones();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (zones) => zones,
  );
});

/// Provider for active towns
final activeTownsProvider = FutureProvider<List<Town>>((ref) async {
  final repository = ref.watch(geofencingRepositoryProvider);
  final result = await repository.getActiveTowns();

  return result.fold(
    (failure) => throw Exception(failure.message),
    (towns) => towns,
  );
});

// =====================================================
// NOTIFIER PROVIDERS (for mutable state)
// =====================================================

/// State notifier for managing current user location and zone
class LocationStateNotifier extends StateNotifier<LocationState> {
  final GeofencingRepository _repository;

  LocationStateNotifier(this._repository) : super(const LocationState.initial());

  /// Detect zone for given coordinates
  Future<void> detectZone(LatLng coordinates) async {
    state = const LocationState.loading();

    final result = await _repository.detectZone(coordinates);

    result.fold(
      (failure) => state = LocationState.error(failure.message),
      (detectionResult) => state = LocationState.detected(detectionResult),
    );
  }

  /// Save current location
  Future<void> saveLocation({
    required String userId,
    required LatLng coordinates,
    required String addressText,
    String? formattedAddress,
    String? placeId,
    required String locationType,
    bool isPrimary = false,
  }) async {
    if (state is! LocationDetected) return;

    final currentState = state as LocationDetected;

    final result = await _repository.saveUserLocation(
      userId: userId,
      coordinates: coordinates,
      addressText: addressText,
      formattedAddress: formattedAddress,
      placeId: placeId,
      zoneId: currentState.detectionResult.zone?.id,
      townId: currentState.detectionResult.town?.id,
      locationType: locationType,
      isPrimary: isPrimary,
    );

    result.fold(
      (failure) => state = LocationState.error(failure.message),
      (_) => state = LocationState.saved(currentState.detectionResult),
    );
  }

  /// Clear current state
  void clear() {
    state = const LocationState.initial();
  }
}

/// Provider for location state notifier
final locationStateNotifierProvider = StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
  final repository = ref.watch(geofencingRepositoryProvider);
  return LocationStateNotifier(repository);
});

// =====================================================
// STATE CLASSES
// =====================================================

/// State for location detection and management
abstract class LocationState {
  const LocationState();

  const factory LocationState.initial() = LocationInitial;
  const factory LocationState.loading() = LocationLoading;
  const factory LocationState.detected(ZoneDetectionResult detectionResult) = LocationDetected;
  const factory LocationState.saved(ZoneDetectionResult detectionResult) = LocationSaved;
  const factory LocationState.error(String message) = LocationError;
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationDetected extends LocationState {
  final ZoneDetectionResult detectionResult;
  const LocationDetected(this.detectionResult);
}

class LocationSaved extends LocationState {
  final ZoneDetectionResult detectionResult;
  const LocationSaved(this.detectionResult);
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
}
