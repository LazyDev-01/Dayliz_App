import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/zone.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_local_data_source.dart';

/// Simplified location repository implementation without zone validation
class SimpleLocationRepositoryImpl implements LocationRepository {
  final LocationLocalDataSource localDataSource;

  SimpleLocationRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, PermissionStatus>> requestLocationPermission() async {
    try {
      final permission = await Permission.location.request();
      return Right(permission);
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to request location permission: $e'));
    }
  }

  @override
  Future<Either<Failure, PermissionStatus>> checkLocationPermission() async {
    try {
      final permission = await Permission.location.status;
      return Right(permission);
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to check location permission: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isLocationServiceEnabled() async {
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      return Right(isEnabled);
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to check location service: $e'));
    }
  }

  @override
  Future<Either<Failure, LocationCoordinates>> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final coordinates = LocationCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      return Right(coordinates);
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to get current location: $e'));
    }
  }

  @override
  Future<Either<Failure, ZoneValidationResult>> validateDeliveryZone(
    LocationCoordinates coordinates,
  ) async {
    // Zone validation removed - always return valid
    return Right(ZoneValidationResult.valid(
      zone: const Zone(
        id: 'default',
        name: 'Default Zone',
        isActive: true,
      ),
      coordinates: coordinates,
    ));
  }

  @override
  Future<Either<Failure, ZoneValidationResult>> getLocationAndValidateZone() async {
    try {
      // Get current location
      final locationResult = await getCurrentLocation();

      return locationResult.fold(
        (failure) => Left(failure),
        (coordinates) async {
          // Skip zone validation - always return valid
          return Right(ZoneValidationResult.valid(
            zone: const Zone(
              id: 'default',
              name: 'Default Zone',
              isActive: true,
            ),
            coordinates: coordinates,
          ));
        },
      );
    } catch (e) {
      return Left(LocationFailure(message: 'Failed to get location: $e'));
    }
  }

  @override
  bool isLocationSetupCompleted() {
    return localDataSource.isLocationSetupCompleted();
  }

  @override
  Future<void> markLocationSetupCompleted() async {
    localDataSource.markLocationSetupCompleted();
  }

  @override
  Future<void> clearLocationSetupStatus() async {
    localDataSource.clearLocationSetupStatus();
  }

  @override
  Future<Either<Failure, Zone>> getZoneById(String zoneId) async {
    // Zone functionality removed - return default zone
    return Right(const Zone(
      id: 'default',
      name: 'Default Zone',
      isActive: true,
    ));
  }
}

/// Custom failure for location-related errors
class LocationFailure extends Failure {
  const LocationFailure({String message = 'Location error occurred'}) : super(message);
}
