import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/errors/exceptions.dart';

abstract class ZoneDataSource {
  /// Gets the zone ID for a given location
  Future<String?> getZoneForLocation(double latitude, double longitude);
  
  /// Checks if a location is within any delivery zone
  Future<bool> isLocationServiceable(double latitude, double longitude);
}

/// Supabase implementation of [ZoneDataSource]
class ZoneSupabaseDataSource implements ZoneDataSource {
  final SupabaseClient client;
  
  ZoneSupabaseDataSource({required this.client});
  
  @override
  Future<String?> getZoneForLocation(double latitude, double longitude) async {
    try {
      // Call a Supabase function that uses PostGIS to check if the point is in any zone
      final response = await client.rpc(
        'get_zone_for_point',
        params: {
          'lat': latitude,
          'lng': longitude,
        },
      );
      
      if (response != null && response['zone_id'] != null) {
        return response['zone_id'] as String;
      }
      
      return null;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Future<bool> isLocationServiceable(double latitude, double longitude) async {
    try {
      final zoneId = await getZoneForLocation(latitude, longitude);
      return zoneId != null;
    } catch (e) {
      return false;
    }
  }
}
