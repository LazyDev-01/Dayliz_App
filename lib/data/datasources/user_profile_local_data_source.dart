import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../models/user_profile_model.dart';
import 'user_profile_data_source.dart';

/// Implementation of [UserProfileDataSource] for local operations
class UserProfileLocalDataSource implements UserProfileDataSource {
  final SharedPreferences sharedPreferences;

  // Keys for SharedPreferences
  static const String USER_PROFILE_KEY = 'USER_PROFILE_';
  static const String USER_ADDRESSES_KEY = 'USER_ADDRESSES_';
  static const String USER_PREFERENCES_KEY = 'USER_PREFERENCES_';

  UserProfileLocalDataSource({required this.sharedPreferences});

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final profilesJsonString = sharedPreferences.getString(USER_PROFILE_KEY);
      if (profilesJsonString == null) {
        throw ServerException(message: 'No user profiles found');
      }

      final List<dynamic> profilesList = json.decode(profilesJsonString);
      final profileJson = profilesList.firstWhere(
        (profile) => profile['user_id'] == userId,
        orElse: () => throw ServerException(message: 'User profile not found'),
      );

      return UserProfileModel.fromMap(profileJson);
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    try {
      final profilesJsonString = sharedPreferences.getString(USER_PROFILE_KEY);
      List<dynamic> profilesList = [];

      if (profilesJsonString != null) {
        profilesList = json.decode(profilesJsonString);

        // Find and update the profile
        final index = profilesList.indexWhere((p) => p['id'] == profile.id);
        if (index != -1) {
          profilesList[index] = profile.toMap();
        } else {
          profilesList.add(profile.toMap());
        }
      } else {
        profilesList.add(profile.toMap());
      }

      await sharedPreferences.setString(
        USER_PROFILE_KEY,
        json.encode(profilesList),
      );

      return profile;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, String imagePath) async {
    // For local data source, we just need to update the profile image URL in the existing profile
    try {
      final profileJson = sharedPreferences.getString(USER_PROFILE_KEY);

      if (profileJson != null) {
        final profile = UserProfileModel.fromJson(json.decode(profileJson));
        final updatedProfile = profile.copyWithModel(
          profileImageUrl: imagePath,
          lastUpdated: DateTime.now(),
        );

        await updateUserProfile(updatedProfile);

        return imagePath;
      } else {
        throw ServerException(message: 'No cached user profile found');
      }
    } catch (e) {
      throw ServerException(message: 'Failed to update profile image: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteProfileImage(String userId) async {
    try {
      final profileJson = sharedPreferences.getString(USER_PROFILE_KEY);

      if (profileJson != null) {
        final profilesList = json.decode(profileJson) as List<dynamic>;
        final index = profilesList.indexWhere((profile) => profile['user_id'] == userId);

        if (index != -1) {
          profilesList[index]['profile_image_url'] = '';
          await sharedPreferences.setString(
            USER_PROFILE_KEY,
            json.encode(profilesList),
          );
          return true;
        } else {
          throw ServerException(message: 'No cached user profile found');
        }
      } else {
        throw ServerException(message: 'No cached user profile found');
      }
    } catch (e) {
      throw ServerException(message: 'Failed to delete profile image: ${e.toString()}');
    }
  }

  @override
  Future<String> updateProfileImage(String userId, File imageFile) async {
    try {
      final profilesJsonString = sharedPreferences.getString(USER_PROFILE_KEY);

      if (profilesJsonString != null) {
        final profilesList = json.decode(profilesJsonString) as List<dynamic>;
        final index = profilesList.indexWhere((profile) => profile['user_id'] == userId);

        if (index != -1) {
          // Save the image path in local storage
          final imagePath = 'local_storage/${imageFile.path.split('/').last}';
          profilesList[index]['profile_image_url'] = imagePath;

          await sharedPreferences.setString(
            USER_PROFILE_KEY,
            json.encode(profilesList),
          );

          return imagePath;
        } else {
          throw ServerException(message: 'No cached user profile found');
        }
      } else {
        throw ServerException(message: 'No cached user profile found');
      }
    } catch (e) {
      throw ServerException(message: 'Failed to update profile image: ${e.toString()}');
    }
  }

  @override
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final addressesJsonString = sharedPreferences.getString(USER_ADDRESSES_KEY);
      if (addressesJsonString == null) {
        return [];
      }

      final List<dynamic> allAddresses = json.decode(addressesJsonString);
      final userAddresses = allAddresses.where((addr) => addr['user_id'] == userId).toList();

      return userAddresses.map((address) => Address(
        id: address['id'],
        userId: address['user_id'],
        addressLine1: address['address_line1'],
        addressLine2: address['address_line2'] ?? '',
        city: address['city'],
        state: address['state'],
        postalCode: address['postal_code'],
        country: address['country'],
        phoneNumber: address['phone_number'],
        isDefault: address['is_default'] ?? false,
        // Label field removed
        additionalInfo: address['additional_info'],
        latitude: address['latitude'] != null ?
            double.tryParse(address['latitude'].toString()) : null,
        longitude: address['longitude'] != null ?
            double.tryParse(address['longitude'].toString()) : null,
        landmark: address['landmark'],
        zoneId: address['zone_id'],
        addressType: address['address_type'],
        recipientName: address['recipient_name'],
        createdAt: address['created_at'] != null ? DateTime.parse(address['created_at'].toString()) : null,
        updatedAt: address['updated_at'] != null ? DateTime.parse(address['updated_at'].toString()) : null,
      )).toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Address> addAddress(String userId, Address address) async {
    try {
      List<Address> addresses;
      final addressesJsonString = sharedPreferences.getString(USER_ADDRESSES_KEY);

      if (addressesJsonString != null) {
        final List<dynamic> allAddresses = json.decode(addressesJsonString);
        addresses = allAddresses
          .map((addrJson) => Address(
            id: addrJson['id'],
            userId: addrJson['user_id'],
            addressLine1: addrJson['address_line1'],
            addressLine2: addrJson['address_line2'] ?? '',
            city: addrJson['city'],
            state: addrJson['state'],
            postalCode: addrJson['postal_code'],
            country: addrJson['country'],
            phoneNumber: addrJson['phone_number'],
            isDefault: addrJson['is_default'] ?? false,
            // Label field removed
            additionalInfo: addrJson['additional_info'],
            latitude: addrJson['latitude'] != null ?
                double.tryParse(addrJson['latitude'].toString()) : null,
            longitude: addrJson['longitude'] != null ?
                double.tryParse(addrJson['longitude'].toString()) : null,
            landmark: addrJson['landmark'],
            zoneId: addrJson['zone_id'],
            addressType: addrJson['address_type'],
            recipientName: addrJson['recipient_name'],
            createdAt: addrJson['created_at'] != null ? DateTime.parse(addrJson['created_at'].toString()) : null,
            updatedAt: addrJson['updated_at'] != null ? DateTime.parse(addrJson['updated_at'].toString()) : null,
          ))
          .toList();
      } else {
        addresses = [];
      }

      // Create the new address with a unique ID if one wasn't provided
      final newAddress = address.id.isEmpty
          ? address.copyWith(id: const Uuid().v4())
          : address;

      // Set as default if this is the first address or explicitly requested
      if (addresses.isEmpty || newAddress.isDefault) {
        // Reset default status of all other addresses if needed
        if (newAddress.isDefault) {
          addresses = addresses.map((a) => a.copyWith(isDefault: false)).toList();
        }
      }

      // Add the new address
      addresses.add(newAddress);

      // Save to SharedPreferences
      await sharedPreferences.setString(
        USER_ADDRESSES_KEY,
        json.encode(
          addresses.map((a) => {
            'id': a.id,
            'user_id': a.userId,
            'address_line1': a.addressLine1,
            'address_line2': a.addressLine2,
            'city': a.city,
            'state': a.state,
            'postal_code': a.postalCode,
            'country': a.country,
            'phone_number': a.phoneNumber,
            'is_default': a.isDefault,
            // Label field removed
            'additional_info': a.additionalInfo,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'landmark': a.landmark,
            'zone_id': a.zoneId,
            'address_type': a.addressType,
            'recipient_name': a.recipientName,
            'created_at': a.createdAt?.toIso8601String(),
            'updated_at': a.updatedAt?.toIso8601String(),
          }).toList()
        ),
      );

      return newAddress;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Address> updateAddress(String userId, Address address) async {
    try {
      final addressesJsonString = sharedPreferences.getString(USER_ADDRESSES_KEY);
      if (addressesJsonString == null) {
        throw ServerException(message: 'No addresses found');
      }

      List<Address> addresses = (json.decode(addressesJsonString) as List)
        .map((addrJson) => Address(
          id: addrJson['id'],
          userId: addrJson['user_id'],
          addressLine1: addrJson['address_line1'],
          addressLine2: addrJson['address_line2'] ?? '',
          city: addrJson['city'],
          state: addrJson['state'],
          postalCode: addrJson['postal_code'],
          country: addrJson['country'],
          phoneNumber: addrJson['phone_number'],
          isDefault: addrJson['is_default'] ?? false,
          // Label field removed
          additionalInfo: addrJson['additional_info'],
          latitude: addrJson['latitude'] != null ?
              double.tryParse(addrJson['latitude'].toString()) : null,
          longitude: addrJson['longitude'] != null ?
              double.tryParse(addrJson['longitude'].toString()) : null,
          landmark: addrJson['landmark'],
          zoneId: addrJson['zone_id'],
          addressType: addrJson['address_type'],
          recipientName: addrJson['recipient_name'],
          createdAt: addrJson['created_at'] != null ? DateTime.parse(addrJson['created_at'].toString()) : null,
          updatedAt: addrJson['updated_at'] != null ? DateTime.parse(addrJson['updated_at'].toString()) : null,
        ))
        .toList();

      final index = addresses.indexWhere((a) => a.id == address.id);
      if (index == -1) {
        throw ServerException(message: 'Address not found');
      }

      // If setting as default, reset any existing default addresses
      if (address.isDefault) {
        for (int i = 0; i < addresses.length; i++) {
          if (i != index && addresses[i].isDefault) {
            addresses[i] = addresses[i].copyWith(isDefault: false);
          }
        }
      }

      // Update the address
      addresses[index] = address;

      // Save to SharedPreferences
      await sharedPreferences.setString(
        USER_ADDRESSES_KEY,
        json.encode(
          addresses.map((a) => {
            'id': a.id,
            'user_id': a.userId,
            'address_line1': a.addressLine1,
            'address_line2': a.addressLine2,
            'city': a.city,
            'state': a.state,
            'postal_code': a.postalCode,
            'country': a.country,
            'phone_number': a.phoneNumber,
            'is_default': a.isDefault,
            // Label field removed
            'additional_info': a.additionalInfo,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'landmark': a.landmark,
            'zone_id': a.zoneId,
            'address_type': a.addressType,
            'recipient_name': a.recipientName,
            'created_at': a.createdAt?.toIso8601String(),
            'updated_at': a.updatedAt?.toIso8601String(),
          }).toList()
        ),
      );

      return address;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      final addressesJsonString = sharedPreferences.getString(USER_ADDRESSES_KEY);
      if (addressesJsonString == null) {
        return false;
      }

      List<Address> addresses = (json.decode(addressesJsonString) as List)
        .map((addrJson) => Address(
          id: addrJson['id'],
          userId: addrJson['user_id'],
          addressLine1: addrJson['address_line1'],
          addressLine2: addrJson['address_line2'] ?? '',
          city: addrJson['city'],
          state: addrJson['state'],
          postalCode: addrJson['postal_code'],
          country: addrJson['country'],
          phoneNumber: addrJson['phone_number'],
          isDefault: addrJson['is_default'] ?? false,
          // Label field removed
          additionalInfo: addrJson['additional_info'],
          latitude: addrJson['latitude'] != null ?
              double.tryParse(addrJson['latitude'].toString()) : null,
          longitude: addrJson['longitude'] != null ?
              double.tryParse(addrJson['longitude'].toString()) : null,
          landmark: addrJson['landmark'],
          zoneId: addrJson['zone_id'],
          addressType: addrJson['address_type'],
          recipientName: addrJson['recipient_name'],
          createdAt: addrJson['created_at'] != null ? DateTime.parse(addrJson['created_at'].toString()) : null,
          updatedAt: addrJson['updated_at'] != null ? DateTime.parse(addrJson['updated_at'].toString()) : null,
        ))
        .toList();

      final filteredAddresses = addresses.where((a) => a.id != addressId).toList();

      // Save the filtered list
      await sharedPreferences.setString(
        USER_ADDRESSES_KEY,
        json.encode(
          filteredAddresses.map((a) => {
            'id': a.id,
            'user_id': a.userId,
            'address_line1': a.addressLine1,
            'address_line2': a.addressLine2,
            'city': a.city,
            'state': a.state,
            'postal_code': a.postalCode,
            'country': a.country,
            'phone_number': a.phoneNumber,
            'is_default': a.isDefault,
            // Label field removed
            'additional_info': a.additionalInfo,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'landmark': a.landmark,
            'zone_id': a.zoneId,
            'address_type': a.addressType,
            'recipient_name': a.recipientName,
            'created_at': a.createdAt?.toIso8601String(),
            'updated_at': a.updatedAt?.toIso8601String(),
          }).toList()
        ),
      );

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> setDefaultAddress(String userId, String addressId) async {
    try {
      final addressesJsonString = sharedPreferences.getString(USER_ADDRESSES_KEY);
      if (addressesJsonString == null) {
        return false;
      }

      List<Address> addresses = (json.decode(addressesJsonString) as List)
        .map((addrJson) => Address(
          id: addrJson['id'],
          userId: addrJson['user_id'],
          addressLine1: addrJson['address_line1'],
          addressLine2: addrJson['address_line2'] ?? '',
          city: addrJson['city'],
          state: addrJson['state'],
          postalCode: addrJson['postal_code'],
          country: addrJson['country'],
          phoneNumber: addrJson['phone_number'],
          isDefault: addrJson['is_default'] ?? false,
          // Label field removed
          additionalInfo: addrJson['additional_info'],
          latitude: addrJson['latitude'] != null ?
              double.tryParse(addrJson['latitude'].toString()) : null,
          longitude: addrJson['longitude'] != null ?
              double.tryParse(addrJson['longitude'].toString()) : null,
          landmark: addrJson['landmark'],
          zoneId: addrJson['zone_id'],
          addressType: addrJson['address_type'],
          recipientName: addrJson['recipient_name'],
          createdAt: addrJson['created_at'] != null ? DateTime.parse(addrJson['created_at'].toString()) : null,
          updatedAt: addrJson['updated_at'] != null ? DateTime.parse(addrJson['updated_at'].toString()) : null,
        ))
        .toList();

      final index = addresses.indexWhere((a) => a.id == addressId);
      if (index == -1) {
        return false;
      }

      // Reset default status on all addresses
      for (int i = 0; i < addresses.length; i++) {
        addresses[i] = addresses[i].copyWith(isDefault: i == index);
      }

      // Save to SharedPreferences
      await sharedPreferences.setString(
        USER_ADDRESSES_KEY,
        json.encode(
          addresses.map((a) => {
            'id': a.id,
            'user_id': a.userId,
            'address_line1': a.addressLine1,
            'address_line2': a.addressLine2,
            'city': a.city,
            'state': a.state,
            'postal_code': a.postalCode,
            'country': a.country,
            'phone_number': a.phoneNumber,
            'is_default': a.isDefault,
            // Label field removed
            'additional_info': a.additionalInfo,
            'latitude': a.latitude,
            'longitude': a.longitude,
            'landmark': a.landmark,
            'zone_id': a.zoneId,
            'address_type': a.addressType,
            'recipient_name': a.recipientName,
            'created_at': a.createdAt?.toIso8601String(),
            'updated_at': a.updatedAt?.toIso8601String(),
          }).toList()
        ),
      );

      return true;
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  // This method is for internal use
  Future<Map<String, dynamic>> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      // Get existing preferences
      Map<String, dynamic> existingPreferences = {};

      final preferencesJson = sharedPreferences.getString(USER_PREFERENCES_KEY);

      if (preferencesJson != null) {
        existingPreferences = json.decode(preferencesJson);
      }

      // Merge existing and new preferences
      existingPreferences.addAll(preferences);

      // Save preferences
      await sharedPreferences.setString(
        USER_PREFERENCES_KEY,
        json.encode(existingPreferences)
      );

      return existingPreferences;
    } catch (e) {
      throw ServerException(message: 'Failed to update preferences: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      // Get existing preferences
      Map<String, dynamic> existingPreferences = {};

      final preferencesJson = sharedPreferences.getString(USER_PREFERENCES_KEY);

      if (preferencesJson != null) {
        final allPreferences = json.decode(preferencesJson) as Map<String, dynamic>;
        if (allPreferences.containsKey(userId)) {
          existingPreferences = Map<String, dynamic>.from(allPreferences[userId]);
        }
      }

      // Update with new preferences
      existingPreferences.addAll(preferences);

      // Get all preferences
      final allPreferences = preferencesJson != null
          ? json.decode(preferencesJson) as Map<String, dynamic>
          : <String, dynamic>{};

      // Update the user's preferences
      allPreferences[userId] = existingPreferences;

      // Save preferences
      await sharedPreferences.setString(
        USER_PREFERENCES_KEY,
        json.encode(allPreferences)
      );

      return existingPreferences;
    } catch (e) {
      throw ServerException(message: 'Failed to update preferences: ${e.toString()}');
    }
  }
}