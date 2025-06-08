import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/geofencing/delivery_zone.dart';
import '../entities/geofencing/town.dart';
import '../entities/geofencing/zone_detection_result.dart';

/// Repository interface for geofencing operations
abstract class GeofencingRepository {
  /// Get all active towns
  Future<Either<Failure, List<Town>>> getActiveTowns();

  /// Get a specific town by ID
  Future<Either<Failure, Town>> getTownById(String townId);

  /// Get a town by name and state
  Future<Either<Failure, Town?>> getTownByNameAndState(String name, String state);

  /// Get all active zones for a specific town
  Future<Either<Failure, List<DeliveryZone>>> getZonesForTown(String townId);

  /// Get all active zones (across all towns)
  Future<Either<Failure, List<DeliveryZone>>> getAllActiveZones();

  /// Get a specific zone by ID
  Future<Either<Failure, DeliveryZone>> getZoneById(String zoneId);

  /// Detect which zone (if any) contains the given coordinates
  Future<Either<Failure, ZoneDetectionResult>> detectZone(LatLng coordinates);

  /// Find the closest zone to the given coordinates (even if outside all zones)
  Future<Either<Failure, DeliveryZone?>> findClosestZone(LatLng coordinates);

  /// Check if delivery is available at the given coordinates
  Future<Either<Failure, bool>> isDeliveryAvailable(LatLng coordinates);

  /// Save user's location and detected zone
  Future<Either<Failure, void>> saveUserLocation({
    required String userId,
    required LatLng coordinates,
    required String addressText,
    String? formattedAddress,
    String? placeId,
    String? zoneId,
    String? townId,
    required String locationType, // 'gps', 'manual', 'search'
    bool isPrimary = false,
  });

  /// Get user's saved locations
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserLocations(String userId);

  /// Update user's primary location
  Future<Either<Failure, void>> updatePrimaryLocation(String userId, String locationId);

  /// Delete a user location
  Future<Either<Failure, void>> deleteUserLocation(String locationId);
}
