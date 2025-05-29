import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/errors/exceptions.dart';
import '../../core/constants/api_endpoints.dart';
import '../models/user_profile_model.dart';
import 'user_profile_data_source.dart';
import '../apis/storage_file_api.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';

/// Implementation of [UserProfileDataSource] for remote operations
class UserProfileRemoteDataSource implements UserProfileDataSource {
  final http.Client client;
  final StorageFileApi storageFileApi;
  final String baseUrl;

  UserProfileRemoteDataSource({
    required this.client,
    required this.storageFileApi,
    required this.baseUrl,
  });

  /// Helper method to create the headers for API requests
  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<UserProfileModel> getUserProfile(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: _headers(null),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromMap(json.decode(response.body));
      } else {
        throw ServerException(
          message: 'Failed to fetch user profile. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/users/${profile.userId}/profile'),
        headers: _headers(null),
        body: json.encode(profile.toMap()),
      );

      if (response.statusCode == 200) {
        return UserProfileModel.fromMap(json.decode(response.body));
      } else {
        throw ServerException(
          message: 'Failed to update user profile. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<String> updateProfileImage(String userId, File imageFile) async {
    try {
      // Upload file to storage
      final imagePath = await storageFileApi.uploadFile(
        'user_profiles/$userId/profile_image',
        imageFile,
      );

      // Update the profile with the new image URL
      final response = await client.patch(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: _headers(null),
        body: json.encode({'profileImageUrl': imagePath}),
      );

      if (response.statusCode == 200) {
        return imagePath;
      } else {
        throw ServerException(
          message: 'Failed to update profile image. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to update profile image: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> deleteProfileImage(String userId) async {
    try {
      // Delete file from storage
      await storageFileApi.deleteFile('user_profiles/$userId/profile_image');

      // Update the profile to remove the image URL
      final response = await client.patch(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: _headers(null),
        body: json.encode({'profileImageUrl': ''}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          message: 'Failed to update profile after image deletion. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to delete profile image: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/users/$userId/addresses'),
        headers: _headers(null),
      );

      if (response.statusCode == 200) {
        final List<dynamic> addressesList = json.decode(response.body);
        return addressesList.map((addressJson) => Address(
          id: addressJson['id'],
          userId: addressJson['user_id'],
          addressLine1: addressJson['address_line1'],
          addressLine2: addressJson['address_line2'] ?? '',
          city: addressJson['city'],
          state: addressJson['state'],
          postalCode: addressJson['postal_code'],
          country: addressJson['country'],
          phoneNumber: addressJson['phone_number'],
          isDefault: addressJson['is_default'] ?? false,
          // Label field removed
          additionalInfo: addressJson['additional_info'],
          latitude: addressJson['latitude'] != null ?
              double.tryParse(addressJson['latitude'].toString()) : null,
          longitude: addressJson['longitude'] != null ?
              double.tryParse(addressJson['longitude'].toString()) : null,
          landmark: addressJson['landmark'],
          zoneId: addressJson['zone_id'],
          addressType: addressJson['address_type'],
          recipientName: addressJson['recipient_name'],
          createdAt: addressJson['created_at'] != null ? DateTime.parse(addressJson['created_at'].toString()) : null,
          updatedAt: addressJson['updated_at'] != null ? DateTime.parse(addressJson['updated_at'].toString()) : null,
        )).toList();
      } else {
        throw ServerException(
          message: 'Failed to fetch addresses. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<Address> addAddress(String userId, Address address) async {
    try {
      // Prepare the request body
      final Map<String, dynamic> addressMap = {
        'user_id': userId,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'phone_number': address.phoneNumber,
        'is_default': address.isDefault,
        // Label field removed
        'additional_info': address.additionalInfo,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'landmark': address.landmark,
        'zone_id': address.zoneId,
        'address_type': address.addressType,
        'recipient_name': address.recipientName,
      };

      final response = await client.post(
        Uri.parse('$baseUrl/users/$userId/addresses'),
        headers: _headers(null),
        body: json.encode(addressMap),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Address(
          id: responseData['id'],
          userId: responseData['user_id'],
          addressLine1: responseData['address_line1'],
          addressLine2: responseData['address_line2'] ?? '',
          city: responseData['city'],
          state: responseData['state'],
          postalCode: responseData['postal_code'],
          country: responseData['country'],
          phoneNumber: responseData['phone_number'],
          isDefault: responseData['is_default'] ?? false,
          // Label field removed
          additionalInfo: responseData['additional_info'],
          latitude: responseData['latitude'] != null ?
              double.tryParse(responseData['latitude'].toString()) : null,
          longitude: responseData['longitude'] != null ?
              double.tryParse(responseData['longitude'].toString()) : null,
          landmark: responseData['landmark'],
          zoneId: responseData['zone_id'],
          addressType: responseData['address_type'],
          recipientName: responseData['recipient_name'],
          createdAt: responseData['created_at'] != null ? DateTime.parse(responseData['created_at'].toString()) : null,
          updatedAt: responseData['updated_at'] != null ? DateTime.parse(responseData['updated_at'].toString()) : null,
        );
      } else {
        throw ServerException(
          message: 'Failed to add address. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<Address> updateAddress(String userId, Address address) async {
    try {
      // Prepare the request body
      final Map<String, dynamic> addressMap = {
        'id': address.id,
        'user_id': userId,
        'address_line1': address.addressLine1,
        'address_line2': address.addressLine2,
        'city': address.city,
        'state': address.state,
        'postal_code': address.postalCode,
        'country': address.country,
        'phone_number': address.phoneNumber,
        'is_default': address.isDefault,
        // Label field removed
        'additional_info': address.additionalInfo,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'landmark': address.landmark,
        'zone_id': address.zoneId,
        'address_type': address.addressType,
        'recipient_name': address.recipientName,
      };

      final response = await client.put(
        Uri.parse('$baseUrl/users/$userId/addresses/${address.id}'),
        headers: _headers(null),
        body: json.encode(addressMap),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Address(
          id: responseData['id'],
          userId: responseData['user_id'],
          addressLine1: responseData['address_line1'],
          addressLine2: responseData['address_line2'] ?? '',
          city: responseData['city'],
          state: responseData['state'],
          postalCode: responseData['postal_code'],
          country: responseData['country'],
          phoneNumber: responseData['phone_number'],
          isDefault: responseData['is_default'] ?? false,
          // Label field removed
          additionalInfo: responseData['additional_info'],
          latitude: responseData['latitude'] != null ?
              double.tryParse(responseData['latitude'].toString()) : null,
          longitude: responseData['longitude'] != null ?
              double.tryParse(responseData['longitude'].toString()) : null,
          landmark: responseData['landmark'],
          zoneId: responseData['zone_id'],
          addressType: responseData['address_type'],
          recipientName: responseData['recipient_name'],
          createdAt: responseData['created_at'] != null ? DateTime.parse(responseData['created_at'].toString()) : null,
          updatedAt: responseData['updated_at'] != null ? DateTime.parse(responseData['updated_at'].toString()) : null,
        );
      } else {
        throw ServerException(
          message: 'Failed to update address. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId'),
        headers: _headers(null),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw ServerException(
          message: 'Failed to delete address. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> setDefaultAddress(String userId, String addressId) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/users/$userId/addresses/$addressId/default'),
        headers: _headers(null),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
          message: 'Failed to set default address. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> updateUserPreferences(String userId, Map<String, dynamic> preferences) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/users/$userId/preferences'),
        headers: _headers(null),
        body: json.encode(preferences),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ServerException(
          message: 'Failed to update preferences. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw ServerException(
        message: 'Failed to connect to server: ${e.toString()}',
      );
    }
  }
}