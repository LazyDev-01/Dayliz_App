import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
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
    try {
      debugPrint('Fetching user profile for user ID: $userId');

      // Try to get the existing profile
      try {
        final response = await client
            .from('user_profiles')
            .select()
            .eq('user_id', userId)
            .single();

        debugPrint('Found existing profile with ID: ${response['id']}');
        debugPrint('FULL RESPONSE: $response');
        debugPrint('Available keys: ${response.keys.toList()}');
        debugPrint('Profile data - fullName: ${response['full_name']}');
        debugPrint('Profile data - name: ${response['name']}');
        debugPrint('Profile data - fullname: ${response['fullname']}');
        debugPrint('Profile data - fullName: ${response['fullName']}');

        // Try to find the fullName field, checking different possible field names
        String? profileFullName = response['full_name'];
        if (profileFullName == null) {
          // Try alternative field names
          if (response.containsKey('name')) {
            profileFullName = response['name'];
            debugPrint('Using "name" field instead: $profileFullName');
          } else if (response.containsKey('fullname')) {
            profileFullName = response['fullname'];
            debugPrint('Using "fullname" field instead: $profileFullName');
          } else if (response.containsKey('fullName')) {
            profileFullName = response['fullName'];
            debugPrint('Using "fullName" field instead: $profileFullName');
          } else if (response.containsKey('user_name')) {
            profileFullName = response['user_name'];
            debugPrint('Using "user_name" field instead: $profileFullName');
          }
        }

        debugPrint('Final fullName value: $profileFullName');

        return UserProfileModel(
          id: response['id'],
          userId: response['user_id'],
          fullName: profileFullName,
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
        // Profile doesn't exist, create a new one
        debugPrint('Profile not found, creating a new one for user ID: $userId');

        // Get user details from auth to populate the profile
        final user = await client.auth.admin.getUserById(userId);
        final email = user.user?.email;

        // Try to get the name from user metadata first, then fall back to email
        String? fullName;
        if (user.user?.userMetadata != null && user.user!.userMetadata!.containsKey('name')) {
          fullName = user.user!.userMetadata!['name'];
          debugPrint('Using name from user metadata: $fullName');
        } else {
          fullName = email != null ? email.split('@')[0] : 'User'; // Use part of email as name
          debugPrint('No name in metadata, using email-based name: $fullName');
        }

        debugPrint('Creating profile with fullName: $fullName');

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

        debugPrint('Created new profile with ID: ${response['id']}');

        // Debug the response
        debugPrint('FULL RESPONSE for new profile: $response');
        debugPrint('Available keys: ${response.keys.toList()}');

        // Try to find the fullName field, checking different possible field names
        String? profileFullName = response['full_name'];
        if (profileFullName == null) {
          // Try alternative field names
          if (response.containsKey('name')) {
            profileFullName = response['name'];
            debugPrint('Using "name" field instead: $profileFullName');
          } else if (response.containsKey('fullname')) {
            profileFullName = response['fullname'];
            debugPrint('Using "fullname" field instead: $profileFullName');
          } else if (response.containsKey('fullName')) {
            profileFullName = response['fullName'];
            debugPrint('Using "fullName" field instead: $profileFullName');
          } else if (response.containsKey('user_name')) {
            profileFullName = response['user_name'];
            debugPrint('Using "user_name" field instead: $profileFullName');
          }
        }

        debugPrint('Final fullName value for new profile: $profileFullName');

        return UserProfileModel(
          id: response['id'],
          userId: response['user_id'],
          fullName: profileFullName,
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
      }
    } catch (e) {
      debugPrint('Error getting/creating user profile: $e');
      throw ServerException(message: e.toString());
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
      // Check if the address is the default one
      final addressResponse = await client
          .from('addresses')
          .select('is_default')
          .eq('id', addressId)
          .eq('user_id', userId)
          .single();

      final isDefault = addressResponse['is_default'] ?? false;

      // Delete the address
      await client
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);

      // If it was the default address, set a new default if there are other addresses
      if (isDefault) {
        final remainingAddresses = await client
            .from('addresses')
            .select('id')
            .eq('user_id', userId)
            .limit(1);

        if (remainingAddresses.isNotEmpty) {
          final newDefaultId = remainingAddresses[0]['id'];
          await client
              .from('addresses')
              .update({'is_default': true})
              .eq('id', newDefaultId)
              .eq('user_id', userId);
        }
      }
      return true;
    } catch (e) {
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