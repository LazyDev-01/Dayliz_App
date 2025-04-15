import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/models/address.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:dayliz_app/services/user_service.dart';

/// Service that handles address operations using Supabase.
class AddressService {
  static final AddressService _instance = AddressService._internal();
  static AddressService get instance => _instance;
  
  late final SupabaseClient _client;
  late final UserService _userService;
  
  /// Private constructor
  AddressService._internal() {
    _client = Supabase.instance.client;
    _userService = UserService.instance;
  }
  
  /// Get all addresses for the current user
  Future<List<Address>> getAddresses() async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in getAddresses: User not authenticated');
        throw Exception('User not authenticated');
      }
      
      // Ensure user exists in public.users table
      final userExists = await _userService.ensureUserExists();
      if (!userExists) {
        debugPrint('Error in getAddresses: Failed to ensure user exists');
        throw Exception('Failed to ensure user exists');
      }
      
      debugPrint('Fetching addresses for user: $userId');
      final response = await _client
          .from('user_addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);
      
      debugPrint('API GET response from user_addresses: Data length: ${response.length}');
      debugPrint('Fetch response: 200 - Data length: ${response.length}');
      debugPrint('Parsed ${response.length} addresses');
      
      if (response.isEmpty) {
        debugPrint('No addresses found, using placeholder');
      }
      
      return response
          .map<Address>((json) => Address(
                id: json['id'],
                userId: json['user_id'],
                name: json['name'],
                addressLine1: json['address_line1'],
                addressLine2: json['address_line2'],
                city: json['city'],
                state: json['state'],
                country: json['country'],
                postalCode: json['postal_code'],
                phoneNumber: json['phone'] ?? '',
                isDefault: json['is_default'] ?? false,
                latitude: json['latitude'],
                longitude: json['longitude'],
                landmark: null,
                addressType: null,
                street: null,
                phone: json['phone'],
              ))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('Supabase error in getAddresses: ${e.code} - ${e.message} - ${e.details}');
      return [];
    } catch (e) {
      debugPrint('Error getting addresses: $e');
      return [];
    }
  }
  
  /// Add a new address
  Future<Address?> addAddress(
    String? name,
    String addressLine1,
    String? addressLine2,
    String city,
    String state,
    String country,
    String postalCode,
    String? phoneNumber,
    bool isDefault,
    double? latitude,
    double? longitude,
    String? landmark,
    String? addressType,
    String? street,
    String? phone,
  ) async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in addAddress: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Check if the user exists
      final userExists = await _client
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (userExists == null) {
        debugPrint('Error in addAddress: User does not exist');
        throw Exception('User does not exist in the database');
      }

      // Generate unique ID
      final addressId = const Uuid().v4();
      debugPrint('Generated address ID: $addressId for user: $userId');

      // Create address data
      final addressData = {
        'id': addressId,
        'user_id': userId,
        'name': name,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'phone_number': phoneNumber,
        'is_default': isDefault,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
        'address_type': addressType,
        'street': street,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      final cleanData = Map<String, dynamic>.from(addressData);
      cleanData.removeWhere((key, value) => value == null);
      
      debugPrint('Inserting address with data: ${cleanData.keys.join(', ')}');

      // Insert the address
      await _client
          .from('user_addresses')
          .insert(cleanData);
      
      // Get the inserted address
      final addressResponse = await _client
          .from('user_addresses')
          .select()
          .eq('id', addressId)
          .single();
      
      debugPrint('Successfully added address with ID: $addressId');
      return Address.fromJson(addressResponse);
    } catch (e) {
      if (e is PostgrestException) {
        debugPrint('PostgrestException in addAddress: ${e.message}, ${e.details}');
      } else {
        debugPrint('Error adding address: $e');
      }
      rethrow;
    }
  }
  
  /// Update an existing address
  Future<Address?> updateAddress(
    String id, {
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? phoneNumber,
    bool? isDefault,
    double? latitude,
    double? longitude,
    String? landmark,
    String? addressType,
    String? street,
    String? phone,
  }) async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in updateAddress: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('Updating address $id for user: $userId');

      // Create address data
      final addressData = {
        'name': name,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'phone_number': phoneNumber,
        'is_default': isDefault,
        'latitude': latitude,
        'longitude': longitude,
        'landmark': landmark,
        'address_type': addressType,
        'street': street,
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      final cleanData = Map<String, dynamic>.from(addressData);
      cleanData.removeWhere((key, value) => value == null);
      
      debugPrint('Updating address with data: ${cleanData.keys.join(', ')}');

      // Update the address in the database
      await _client
          .from('user_addresses')
          .update(cleanData)
          .eq('id', id);
      
      // Get the updated address
      final addressResponse = await _client
          .from('user_addresses')
          .select()
          .eq('id', id)
          .single();
      
      debugPrint('Successfully updated address with ID: $id');
      return Address.fromJson(addressResponse);
    } catch (e) {
      if (e is PostgrestException) {
        debugPrint('PostgrestException in updateAddress: ${e.message}, ${e.details}');
      } else {
        debugPrint('Error updating address: $e');
      }
      rethrow;
    }
  }
  
  /// Delete an address
  Future<void> deleteAddress(String id) async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in deleteAddress: User not authenticated');
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
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in setDefaultAddress: User not authenticated');
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
          .select();
      
      if (response.isEmpty) {
        throw Exception('Address not found');
      }
      
      return Address.fromJson(response.first);
    } catch (e) {
      debugPrint('Error setting default address: $e');
      rethrow;
    }
  }
  
  /// Clear all default addresses
  Future<void> _clearDefaultAddresses() async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in _clearDefaultAddresses: User not authenticated');
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
  
  /// Test connection to database and check if user_addresses table exists
  Future<bool> testDatabaseConnection() async {
    debugPrint('Testing database connection to user_addresses table...');
    
    try {
      // Try to get column information directly
      final response = await _client
          .from('user_addresses')
          .select('*')
          .limit(1);
          
      debugPrint('✅ Successfully connected to user_addresses table');
      // If we have data, print the first row keys to see column names
      if (response is List && response.isNotEmpty) {
        final columns = (response[0] as Map).keys.toList();
        debugPrint('user_addresses table columns: $columns');
      } else {
        debugPrint('user_addresses table exists but has no data to inspect columns');
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ Error accessing user_addresses table: $e');
      
      try {
        // If user_addresses doesn't exist, check if address table exists instead
        final alternativeResponse = await _client
            .from('address')
            .select('*')
            .limit(1);
            
        debugPrint('✅ Found alternative address table!');
        debugPrint('Address table data: $alternativeResponse');
        
        // If we have data, print the first row keys to see column names
        if (alternativeResponse is List && alternativeResponse.isNotEmpty) {
          final columns = (alternativeResponse[0] as Map).keys.toList();
          debugPrint('Address table columns: $columns');
        } else {
          debugPrint('Address table exists but has no data to inspect columns');
        }
        return true;
      } catch (innerE) {
        debugPrint('❌ Alternative address table also not found: $innerE');
        return false;
      }
    }
  }
} 