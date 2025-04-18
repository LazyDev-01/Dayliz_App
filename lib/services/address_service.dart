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
      
      // Make sure the table exists
      final tableExists = await createAddressesTableIfNeeded();
      if (!tableExists) {
        debugPrint('Error in getAddresses: Address table does not exist');
        return [];
      }
      
      debugPrint('Fetching addresses for user: $userId');
      
      // Fetch addresses from the 'addresses' table
      final response = await _client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);
          
      debugPrint('API GET response from addresses: Data length: ${response.length}');
      
      return response.map<Address>((json) => Address.fromJson(json)).toList();
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
    String addressLine1,
    String? addressLine2,
    String city,
    String state,
    String country,
    String postalCode,
    bool isDefault,
    String? addressType,
    String? recipientName,
    String? recipientPhone,
    String? landmark,
    double? latitude,
    double? longitude,
    String? zone,
  ) async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in addAddress: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Make sure the table exists
      final tableExists = await createAddressesTableIfNeeded();
      if (!tableExists) {
        debugPrint('Error in addAddress: Address table creation failed');
        throw Exception('Could not create or access addresses table');
      }

      // Generate unique ID
      final addressId = const Uuid().v4();
      debugPrint('Generated address ID: $addressId for user: $userId');

      // First, try to insert the user directly using SQL
      try {
        final user = _userService.getCurrentUser();
        if (user != null) {
          final createUserSQL = '''
          INSERT INTO public.users (id, email, created_at, updated_at)
          VALUES ('${user.id}', '${user.email ?? ''}', NOW(), NOW())
          ON CONFLICT (id) DO NOTHING;
          ''';
          
          await _client.rpc('execute_sql', params: {'query': createUserSQL});
          debugPrint('✅ Successfully created user record via SQL');
        }
      } catch (e) {
        debugPrint('⚠️ Error creating user via SQL: $e');
        // Continue anyway, we'll try to add the address
      }
      
      // Now try to add the address
      try {
        // Create address data
        final addressData = {
          'id': addressId,
          'user_id': userId,
          'address_line1': addressLine1,
          'address_line2': addressLine2,
          'city': city,
          'state': state,
          'country': country,
          'postal_code': postalCode,
          'is_default': isDefault,
          'address_type': addressType,
          'recipient_name': recipientName,
          'recipient_phone': recipientPhone,
          'landmark': landmark,
          'latitude': latitude,
          'longitude': longitude,
          'zone_id': zone,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Remove null values
        final cleanData = Map<String, dynamic>.from(addressData);
        cleanData.removeWhere((key, value) => value == null);
        
        debugPrint('Inserting address with data: ${cleanData.keys.join(', ')}');

        // Try raw SQL insertion as a last resort
        final values = [
          "'$addressId'", 
          "'$userId'",
          "'$addressLine1'",
          addressLine2 != null ? "'$addressLine2'" : "NULL",
          "'$city'",
          "'$state'",
          "'$country'",
          "'$postalCode'",
          isDefault ? "TRUE" : "FALSE",
          addressType != null ? "'$addressType'" : "NULL",
          recipientName != null ? "'$recipientName'" : "NULL",
          recipientPhone != null ? "'$recipientPhone'" : "NULL",
          landmark != null ? "'$landmark'" : "NULL",
          latitude != null ? latitude.toString() : "NULL",
          longitude != null ? longitude.toString() : "NULL",
          zone != null ? "'$zone'" : "NULL",
          "NOW()",
          "NOW()"
        ];
        
        final insertSQL = '''
        INSERT INTO public.addresses (
          id, user_id, address_line1, address_line2, city, state, country, 
          postal_code, is_default, address_type, recipient_name, recipient_phone, 
          landmark, latitude, longitude, zone_id, created_at, updated_at
        ) VALUES (
          ${values.join(', ')}
        )
        RETURNING *;
        ''';
        
        final result = await _client.rpc('execute_sql', params: {'query': insertSQL});
        
        if (result != null && result.isNotEmpty) {
          debugPrint('Successfully added address using SQL: $result');
          
          // Create a model to return
          return Address(
            id: addressId,
            userId: userId,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            city: city,
            state: state,
            country: country,
            postalCode: postalCode,
            isDefault: isDefault,
            addressType: addressType,
            recipientName: recipientName,
            recipientPhone: recipientPhone,
            landmark: landmark,
            latitude: latitude,
            longitude: longitude,
            zone: zone,
            zoneId: zone,
          );
        }
        
        // Try the standard method as a fallback
        await _client.from('addresses').insert(cleanData);
            
        // Get the inserted address
        final addressResponse = await _client
            .from('addresses')
            .select()
            .eq('id', addressId)
            .single();
        
        debugPrint('Successfully added address with ID: $addressId to addresses table');
        return Address.fromJson(addressResponse);
      } catch (e) {
        debugPrint('❌ Error inserting into addresses table: $e');
        throw Exception('Could not insert address into table');
      }
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
  Future<bool> updateAddress(
    String id, {
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    bool? isDefault,
    String? addressType,
    String? recipientName,
    String? recipientPhone,
    String? landmark,
    double? latitude,
    double? longitude,
    String? zone,
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
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postalCode,
        'is_default': isDefault,
        'address_type': addressType,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'landmark': landmark,
        'latitude': latitude,
        'longitude': longitude,
        'zone': zone,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values
      final cleanData = Map<String, dynamic>.from(addressData);
      cleanData.removeWhere((key, value) => value == null);
      
      debugPrint('Updating address with data: ${cleanData.keys.join(', ')}');

      // Try updating in 'addresses' table
      try {
        await _client.from('addresses')
          .update(cleanData)
          .eq('id', id)
          .eq('user_id', userId);

        // If this is set as default, update other addresses
        if (isDefault == true) {
          await _updateOtherAddressesDefaultStatus(id);
        }
          
        debugPrint('Successfully updated address in addresses table');
        return true;
      } catch (e) {
        debugPrint('Error updating in addresses table: $e');
        
        // Try the legacy table
        try {
          await _client.from('user_addresses')
            .update(cleanData)
            .eq('id', id)
            .eq('user_id', userId);

          // If this is set as default, update other addresses
          if (isDefault == true) {
            await _updateOtherAddressesDefaultStatus(id);
          }
            
          debugPrint('Successfully updated address in user_addresses table');
          return true;
        } catch (e) {
          debugPrint('Error updating in user_addresses table: $e');
          throw Exception('Could not update address in any available tables');
        }
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
      return false;
    }
  }
  
  /// Delete an address
  Future<bool> deleteAddress(String id) async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in deleteAddress: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('Deleting address $id for user: $userId');

      // Try deleting from 'addresses' table
      try {
        await _client.from('addresses')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
          
        debugPrint('Successfully deleted address from addresses table');
        return true;
      } catch (e) {
        debugPrint('Error deleting from addresses table: $e');
        
        // Try the legacy table
        try {
          await _client.from('user_addresses')
            .delete()
            .eq('id', id)
            .eq('user_id', userId);
            
          debugPrint('Successfully deleted address from user_addresses table');
          return true;
        } catch (e) {
          debugPrint('Error deleting from user_addresses table: $e');
          throw Exception('Could not delete address from any available tables');
        }
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
      return false;
    }
  }
  
  /// Set an address as default
  Future<bool> setDefaultAddress(String id) async {
    try {
      final userId = _userService.getCurrentUser()?.id;
      if (userId == null) {
        debugPrint('Error in setDefaultAddress: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('Setting address $id as default for user: $userId');

      // First, set the specified address as default
      try {
        await _client.from('addresses')
          .update({'is_default': true})
          .eq('id', id)
          .eq('user_id', userId);
          
        // Update other addresses
        await _updateOtherAddressesDefaultStatus(id);
          
        debugPrint('Successfully set address as default in addresses table');
        return true;
      } catch (e) {
        debugPrint('Error setting default in addresses table: $e');
        
        // Try the legacy table
        try {
          await _client.from('user_addresses')
            .update({'is_default': true})
            .eq('id', id)
            .eq('user_id', userId);
            
          // Update other addresses
          await _updateOtherAddressesDefaultStatus(id);
            
          debugPrint('Successfully set address as default in user_addresses table');
          return true;
        } catch (e) {
          debugPrint('Error setting default in user_addresses table: $e');
          throw Exception('Could not set address as default in any available tables');
        }
      }
    } catch (e) {
      debugPrint('Error setting default address: $e');
      return false;
    }
  }
  
  /// Helper method to update other addresses when setting one as default
  Future<void> _updateOtherAddressesDefaultStatus(String defaultAddressId) async {
    final userId = _userService.getCurrentUser()?.id;
    if (userId == null) return;

    // Try to update in addresses table
    try {
      await _client.from('addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .neq('id', defaultAddressId);
    } catch (e) {
      debugPrint('Error updating other addresses in addresses table: $e');
    }

    // Try to update in user_addresses table
    try {
      await _client.from('user_addresses')
        .update({'is_default': false})
        .eq('user_id', userId)
        .neq('id', defaultAddressId);
    } catch (e) {
      debugPrint('Error updating other addresses in user_addresses table: $e');
    }
  }
  
  /// Test connection to database and check if addresses table exists
  Future<bool> testDatabaseConnection() async {
    try {
      // Get current user ID
      final user = _userService.getCurrentUser();
      if (user == null) {
        debugPrint('Error in testDatabaseConnection: User not authenticated');
        return false;
      }
      
      // Try direct query as a fallback to check if addresses table exists
      try {
        final fallbackCheck = await _client
            .from('addresses')
            .select('id')
            .limit(1);
        
        debugPrint('✅ Address table exists (verified through direct query)');
        return true;
      } catch (e) {
        debugPrint('❌ Addresses table not found');
        return false;
      }
    } catch (e) {
      debugPrint('Error testing database connection: $e');
      return false;
    }
  }

  // Create the addresses table if it doesn't exist
  Future<bool> createAddressesTableIfNeeded() async {
    try {
      // Check if the table exists
      final hasTable = await testDatabaseConnection();
      if (hasTable) {
        debugPrint('✅ Address table connection successful');
        return true;
      }
      
      // Table doesn't exist, create it
      const createTableSQL = '''
      CREATE TABLE IF NOT EXISTS addresses (
        id UUID PRIMARY KEY,
        user_id UUID NOT NULL REFERENCES auth.users(id),
        address_line1 TEXT NOT NULL,
        address_line2 TEXT,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        country TEXT NOT NULL,
        postal_code TEXT NOT NULL,
        is_default BOOLEAN DEFAULT false,
        address_type TEXT,
        recipient_name TEXT,
        recipient_phone TEXT,
        landmark TEXT,
        latitude DECIMAL(10,6),
        longitude DECIMAL(10,6),
        zone_id UUID REFERENCES zones(id),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
      
      CREATE INDEX IF NOT EXISTS idx_addresses_user_id ON addresses(user_id);
      CREATE INDEX IF NOT EXISTS idx_addresses_zone_id ON addresses(zone_id);
      ''';
      
      await _client.rpc('execute_sql', params: {'query': createTableSQL});
      debugPrint('✅ Created addresses table');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to create addresses table: $e');
      return false;
    }
  }
} 