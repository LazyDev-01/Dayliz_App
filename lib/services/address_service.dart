import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:flutter/services.dart';

/// Service that handles address operations using Supabase.
class AddressService {
  static final AddressService _instance = AddressService._internal();
  static AddressService get instance => _instance;
  
  late final SupabaseClient _client;
  
  /// Private constructor
  AddressService._internal() {
    _client = Supabase.instance.client;
  }
  
  /// Get all addresses for the current user
  Future<List<Address>> getAddresses() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      
      return (response as List).map((item) => Address.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error getting addresses: $e');
      return [];
    }
  }
  
  /// Add a new address
  Future<Address?> addAddress(Address address) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // If this is the default address, update all other addresses
      if (address.isDefault) {
        await _clearDefaultAddresses();
      }
      
      // Prepare data for inserting into the database
      final data = address.toJson();
      data.remove('id'); // Remove ID for new addresses
      data['user_id'] = userId; // Add user ID
      
      // Insert the address
      final response = await _client
          .from('user_addresses')
          .insert(data)
          .select()
          .single();
      
      return Address.fromJson(response);
    } catch (e) {
      debugPrint('Error adding address: $e');
      rethrow;
    }
  }
  
  /// Update an existing address
  Future<Address?> updateAddress(Address address) async {
    try {
      if (address.id == null) {
        throw Exception('Address ID is required for updates');
      }
      
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // If this is the default address, update all other addresses
      if (address.isDefault) {
        await _clearDefaultAddresses();
      }
      
      // Prepare data for updating in the database
      final data = address.toJson();
      data['user_id'] = userId; // Add user ID
      
      // Update the address
      final response = await _client
          .from('user_addresses')
          .update(data)
          .eq('id', address.id)
          .eq('user_id', userId)
          .select()
          .single();
      
      return Address.fromJson(response);
    } catch (e) {
      debugPrint('Error updating address: $e');
      rethrow;
    }
  }
  
  /// Delete an address
  Future<void> deleteAddress(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _client
          .from('user_addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Error deleting address: $e');
      rethrow;
    }
  }
  
  /// Set an address as default
  Future<Address?> setDefaultAddress(String id) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Clear all default addresses
      await _clearDefaultAddresses();
      
      // Set the selected address as default
      final response = await _client
          .from('user_addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', userId)
          .select()
          .single();
      
      return Address.fromJson(response);
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }
  
  /// Clear all default addresses
  Future<void> _clearDefaultAddresses() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      await _client
          .from('user_addresses')
          .update({'is_default': false})
          .eq('user_id', userId)
          .eq('is_default', true);
    } catch (e) {
      debugPrint('Error clearing default addresses: $e');
    }
  }
} 