import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/datasources/location_local_data_source.dart';
import '../../data/repositories/simple_location_repository_impl.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/location_repository.dart';
import '../../domain/usecases/location/get_current_location_usecase.dart';
import '../../domain/usecases/location/location_setup_usecase.dart';
import '../../domain/usecases/location/request_location_permission_usecase.dart';
import '../../core/usecases/usecase.dart';

// Data Source Providers
final locationLocalDataSourceProvider = Provider<LocationLocalDataSource>((ref) {
  return LocationLocalDataSourceImpl();
});

// Repository Providers
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final localDataSource = ref.watch(locationLocalDataSourceProvider);
  return SimpleLocationRepositoryImpl(
    localDataSource: localDataSource,
  );
});

// Use Case Providers
final requestLocationPermissionUseCaseProvider = Provider<RequestLocationPermissionUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return RequestLocationPermissionUseCase(repository);
});

final checkLocationPermissionUseCaseProvider = Provider<CheckLocationPermissionUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return CheckLocationPermissionUseCase(repository);
});

final isLocationServiceEnabledUseCaseProvider = Provider<IsLocationServiceEnabledUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return IsLocationServiceEnabledUseCase(repository);
});

final getCurrentLocationUseCaseProvider = Provider<GetCurrentLocationUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return GetCurrentLocationUseCase(repository);
});

// Zone validation providers removed - no longer needed

final isLocationSetupCompletedUseCaseProvider = Provider<IsLocationSetupCompletedUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return IsLocationSetupCompletedUseCase(repository);
});

final markLocationSetupCompletedUseCaseProvider = Provider<MarkLocationSetupCompletedUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return MarkLocationSetupCompletedUseCase(repository);
});

final clearLocationSetupStatusUseCaseProvider = Provider<ClearLocationSetupStatusUseCase>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return ClearLocationSetupStatusUseCase(repository);
});

// State Providers
final locationPermissionProvider = FutureProvider<PermissionStatus>((ref) async {
  final useCase = ref.watch(checkLocationPermissionUseCaseProvider);
  final result = await useCase(NoParams());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (permission) => permission,
  );
});

final currentLocationProvider = FutureProvider<LocationCoordinates>((ref) async {
  final useCase = ref.watch(getCurrentLocationUseCaseProvider);
  final result = await useCase(NoParams());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (coordinates) => coordinates,
  );
});

// Zone validation provider removed - no longer needed

final isLocationSetupCompletedProvider = Provider<bool>((ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.isLocationSetupCompleted();
});
