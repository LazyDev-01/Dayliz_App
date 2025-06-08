import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/zone.dart';

/// Repository interface for zone-related operations
abstract class ZoneRepository {
  /// Get zone for specific coordinates
  Future<Either<Failure, Zone?>> getZoneForLocation(
    double latitude,
    double longitude,
  );

  /// Get zone by ID
  Future<Either<Failure, Zone>> getZoneById(String zoneId);

  /// Get all active zones
  Future<Either<Failure, List<Zone>>> getActiveZones();

  /// Check if coordinates are within any delivery zone
  Future<Either<Failure, bool>> isLocationInDeliveryZone(
    double latitude,
    double longitude,
  );

  /// Get nearest zone to coordinates (even if not within delivery area)
  Future<Either<Failure, Zone?>> getNearestZone(
    double latitude,
    double longitude,
  );
}
