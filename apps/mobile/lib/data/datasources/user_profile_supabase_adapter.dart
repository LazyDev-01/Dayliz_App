import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/address.dart';

import '../../data/models/user_profile_model.dart';
import '../datasources/user_profile_data_source.dart';
import '../../core/errors/exceptions.dart';

/// Adapter class that implements UserProfileDataSource using Supabase
class UserProfileSupabaseAdapter implements UserProfileDataSource {
  final SupabaseClient client;

  UserProfileSupabaseAdapter({required this.client}) {
    debugPrint('UserProfileSupabaseAdapter initialized with client: $client');
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      final response = await client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      // Handle preferences field properly for Google Sign-In users
      Map<String, dynamic>? preferences;
      try {
        final prefsValue = response['preferences'];
        if (prefsValue is String) {
          // If it's a JSON string (common for Google Sign-In users), parse it
          preferences = prefsValue.isEmpty ? {} : json.decode(prefsValue);
          debugPrint('UserProfileSupabaseAdapter: Parsed preferences from JSON string: $preferences');
        } else if (prefsValue is Map<String, dynamic>) {
          // If it's already a map, use it directly
          preferences = prefsValue;
          debugPrint('UserProfileSupabaseAdapter: Using preferences as map: $preferences');
        } else {
          // Default to empty map
          preferences = {};
          debugPrint('UserProfileSupabaseAdapter: Using default empty preferences');
        }
      } catch (e) {
        debugPrint('UserProfileSupabaseAdapter: Error parsing preferences, using empty map: $e');
        preferences = {};
      }

      return UserProfileModel(
        id: response['id'],
        userId: response['user_id'],
        fullName: response['full_name'],
        profileImageUrl: response['profile_image_url'],
        dateOfBirth: response['date_of_birth'] != null
            ? DateTime.parse(response['date_of_birth'])
            : null,
        gender: response['gender'],
        lastUpdated: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'])
            : null,
        preferences: preferences,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      final response = await client
          .from('addresses')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false);

      return (response as List).map((item) => Address(
        id: item['id'],
        userId: item['user_id'],
        addressLine1: item['address_line1'],
        addressLine2: item['address_line2'] ?? '',
        city: item['city'],
        state: item['state'],
        postalCode: item['postal_code'],
        country: item['country'],
        phoneNumber: item['phone_number'],
        isDefault: item['is_default'] ?? false,
        // Label field removed
        addressType: item['address_type'],
        additionalInfo: item['additional_info'],
        landmark: item['landmark'],
        latitude: item['latitude'] != null ?
            double.tryParse(item['latitude'].toString()) : null,
        longitude: item['longitude'] != null ?
            double.tryParse(item['longitude'].toString()) : null,
        zoneId: item['zone_id'],
        recipientName: item['recipient_name'],
        createdAt: item['created_at'] != null ? DateTime.parse(item['created_at'].toString()) : null,
        updatedAt: item['updated_at'] != null ? DateTime.parse(item['updated_at'].toString()) : null,
      )).toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Address> addAddress(String userId, Address address) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }

      // Debug log
      debugPrint('Adding address for user: $userId');
      debugPrint('Address details: ${address.addressLine1}, ${address.city}, ${address.state}');

      // If this is the first address or marked as default, ensure it's set as default
      bool shouldBeDefault = address.isDefault;

      if (!shouldBeDefault) {
        // Check if user has any addresses
        final existingAddresses = await client
            .from('addresses')
            .select('id')
            .eq('user_id', userId);

        debugPrint('Existing addresses count: ${existingAddresses.length}');

        // If no addresses exist, make this the default
        if (existingAddresses.isEmpty) {
          shouldBeDefault = true;
          debugPrint('No existing addresses, setting as default');
        }
      }

      // If setting as default, reset any existing default addresses
      if (shouldBeDefault) {
        debugPrint('Setting as default address, resetting other defaults');
        await client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }

      // Prepare data for insertion, ensuring no null values for required fields
      final data = {
        'id': address.id,
        'user_id': userId,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'phone_number': address.phoneNumber,
        'is_default': shouldBeDefault,
        // Label field removed
        'address_type': address.addressType,
        'additional_info': address.additionalInfo,
        'landmark': address.landmark,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'zone_id': address.zoneId,
        'recipient_name': address.recipientName,
        // Let the database handle created_at and updated_at
      };

      // Remove null values to prevent database errors
      data.removeWhere((key, value) => value == null);

      debugPrint('Inserting address with data: $data');

      final response = await client
          .from('addresses')
          .insert(data)
          .select()
          .single();

      debugPrint('Address inserted successfully: ${response['id']}');

      return Address(
        id: response['id'],
        userId: response['user_id'],
        addressLine1: response['address_line1'],
        addressLine2: response['address_line2'] ?? '',
        city: response['city'],
        state: response['state'],
        postalCode: response['postal_code'],
        country: response['country'],
        phoneNumber: response['phone_number'],
        isDefault: response['is_default'] ?? false,
        // Label field removed
        addressType: response['address_type'],
        additionalInfo: response['additional_info'],
        landmark: response['landmark'],
        latitude: response['latitude'] != null ?
            double.tryParse(response['latitude'].toString()) : null,
        longitude: response['longitude'] != null ?
            double.tryParse(response['longitude'].toString()) : null,
        zoneId: response['zone_id'],
        recipientName: response['recipient_name'],
        createdAt: response['created_at'] != null ? DateTime.parse(response['created_at'].toString()) : null,
        updatedAt: response['updated_at'] != null ? DateTime.parse(response['updated_at'].toString()) : null,
      );
    } catch (e) {
      debugPrint('Error adding address: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Address> updateAddress(String userId, Address address) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      // Debug log
      debugPrint('Updating address: ${address.id} for user: $userId');

      // If setting as default, reset any existing default addresses
      if (address.isDefault) {
        debugPrint('Setting as default address, resetting other defaults');
        await client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true)
            .neq('id', address.id);
      }

      // Prepare data for update
      final data = {
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'phone_number': address.phoneNumber,
        'is_default': address.isDefault,
        // Label field removed
        'address_type': address.addressType,
        'additional_info': address.additionalInfo,
        'landmark': address.landmark,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'zone_id': address.zoneId,
        'recipient_name': address.recipientName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Remove null values to prevent database errors
      data.removeWhere((key, value) => value == null);

      debugPrint('Updating address with data: $data');

      final response = await client
          .from('addresses')
          .update(data)
          .eq('id', address.id)
          .eq('user_id', userId)
          .select()
          .single();

      debugPrint('Address updated successfully: ${response['id']}');

      return Address(
        id: response['id'],
        userId: response['user_id'],
        addressLine1: response['address_line1'],
        addressLine2: response['address_line2'] ?? '',
        city: response['city'],
        state: response['state'],
        postalCode: response['postal_code'],
        country: response['country'],
        phoneNumber: response['phone_number'],
        isDefault: response['is_default'] ?? false,
        // Label field removed
        addressType: response['address_type'],
        additionalInfo: response['additional_info'],
        landmark: response['landmark'],
        latitude: response['latitude'] != null ?
            double.tryParse(response['latitude'].toString()) : null,
        longitude: response['longitude'] != null ?
            double.tryParse(response['longitude'].toString()) : null,
        zoneId: response['zone_id'],
        recipientName: response['recipient_name'],
        createdAt: response['created_at'] != null ? DateTime.parse(response['created_at'].toString()) : null,
        updatedAt: response['updated_at'] != null ? DateTime.parse(response['updated_at'].toString()) : null,
      );
    } catch (e) {
      debugPrint('Error updating address: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }

      debugPrint('Deleting address: $addressId for user: $userId');

      // First, let's create the safe_delete_address function if it doesn't exist
      try {
        const createFunctionSQL = '''
        -- Function to safely delete an address
        CREATE OR REPLACE FUNCTION safe_delete_address(
          address_id_param UUID,
          user_id_param UUID
        )
        RETURNS BOOLEAN
        LANGUAGE plpgsql
        SECURITY DEFINER -- This makes the function run with the privileges of the creator
        AS \$\$
        DECLARE
          is_default BOOLEAN;
          remaining_address_id UUID;
        BEGIN
          -- Check if the address exists and belongs to the user
          SELECT is_default INTO is_default
          FROM addresses
          WHERE id = address_id_param AND user_id = user_id_param;

          IF is_default IS NULL THEN
            RAISE EXCEPTION 'Address not found or does not belong to user';
            RETURN FALSE;
          END IF;

          -- Check if the address is referenced by any orders
          IF EXISTS (
            SELECT 1 FROM orders
            WHERE (
              shipping_address_id = address_id_param
              OR billing_address_id = address_id_param
              OR shipping_address->>'id' = address_id_param::TEXT
              OR billing_address->>'id' = address_id_param::TEXT
            )
            LIMIT 1
          ) THEN
            RAISE EXCEPTION 'Cannot delete this address because it is used in one or more orders.';
            RETURN FALSE;
          END IF;

          -- Delete the address
          DELETE FROM addresses
          WHERE id = address_id_param AND user_id = user_id_param;

          -- If the deleted address was the default one, set a new default address
          IF is_default THEN
            SELECT id INTO remaining_address_id
            FROM addresses
            WHERE user_id = user_id_param
            LIMIT 1;

            IF remaining_address_id IS NOT NULL THEN
              UPDATE addresses
              SET is_default = TRUE
              WHERE id = remaining_address_id;
            END IF;
          END IF;

          RETURN TRUE;
        END;
        \$\$;

        -- Grant execute permission to authenticated users
        GRANT EXECUTE ON FUNCTION safe_delete_address(UUID, UUID) TO authenticated;
        ''';

        // Create the function
        await client.rpc('execute_sql', params: {'sql': createFunctionSQL});
        debugPrint('Created safe_delete_address function');
      } catch (e) {
        // Function might already exist, which is fine
        debugPrint('Note: Function creation error (may already exist): $e');
      }

      // Now call the function to safely delete the address
      final result = await client.rpc('safe_delete_address', params: {
        'address_id_param': addressId,
        'user_id_param': userId
      });

      if (result == null || result == false) {
        throw ServerException(message: 'Failed to delete address');
      }

      debugPrint('Address deleted successfully using safe_delete_address function');
      return true;
    } catch (e) {
      debugPrint('Exception in deleteAddress: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> setDefaultAddress(String userId, String addressId) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      // First, reset all addresses to non-default
      await client
          .from('addresses')
          .update({'is_default': false})
          .eq('user_id', userId);

      // Then set the selected address as default
      await client
          .from('addresses')
          .update({'is_default': true})
          .eq('id', addressId)
          .eq('user_id', userId);
      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    try {
      final response = await client
          .from('user_profiles')
          .update(profile.toMap())
          .eq('id', profile.id)
          .select()
          .single();

      // Handle preferences field properly for Google Sign-In users
      Map<String, dynamic>? updatePreferences;
      try {
        final prefsValue = response['preferences'];
        if (prefsValue is String) {
          // If it's a JSON string (common for Google Sign-In users), parse it
          updatePreferences = prefsValue.isEmpty ? {} : json.decode(prefsValue);
          debugPrint('UserProfileSupabaseAdapter: Parsed update preferences from JSON string: $updatePreferences');
        } else if (prefsValue is Map<String, dynamic>) {
          // If it's already a map, use it directly
          updatePreferences = prefsValue;
          debugPrint('UserProfileSupabaseAdapter: Using update preferences as map: $updatePreferences');
        } else {
          // Default to empty map
          updatePreferences = {};
          debugPrint('UserProfileSupabaseAdapter: Using default empty update preferences');
        }
      } catch (e) {
        debugPrint('UserProfileSupabaseAdapter: Error parsing update preferences, using empty map: $e');
        updatePreferences = {};
      }

      return UserProfileModel(
        id: response['id'],
        userId: response['user_id'],
        fullName: response['full_name'],
        profileImageUrl: response['profile_image_url'],
        dateOfBirth: response['date_of_birth'] != null
            ? DateTime.parse(response['date_of_birth'])
            : null,
        gender: response['gender'],
        lastUpdated: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'])
            : null,
        preferences: updatePreferences,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<String> uploadProfileImage(String userId, String imagePath) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      // Convert the image path to a File object
      final file = File(imagePath);

      // Upload the image to Supabase Storage
      final fileName = 'profile_$userId.jpg';
      final filePath = 'profiles/$fileName';

      await client.storage.from('avatars').upload(
        filePath,
        file,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get the public URL
      final imageUrl = client.storage.from('avatars').getPublicUrl(filePath);

      // Update the user profile with the new image URL
      await client
          .from('user_profiles')
          .update({'profile_image_url': imageUrl})
          .eq('user_id', userId);

      return imageUrl;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      // Check if preferences exist for this user
      final existingPrefs = await client
          .from('user_preferences')
          .select()
          .eq('user_id', userId);

      if (existingPrefs.isEmpty) {
        // Create new preferences
        final data = {
          'user_id': userId,
          'preferences': preferences,
        };

        await client
            .from('user_preferences')
            .insert(data);
      } else {
        // Update existing preferences
        await client
            .from('user_preferences')
            .update({'preferences': preferences})
            .eq('user_id', userId);
      }

      return preferences;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> updateProfileImage(String userId, dynamic imageFile) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      if (imageFile is! File) {
        throw ServerException(message: 'imageFile must be a File object');
      }

      // Upload the image to Supabase Storage
      final fileName = 'profile_$userId.jpg';
      final filePath = 'profiles/$fileName';

      await client.storage.from('avatars').upload(
        filePath,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get the public URL
      final imageUrl = client.storage.from('avatars').getPublicUrl(filePath);

      // Update the user profile with the new image URL
      await client
          .from('user_profiles')
          .update({'profile_image_url': imageUrl})
          .eq('user_id', userId);

      return imageUrl;
    } catch (e) {
      throw ServerException(message: 'Failed to update profile image: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteProfileImage(String userId) async {
    try {
      // Validate UUID format
      if (!_isValidUuid(userId)) {
        throw ServerException(message: 'Invalid user ID format. Must be a valid UUID.');
      }
      // Get the current profile image URL
      final response = await client
          .from('user_profiles')
          .select('profile_image_url')
          .eq('user_id', userId)
          .single();

      final imageUrl = response['profile_image_url'] as String?;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        // Extract the file path from the URL
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;

        // The file path should be the last segments after 'avatars'
        final avatarIndex = pathSegments.indexOf('avatars');
        if (avatarIndex >= 0 && avatarIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(avatarIndex + 1).join('/');

          // Delete the file from storage
          await client.storage.from('avatars').remove([filePath]);
        }
      }

      // Update the user profile to remove the image URL
      await client
          .from('user_profiles')
          .update({'profile_image_url': null})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      throw ServerException(message: 'Failed to delete profile image: ${e.toString()}');
    }
  }

  /// Validates if a string is a valid UUID
  bool _isValidUuid(String str) {
    try {
      // Check if the string matches the UUID pattern
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      return uuidRegex.hasMatch(str);
    } catch (e) {
      return false;
    }
  }
}
