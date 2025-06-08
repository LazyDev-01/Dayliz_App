import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/geofencing/delivery_zone.dart';
import '../models/geofencing/delivery_zone_model.dart';
import '../models/geofencing/town_model.dart';

/// Abstract interface for geofencing remote data source
abstract class GeofencingRemoteDataSource {
  Future<List<TownModel>> getActiveTowns();
  Future<TownModel> getTownById(String townId);
  Future<TownModel?> getTownByNameAndState(String name, String state);
  Future<List<DeliveryZoneModel>> getZonesForTown(String townId);
  Future<List<DeliveryZoneModel>> getAllActiveZones();
  Future<DeliveryZoneModel> getZoneById(String zoneId);
  
  Future<void> saveUserLocation({
    required String userId,
    required LatLng coordinates,
    required String addressText,
    String? formattedAddress,
    String? placeId,
    String? zoneId,
    String? townId,
    required String locationType,
    bool isPrimary = false,
  });
  
  Future<List<Map<String, dynamic>>> getUserLocations(String userId);
  Future<void> updatePrimaryLocation(String userId, String locationId);
  Future<void> deleteUserLocation(String locationId);
}

/// Supabase implementation of GeofencingRemoteDataSource
class GeofencingSupabaseDataSource implements GeofencingRemoteDataSource {
  final SupabaseClient client;

  GeofencingSupabaseDataSource({required this.client});

  @override
  Future<List<TownModel>> getActiveTowns() async {
    try {
      final response = await client
          .from('towns')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List<dynamic>)
          .map((json) => TownModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch active towns: $e');
    }
  }

  @override
  Future<TownModel> getTownById(String townId) async {
    try {
      final response = await client
          .from('towns')
          .select()
          .eq('id', townId)
          .single();

      return TownModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch town by ID: $e');
    }
  }

  @override
  Future<TownModel?> getTownByNameAndState(String name, String state) async {
    try {
      final response = await client
          .from('towns')
          .select()
          .eq('name', name)
          .eq('state', state)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      
      return TownModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch town by name and state: $e');
    }
  }

  @override
  Future<List<DeliveryZoneModel>> getZonesForTown(String townId) async {
    try {
      final response = await client
          .from('zones')
          .select()
          .eq('town_id', townId)
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('zone_number');

      return (response as List<dynamic>)
          .map((json) => DeliveryZoneModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch zones for town: $e');
    }
  }

  @override
  Future<List<DeliveryZoneModel>> getAllActiveZones() async {
    try {
      final response = await client
          .from('zones')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: false)
          .order('zone_number');

      return (response as List<dynamic>)
          .map((json) => DeliveryZoneModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all active zones: $e');
    }
  }

  @override
  Future<DeliveryZoneModel> getZoneById(String zoneId) async {
    try {
      final response = await client
          .from('zones')
          .select()
          .eq('id', zoneId)
          .single();

      return DeliveryZoneModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to fetch zone by ID: $e');
    }
  }

  @override
  Future<void> saveUserLocation({
    required String userId,
    required LatLng coordinates,
    required String addressText,
    String? formattedAddress,
    String? placeId,
    String? zoneId,
    String? townId,
    required String locationType,
    bool isPrimary = false,
  }) async {
    try {
      // If this is set as primary, first unset all other primary locations for this user
      if (isPrimary) {
        await client
            .from('user_locations')
            .update({'is_primary': false})
            .eq('user_id', userId);
      }

      // Insert the new location
      await client.from('user_locations').insert({
        'user_id': userId,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'address_text': addressText,
        'formatted_address': formattedAddress,
        'place_id': placeId,
        'zone_id': zoneId,
        'town_id': townId,
        'location_type': locationType,
        'is_primary': isPrimary,
        'is_active': true,
      });
    } catch (e) {
      throw Exception('Failed to save user location: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserLocations(String userId) async {
    try {
      final response = await client
          .from('user_locations')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch user locations: $e');
    }
  }

  @override
  Future<void> updatePrimaryLocation(String userId, String locationId) async {
    try {
      // First, unset all primary locations for this user
      await client
          .from('user_locations')
          .update({'is_primary': false})
          .eq('user_id', userId);

      // Then set the specified location as primary
      await client
          .from('user_locations')
          .update({'is_primary': true})
          .eq('id', locationId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update primary location: $e');
    }
  }

  @override
  Future<void> deleteUserLocation(String locationId) async {
    try {
      await client
          .from('user_locations')
          .update({'is_active': false})
          .eq('id', locationId);
    } catch (e) {
      throw Exception('Failed to delete user location: $e');
    }
  }
}
