import 'dart:io';

import 'package:dartz/dartz.dart';

import '../entities/user_profile.dart';
import '../entities/address.dart';
import '../../core/errors/failures.dart';

/// Repository interface for user profile operations
abstract class UserProfileRepository {
  /// Get user profile by ID
  /// Returns a [Either] with a [Failure] or a [UserProfile]
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);
  
  /// Update user profile
  /// Returns a [Either] with a [Failure] or the updated [UserProfile]
  Future<Either<Failure, UserProfile>> updateUserProfile(UserProfile profile);
  
  /// Update profile image and return the path or URL
  /// Returns a [Either] with a [Failure] or the image URL as [String]
  Future<Either<Failure, String>> updateProfileImage(String userId, File imageFile);
  
  /// Delete profile image
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> deleteProfileImage(String userId);
  
  /// Get all addresses for a user
  /// Returns a [Either] with a [Failure] or a [List] of [Address]
  Future<Either<Failure, List<Address>>> getUserAddresses(String userId);
  
  /// Add a new address
  /// Returns a [Either] with a [Failure] or the added [Address]
  Future<Either<Failure, Address>> addAddress(String userId, Address address);
  
  /// Update an existing address
  /// Returns a [Either] with a [Failure] or the updated [Address]
  Future<Either<Failure, Address>> updateAddress(String userId, Address address);
  
  /// Delete an address
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> deleteAddress(String userId, String addressId);
  
  /// Set an address as the default
  /// Returns a [Either] with a [Failure] or a [bool] indicating success
  Future<Either<Failure, bool>> setDefaultAddress(String userId, String addressId);
  
  /// Update user preferences
  /// Returns a [Either] with a [Failure] or the updated preferences [Map]
  Future<Either<Failure, Map<String, dynamic>>> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  );
} 