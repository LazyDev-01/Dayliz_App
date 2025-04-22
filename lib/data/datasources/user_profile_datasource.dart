import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

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
      final response = await client
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
          
      return UserProfileModel(
        id: response['id'],
        userId: response['user_id'],
        fullName: response['full_name'],
        displayName: response['display_name'],
        bio: response['bio'],
        profileImageUrl: response['profile_image_url'],
      );
    } catch (e) {
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
        isDefault: item['is_default'] ?? false,
        label: item['label'] ?? 'Home',
      )).toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Future<Address> addAddress(String userId, Address address) async {
    try {
      // If this is the first address or marked as default, ensure it's set as default
      bool shouldBeDefault = address.isDefault;
      
      if (!shouldBeDefault) {
        // Check if user has any addresses
        final existingAddresses = await client
            .from('addresses')
            .select('id')
            .eq('user_id', userId);
            
        // If no addresses exist, make this the default
        if (existingAddresses.isEmpty) {
          shouldBeDefault = true;
        }
      }
      
      // If setting as default, reset any existing default addresses
      if (shouldBeDefault) {
        await client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true);
      }
      
      final data = {
        'user_id': userId,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'is_default': shouldBeDefault,
        'label': address.label,
      };
      
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
        isDefault: response['is_default'] ?? false,
        label: response['label'] ?? 'Home',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
  
  @override
  Future<Address> updateAddress(String userId, Address address) async {
    try {
      // If setting as default, reset any existing default addresses
      if (address.isDefault) {
        await client
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', userId)
            .eq('is_default', true)
            .neq('id', address.id);
      }
      
      final data = {
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'is_default': address.isDefault,
        'label': address.label,
      };
      
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
        isDefault: response['is_default'] ?? false,
        label: response['label'] ?? 'Home',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
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
        displayName: response['display_name'],
        bio: response['bio'],
        profileImageUrl: response['profile_image_url'],
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