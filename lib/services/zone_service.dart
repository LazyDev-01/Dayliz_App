import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/models/zone.dart';
import 'package:dayliz_app/services/user_service.dart';

/// Service that handles zone operations using Supabase.
class ZoneService {
  static final ZoneService _instance = ZoneService._internal();
  static ZoneService get instance => _instance;
  
  late final SupabaseClient _client;
  late final UserService _userService;
  
  /// Private constructor
  ZoneService._internal() {
    _client = Supabase.instance.client;
    _userService = UserService.instance;
  }
  
  /// Get all active zones
  Future<List<Zone>> getZones() async {
    try {
      // Check if user is authenticated
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in getZones: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Get active zones
      final response = await _client
          .from('zones')
          .select()
          .eq('is_active', true);
      
      debugPrint('API GET response from zones: Data length: ${response.length}');
      
      return response.map<Zone>((json) => Zone.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting zones: $e');
      return [];
    }
  }
  
  /// Get a specific zone by ID
  Future<Zone?> getZoneById(String zoneId) async {
    try {
      final response = await _client
          .from('zones')
          .select()
          .eq('id', zoneId)
          .single();
      
      return Zone.fromJson(response);
    } catch (e) {
      debugPrint('Error getting zone by ID: $e');
      return null;
    }
  }
  
  /// Get zone for specific coordinates using the server-side function
  Future<Zone?> getZoneForCoordinates(double latitude, double longitude) async {
    try {
      // Use the PostgreSQL function we created
      final response = await _client
          .rpc('get_zone_id_for_point', params: {
            'lat': latitude,
            'lng': longitude,
          });
      
      if (response == null) {
        debugPrint('No zone found for coordinates: $latitude, $longitude');
        return null;
      }
      
      // Get the zone details
      final zoneId = response as String;
      debugPrint('Found zone ID $zoneId for coordinates: $latitude, $longitude');
      
      return await getZoneById(zoneId);
    } catch (e) {
      debugPrint('Error getting zone for coordinates: $e');
      return null;
    }
  }

  // Find a zone based on latitude and longitude
  Future<Zone?> findZoneByLocation(double latitude, double longitude) async {
    try {
      // In a real implementation, you would have a PostGIS query that uses
      // ST_Contains to check if the point is within any of the zone polygons
      // For now, we'll just fetch all zones and check locally
      final zones = await getZones();
      
      // Find the first zone that contains the point
      return zones.firstWhere(
        (zone) => zone.containsPoint(latitude, longitude),
        orElse: () => throw Exception('No zone found for this location'),
      );
    } catch (e) {
      print('Error finding zone by location: $e');
      return null;
    }
  }
} 