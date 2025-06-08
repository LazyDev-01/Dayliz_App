import 'package:dartz/dartz.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/failures.dart';
import '../entities/zone.dart';

/// Repository interface for location-related operations
abstract class LocationRepository {
  /// Check if location services are enabled on the device
  Future<Either<Failure, bool>> isLocationServiceEnabled();

  /// Check current location permission status
  Future<Either<Failure, PermissionStatus>> checkLocationPermission();

  /// Request location permission from user
  Future<Either<Failure, PermissionStatus>> requestLocationPermission();

  /// Get current GPS coordinates
  Future<Either<Failure, LocationCoordinates>> getCurrentLocation();

  /// Validate if coordinates fall within any delivery zone
  Future<Either<Failure, ZoneValidationResult>> validateDeliveryZone(
    LocationCoordinates coordinates,
  );

  /// Get zone information by zone ID
  Future<Either<Failure, Zone>> getZoneById(String zoneId);

  /// Check if location setup is completed for current session
  bool isLocationSetupCompleted();

  /// Mark location setup as completed for current session
  void markLocationSetupCompleted();

  /// Clear location setup status (for app restart)
  void clearLocationSetupStatus();
}
