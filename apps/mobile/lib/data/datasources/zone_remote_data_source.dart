import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/exceptions.dart';
import '../models/zone_model.dart';

/// Abstract interface for zone remote data source
abstract class ZoneRemoteDataSource {
  /// Get zone for specific coordinates using PostGIS
  Future<ZoneModel?> getZoneForLocation(double latitude, double longitude);

  /// Get zone by ID
  Future<ZoneModel> getZoneById(String zoneId);

  /// Get all active zones
  Future<List<ZoneModel>> getActiveZones();

  /// Check if coordinates are within any delivery zone
  Future<bool> isLocationInDeliveryZone(double latitude, double longitude);

  /// Get nearest zone to coordinates
  Future<ZoneModel?> getNearestZone(double latitude, double longitude);
}

/// Supabase implementation of zone remote data source
class ZoneSupabaseRemoteDataSource implements ZoneRemoteDataSource {
  final SupabaseClient client;

  ZoneSupabaseRemoteDataSource({required this.client});

  @override
  Future<ZoneModel?> getZoneForLocation(double latitude, double longitude) async {
    try {
      // Use the existing get_zone_for_point function
      final response = await client.rpc(
        'get_zone_for_point',
        params: {
          'lat': latitude,
          'lng': longitude,
        },
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      // The function returns zone ID, now get full zone details
      final zoneId = response[0]['id'] as String?;
      if (zoneId == null) return null;

      return await getZoneById(zoneId);
    } catch (e) {
      throw ServerException(message: 'Failed to get zone for location: $e');
    }
  }

  @override
  Future<ZoneModel> getZoneById(String zoneId) async {
    try {
      final response = await client
          .from('zones')
          .select()
          .eq('id', zoneId)
          .eq('is_active', true)
          .single();

      return ZoneModel.fromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to get zone by ID: $e');
    }
  }

  @override
  Future<List<ZoneModel>> getActiveZones() async {
    try {
      final response = await client
          .from('zones')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => ZoneModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to get active zones: $e');
    }
  }

  @override
  Future<bool> isLocationInDeliveryZone(double latitude, double longitude) async {
    try {
      final zone = await getZoneForLocation(latitude, longitude);
      return zone != null;
    } catch (e) {
      throw ServerException(message: 'Failed to check location in delivery zone: $e');
    }
  }

  @override
  Future<ZoneModel?> getNearestZone(double latitude, double longitude) async {
    try {
      // Use the find_nearest_zone function if it exists, otherwise fallback
      final response = await client.rpc(
        'find_nearest_zone',
        params: {
          'lat': latitude,
          'lng': longitude,
        },
      );

      if (response == null || response.isEmpty) {
        return null;
      }

      final zoneId = response[0]['zone_id'] as String?;
      if (zoneId == null) return null;

      return await getZoneById(zoneId);
    } catch (e) {
      // Fallback: get all zones and find the first one (simplified)
      try {
        final zones = await getActiveZones();
        return zones.isNotEmpty ? zones.first : null;
      } catch (fallbackError) {
        throw ServerException(message: 'Failed to get nearest zone: $e');
      }
    }
  }
}
