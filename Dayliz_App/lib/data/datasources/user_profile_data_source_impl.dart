import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';
import '../models/address_model.dart';

abstract class UserProfileDataSource {
  /// Gets the user profile for the given [userId].
  ///
  /// Throws a [ServerException] for all server errors.
  Future<UserProfileModel> getUserProfile(String userId);

  /// Gets all addresses for the given [userId].
  ///
  /// Throws a [ServerException] for all server errors.
  Future<List<Address>> getUserAddresses(String userId);

  /// Adds a new address for the user.
  ///
  /// Throws a [ServerException] for all server errors.
  Future<Address> addAddress(String userId, Address address);

  /// Updates an existing address.
  ///
  /// Throws a [ServerException] for all server errors.
  Future<Address> updateAddress(String userId, Address address);

  /// Deletes an address.
  ///
  /// Throws a [ServerException] for all server errors.
  Future<bool> deleteAddress(String userId, String addressId);

  /// Sets an address as the default address.
  ///
  /// Throws a [ServerException] for all server errors.
  Future<bool> setDefaultAddress(String userId, String addressId);

  /// Updates a user profile
  ///
  /// Throws a [ServerException] for all server errors.
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile);

  /// Uploads a profile image
  ///
  /// Throws a [ServerException] for all server errors.
  Future<String> uploadProfileImage(String userId, String imagePath);

  /// Deletes a profile image
  ///
  /// Throws a [ServerException] for all server errors.
  Future<bool> deleteProfileImage(String userId);

  /// Updates user preferences
  ///
  /// Throws a [ServerException] for all server errors.
  Future<Map<String, dynamic>> updatePreferences(String userId, Map<String, dynamic> preferences);

  /// Updates a profile image
  ///
  /// Throws a [ServerException] for all server errors.
  Future<String> updateProfileImage(String userId, File imageFile);
}

class UserProfileDataSourceImpl implements UserProfileDataSource {
  final SupabaseClient client;

  UserProfileDataSourceImpl({required this.client});

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    debugPrint('UserProfileDataSourceImpl: Fetching user profile for user ID: $userId');
    debugPrint('UserProfileDataSourceImpl: Using Supabase client: available');

    try {
      debugPrint('UserProfileDataSourceImpl: Querying user_profiles table for user_id: $userId');

      // Check if the client is properly initialized
      try {
        // Just access a property to verify the client is working
        final _ = client.auth.currentSession;
        debugPrint('UserProfileDataSourceImpl: Supabase client auth is properly initialized');
      } catch (authError) {
        debugPrint('UserProfileDataSourceImpl: Supabase client auth error: $authError');
        throw ServerException(message: 'Supabase client is not properly initialized: $authError');
      }

      // Check if the table exists
      try {
        debugPrint('UserProfileDataSourceImpl: Checking if user_profiles table exists');
        final tableCheck = await client.from('user_profiles').select('count').limit(1);
        debugPrint('UserProfileDataSourceImpl: Table check successful: $tableCheck');
      } catch (tableError) {
        debugPrint('UserProfileDataSourceImpl: Error checking table: $tableError');
        // Continue anyway, as this is just a diagnostic check
      }

      // Perform the actual query
      final response = await client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      debugPrint('UserProfileDataSourceImpl: Found existing profile with ID: ${response['id']}');
      debugPrint('UserProfileDataSourceImpl: FULL RESPONSE: $response');
      debugPrint('UserProfileDataSourceImpl: Available keys: ${response.keys.toList()}');

      // Debug all fields that might contain the name
      debugPrint('UserProfileDataSourceImpl: Profile data - full_name: ${response['full_name']}');
      debugPrint('UserProfileDataSourceImpl: Profile data - name: ${response['name']}');
      debugPrint('UserProfileDataSourceImpl: Profile data - fullname: ${response['fullname']}');
      debugPrint('UserProfileDataSourceImpl: Profile data - fullName: ${response['fullName']}');
      debugPrint('UserProfileDataSourceImpl: Profile data - user_name: ${response['user_name']}');

      // Try to find the fullName field, checking different possible field names
      String? profileFullName = response['full_name'];
      if (profileFullName == null) {
        // Try alternative field names
        if (response.containsKey('name')) {
          profileFullName = response['name'];
          debugPrint('UserProfileDataSourceImpl: Using "name" field instead: $profileFullName');
        } else if (response.containsKey('fullname')) {
          profileFullName = response['fullname'];
          debugPrint('UserProfileDataSourceImpl: Using "fullname" field instead: $profileFullName');
        } else if (response.containsKey('fullName')) {
          profileFullName = response['fullName'];
          debugPrint('UserProfileDataSourceImpl: Using "fullName" field instead: $profileFullName');
        } else if (response.containsKey('user_name')) {
          profileFullName = response['user_name'];
          debugPrint('UserProfileDataSourceImpl: Using "user_name" field instead: $profileFullName');
        }
      }

      debugPrint('UserProfileDataSourceImpl: Final fullName value: $profileFullName');

      // CRITICAL FIX: Handle preferences field properly
      Map<String, dynamic>? preferences;
      try {
        final prefsValue = response['preferences'];
        if (prefsValue is String) {
          // If it's a JSON string, parse it
          preferences = prefsValue.isEmpty ? {} : json.decode(prefsValue);
          debugPrint('UserProfileDataSourceImpl: Parsed preferences from JSON string: $preferences');
        } else if (prefsValue is Map<String, dynamic>) {
          // If it's already a map, use it directly
          preferences = prefsValue;
          debugPrint('UserProfileDataSourceImpl: Using preferences as map: $preferences');
        } else {
          // Default to empty map
          preferences = {};
          debugPrint('UserProfileDataSourceImpl: Using default empty preferences');
        }
      } catch (e) {
        debugPrint('UserProfileDataSourceImpl: Error parsing preferences, using empty map: $e');
        preferences = {};
      }

      // Create the model using fromMap to ensure proper type handling
      final responseMap = Map<String, dynamic>.from(response);
      responseMap['full_name'] = profileFullName; // Use the processed fullName
      responseMap['preferences'] = preferences; // Use the processed preferences

      // Debug the final responseMap before creating the model
      debugPrint('UserProfileDataSourceImpl: Final responseMap before creating model: $responseMap');
      debugPrint('UserProfileDataSourceImpl: responseMap types:');
      responseMap.forEach((key, value) {
        debugPrint('  $key: ${value.runtimeType} = $value');
      });

      try {
        final model = UserProfileModel.fromMap(responseMap);
        debugPrint('UserProfileDataSourceImpl: Successfully created UserProfileModel');
        return model;
      } catch (modelError) {
        debugPrint('UserProfileDataSourceImpl: Error creating UserProfileModel: $modelError');
        debugPrint('UserProfileDataSourceImpl: Error type: ${modelError.runtimeType}');
        throw ServerException(message: 'Error creating user profile model: $modelError');
      }
    } catch (e) {
      debugPrint('UserProfileDataSourceImpl: Error in getUserProfile: $e');
      debugPrint('UserProfileDataSourceImpl: Error details: $e');

      // CRITICAL FIX: Check if this is actually a "profile not found" error or just a parsing error
      if (e is PostgrestException) {
        debugPrint('UserProfileDataSourceImpl: PostgrestException - code: ${e.code}, message: ${e.message}, details: ${e.details}');

        // If it's a duplicate key error, the profile exists but there's a conflict
        if (e.code == '23505' || e.message.contains('duplicate key') || e.message.contains('unique constraint')) {
          debugPrint('UserProfileDataSourceImpl: Duplicate key error detected - profile exists but there was a conflict');
          throw ServerException(message: 'Profile already exists: ${e.message}');
        }

        // If it's not a "not found" error, don't try to create a new profile
        if (e.code != null && e.code != '406' && !e.message.contains('No rows found')) {
          debugPrint('UserProfileDataSourceImpl: Non-404 PostgrestException, not attempting to create profile');
          throw ServerException(message: 'Database error: ${e.message}');
        }
      } else {
        // For non-PostgrestException errors (like parsing errors), don't create a new profile
        debugPrint('UserProfileDataSourceImpl: Non-PostgrestException error, not attempting to create profile');
        throw ServerException(message: 'Error processing profile data: $e');
      }

      // Only create a new profile if it's actually a "not found" error
      debugPrint('UserProfileDataSourceImpl: Profile not found, creating a new one for user ID: $userId');

      // Get user details from current session to populate the profile
      debugPrint('UserProfileDataSourceImpl: Getting user details from current session for user ID: $userId');

      try {
        // CRITICAL FIX: Use current user instead of admin API to avoid 403 error
        final currentUser = client.auth.currentUser;
        if (currentUser == null || currentUser.id != userId) {
          debugPrint('UserProfileDataSourceImpl: No current user or user ID mismatch');
          throw ServerException(message: 'User not authenticated or user ID mismatch');
        }

        final email = currentUser.email;
        debugPrint('UserProfileDataSourceImpl: Got user email: $email');

        // Try to get the name from user metadata first, then fall back to email
        String? fullName;
        if (currentUser.userMetadata != null && currentUser.userMetadata!.containsKey('name')) {
          fullName = currentUser.userMetadata!['name'];
          debugPrint('UserProfileDataSourceImpl: Using name from user metadata: $fullName');
        } else if (currentUser.userMetadata != null && currentUser.userMetadata!.containsKey('full_name')) {
          fullName = currentUser.userMetadata!['full_name'];
          debugPrint('UserProfileDataSourceImpl: Using full_name from user metadata: $fullName');
        } else if (currentUser.userMetadata != null && currentUser.userMetadata!.containsKey('display_name')) {
          fullName = currentUser.userMetadata!['display_name'];
          debugPrint('UserProfileDataSourceImpl: Using display_name from user metadata: $fullName');
        } else {
          fullName = email != null ? email.split('@')[0] : 'User'; // Use part of email as name
          debugPrint('UserProfileDataSourceImpl: No name in metadata, using email-based name: $fullName');
        }

        debugPrint('UserProfileDataSourceImpl: Creating profile with fullName: $fullName');

        // Insert new profile
        final data = {
          'user_id': userId,
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await client
            .from('user_profiles')
            .insert(data)
            .select()
            .single();

        debugPrint('UserProfileDataSourceImpl: Created new profile with ID: ${response['id']}');

        // Debug the response
        debugPrint('UserProfileDataSourceImpl: FULL RESPONSE for new profile: $response');
        debugPrint('UserProfileDataSourceImpl: Available keys: ${response.keys.toList()}');

        // Try to find the fullName field, checking different possible field names
        String? profileFullName = response['full_name'];
        if (profileFullName == null) {
          // Try alternative field names
          if (response.containsKey('name')) {
            profileFullName = response['name'];
            debugPrint('UserProfileDataSourceImpl: Using "name" field instead: $profileFullName');
          } else if (response.containsKey('fullname')) {
            profileFullName = response['fullname'];
            debugPrint('UserProfileDataSourceImpl: Using "fullname" field instead: $profileFullName');
          } else if (response.containsKey('fullName')) {
            profileFullName = response['fullName'];
            debugPrint('UserProfileDataSourceImpl: Using "fullName" field instead: $profileFullName');
          } else if (response.containsKey('user_name')) {
            profileFullName = response['user_name'];
            debugPrint('UserProfileDataSourceImpl: Using "user_name" field instead: $profileFullName');
          }
        }

        debugPrint('UserProfileDataSourceImpl: Final fullName value for new profile: $profileFullName');

        // CRITICAL FIX: Handle preferences field properly for new profiles too
        Map<String, dynamic>? newProfilePreferences;
        try {
          final prefsValue = response['preferences'];
          if (prefsValue is String) {
            // If it's a JSON string, parse it
            newProfilePreferences = prefsValue.isEmpty ? {} : json.decode(prefsValue);
            debugPrint('UserProfileDataSourceImpl: Parsed new profile preferences from JSON string: $newProfilePreferences');
          } else if (prefsValue is Map<String, dynamic>) {
            // If it's already a map, use it directly
            newProfilePreferences = prefsValue;
            debugPrint('UserProfileDataSourceImpl: Using new profile preferences as map: $newProfilePreferences');
          } else {
            // Default to empty map
            newProfilePreferences = {};
            debugPrint('UserProfileDataSourceImpl: Using default empty preferences for new profile');
          }
        } catch (e) {
          debugPrint('UserProfileDataSourceImpl: Error parsing new profile preferences, using empty map: $e');
          newProfilePreferences = {};
        }

        // Create the model using fromMap to ensure proper type handling
        final newResponseMap = Map<String, dynamic>.from(response);
        newResponseMap['full_name'] = profileFullName; // Use the processed fullName
        newResponseMap['preferences'] = newProfilePreferences; // Use the processed preferences

        // Debug the final newResponseMap before creating the model
        debugPrint('UserProfileDataSourceImpl: Final newResponseMap before creating model: $newResponseMap');
        debugPrint('UserProfileDataSourceImpl: newResponseMap types:');
        newResponseMap.forEach((key, value) {
          debugPrint('  $key: ${value.runtimeType} = $value');
        });

        try {
          final newModel = UserProfileModel.fromMap(newResponseMap);
          debugPrint('UserProfileDataSourceImpl: Successfully created new UserProfileModel');
          return newModel;
        } catch (newModelError) {
          debugPrint('UserProfileDataSourceImpl: Error creating new UserProfileModel: $newModelError');
          debugPrint('UserProfileDataSourceImpl: Error type: ${newModelError.runtimeType}');
          throw ServerException(message: 'Error creating new user profile model: $newModelError');
        }
      } catch (authError) {
        debugPrint('UserProfileDataSourceImpl: Error getting user details from auth: $authError');
        throw ServerException(message: 'Error getting user details: $authError');
      }
    }
  }

  @override
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
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
      if (e is PostgrestException) {
        throw ServerException(message: 'Database error: ${e.message}. Details: ${e.details}');
      } else {
        throw ServerException(message: 'Error adding address: ${e.toString()}');
      }
    }
  }

  @override
  Future<Address> updateAddress(String userId, Address address) async {
    try {
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

      // Prepare data for update, ensuring no null values for required fields
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
      if (e is PostgrestException) {
        throw ServerException(message: 'Database error: ${e.message}. Details: ${e.details}');
      } else {
        throw ServerException(message: 'Error updating address: ${e.toString()}');
      }
    }
  }

  @override
  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      debugPrint('UserProfileDataSourceImpl: Deleting address $addressId for user $userId');

      // Check if the address exists and belongs to the user
      final addressResponse = await client
          .from('addresses')
          .select('id, is_default')
          .eq('id', addressId)
          .eq('user_id', userId)
          .maybeSingle();

      if (addressResponse == null) {
        debugPrint('UserProfileDataSourceImpl: Address not found or does not belong to user');
        throw ServerException(message: 'Address not found or does not belong to user');
      }

      final isDefault = addressResponse['is_default'] ?? false;
      debugPrint('UserProfileDataSourceImpl: Address is default: $isDefault');

      // Check if the address is referenced by any orders
      try {
        // First check if the orders table has shipping_address_id or billing_address_id columns
        final ordersColumns = await client
            .from('information_schema.columns')
            .select('column_name')
            .eq('table_name', 'orders')
            .eq('table_schema', 'public');

        debugPrint('UserProfileDataSourceImpl: Orders table columns: $ordersColumns');

        final hasShippingAddressId =
            (ordersColumns as List<dynamic>).any((col) => col['column_name'] == 'shipping_address_id');

        final hasBillingAddressId =
            ordersColumns.any((col) => col['column_name'] == 'billing_address_id');

        debugPrint('UserProfileDataSourceImpl: Has shipping_address_id: $hasShippingAddressId, Has billing_address_id: $hasBillingAddressId');

        // Check for references in shipping_address_id
        if (hasShippingAddressId) {
          final shippingOrdersResponse = await client
              .from('orders')
              .select('id')
              .eq('shipping_address_id', addressId)
              .limit(1);

          if (shippingOrdersResponse.isNotEmpty) {
            debugPrint('UserProfileDataSourceImpl: Cannot delete address: It is used as shipping address in orders');
            throw ServerException(
              message: 'Cannot delete this address because it is used as a shipping address in one or more orders.'
            );
          }
        }

        // Check for references in billing_address_id
        if (hasBillingAddressId) {
          final billingOrdersResponse = await client
              .from('orders')
              .select('id')
              .eq('billing_address_id', addressId)
              .limit(1);

          if (billingOrdersResponse.isNotEmpty) {
            debugPrint('UserProfileDataSourceImpl: Cannot delete address: It is used as billing address in orders');
            throw ServerException(
              message: 'Cannot delete this address because it is used as a billing address in one or more orders.'
            );
          }
        }

        // Also check for JSONB fields
        try {
          final jsonbOrdersResponse = await client
              .from('orders')
              .select('id')
              .or('shipping_address->id.eq.$addressId,billing_address->id.eq.$addressId')
              .limit(1);

          if (jsonbOrdersResponse.isNotEmpty) {
            debugPrint('UserProfileDataSourceImpl: Cannot delete address: It is used in orders JSONB fields');
            throw ServerException(
              message: 'Cannot delete this address because it is used in one or more orders.'
            );
          }
        } catch (e) {
          debugPrint('UserProfileDataSourceImpl: Error checking JSONB fields: $e');
          // Continue if JSONB check fails
        }
      } catch (e) {
        debugPrint('UserProfileDataSourceImpl: Error checking orders table: $e');
        // Continue with deletion attempt
      }

      // Delete the address
      await client
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);

      debugPrint('UserProfileDataSourceImpl: Address deleted successfully');

      // If it was the default address, set a new default if there are other addresses
      if (isDefault) {
        debugPrint('UserProfileDataSourceImpl: Setting new default address');
        final remainingAddresses = await client
            .from('addresses')
            .select('id')
            .eq('user_id', userId)
            .limit(1);

        if (remainingAddresses.isNotEmpty) {
          final newDefaultId = remainingAddresses[0]['id'];
          debugPrint('UserProfileDataSourceImpl: Setting address $newDefaultId as default');
          await client
              .from('addresses')
              .update({'is_default': true})
              .eq('id', newDefaultId)
              .eq('user_id', userId);
        }
      }
      return true;
    } catch (e) {
      debugPrint('UserProfileDataSourceImpl: Exception in deleteAddress: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> setDefaultAddress(String userId, String addressId) async {
    try {
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
        preferences: response['preferences'],
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, String imagePath) async {
    File imageFile = File(imagePath);
    return updateProfileImage(userId, imageFile);
  }

  @override
  Future<bool> deleteProfileImage(String userId) async {
    try {
      await client
          .storage
          .from('user_profiles')
          .remove(['$userId/profile.jpg']);

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> updatePreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final response = await client
          .from('user_preferences')
          .update(preferences)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> updateProfileImage(String userId, File imageFile) async {
    try {
      final response = await client
          .storage
          .from('user_profiles')
          .upload('$userId/profile.jpg', imageFile);

      return response.toString();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}