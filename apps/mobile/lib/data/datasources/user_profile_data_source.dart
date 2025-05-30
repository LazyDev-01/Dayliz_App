import 'dart:io';

import '../../domain/entities/address.dart';
import '../models/user_profile_model.dart';

/// Interface for user profile data operations
abstract class UserProfileDataSource {
  // Keys for local storage
  static const String USER_PROFILE_KEY = 'USER_PROFILES';
  static const String USER_ADDRESSES_KEY = 'USER_ADDRESSES';
  static const String USER_PREFERENCES_KEY = 'USER_PREFERENCES';
  
  /// Fetches a user profile by user ID
  Future<UserProfileModel> getUserProfile(String userId);
  
  /// Updates a user profile
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile);
  
  /// Updates the profile image and returns the path or URL
  Future<String> updateProfileImage(String userId, File imageFile);
  
  /// Deletes the profile image
  Future<bool> deleteProfileImage(String userId);
  
  /// Gets a list of addresses for a user
  Future<List<Address>> getUserAddresses(String userId);
  
  /// Adds a new address for a user
  Future<Address> addAddress(String userId, Address address);
  
  /// Updates an existing address
  Future<Address> updateAddress(String userId, Address address);
  
  /// Deletes an address
  Future<bool> deleteAddress(String userId, String addressId);
  
  /// Sets an address as the default address
  Future<bool> setDefaultAddress(String userId, String addressId);
  
  /// Updates user preferences
  Future<Map<String, dynamic>> updateUserPreferences(String userId, Map<String, dynamic> preferences);
} 