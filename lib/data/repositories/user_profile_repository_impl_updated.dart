import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_data_source.dart';
import '../models/address_model.dart';
import '../models/user_profile_model.dart';

/// Implementation of the UserProfileRepository that uses both remote and local data sources
/// Updated to use the new database features for improved performance
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource remoteDataSource;
  final UserProfileDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SupabaseClient supabaseClient;

  UserProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.supabaseClient,
  });

  /// Get a user profile by user ID
  @override
  Future<Either<Failure, UserProfile>> getUserProfile(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final userProfile = await remoteDataSource.getUserProfile(userId);
        // Cache the result locally
        await localDataSource.updateUserProfile(userProfile);
        return Right(userProfile);
      } on ServerException catch (e) {
        // If server fails, try to get from local cache
        try {
          final localUserProfile = await localDataSource.getUserProfile(userId);
          return Right(localUserProfile);
        } on ServerException {
          return Left(ServerFailure(message: e.message));
        }
      }
    } else {
      try {
        final localUserProfile = await localDataSource.getUserProfile(userId);
        return Right(localUserProfile);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Get all addresses for a user
  @override
  Future<Either<Failure, List<Address>>> getUserAddresses(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final addresses = await remoteDataSource.getUserAddresses(userId);
        // Cache addresses locally
        await Future.forEach(addresses, (Address address) async {
          await localDataSource.addAddress(userId, address);
        });
        return Right(addresses);
      } on ServerException catch (e) {
        // If server fails, try to get from local cache
        try {
          final localAddresses = await localDataSource.getUserAddresses(userId);
          return Right(localAddresses);
        } on ServerException {
          return Left(ServerFailure(message: e.message));
        }
      }
    } else {
      try {
        final localAddresses = await localDataSource.getUserAddresses(userId);
        return Right(localAddresses);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Find addresses within a radius of a location
  /// Uses the new find_addresses_within_radius database function
  @override
  Future<Either<Failure, List<Address>>> findAddressesWithinRadius({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String? userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await supabaseClient.rpc(
          'find_addresses_within_radius',
          params: {
            'lat': latitude,
            'lng': longitude,
            'radius_meters': radiusMeters,
            'user_id_param': userId,
          },
        );
        
        if (result.error != null) {
          return Left(ServerFailure(message: result.error!.message));
        }
        
        final addresses = (result.data as List).map((item) {
          return AddressModel(
            id: item['address_id'],
            userId: item['user_id'],
            addressLine1: item['address_line1'],
            addressLine2: item['address_line2'] ?? '',
            city: item['city'],
            state: item['state'],
            postalCode: item['postal_code'],
            country: item['country'],
            phoneNumber: item['phone_number'],
            isDefault: item['is_default'] ?? false,
            addressType: item['address_type'],
            recipientName: item['recipient_name'],
            latitude: item['latitude'],
            longitude: item['longitude'],
          );
        }).toList();
        
        return Right(addresses);
      } on PostgrestException catch (e) {
        return Left(ServerFailure(message: 'Database error: ${e.message}'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Find the nearest zone for an address
  /// Uses the new find_nearest_zone database function
  @override
  Future<Either<Failure, Map<String, dynamic>>> findNearestZone({
    required double latitude,
    required double longitude,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await supabaseClient.rpc(
          'find_nearest_zone',
          params: {
            'lat': latitude,
            'lng': longitude,
          },
        );
        
        if (result.error != null) {
          return Left(ServerFailure(message: result.error!.message));
        }
        
        if (result.data == null || (result.data as List).isEmpty) {
          return Left(ServerFailure(message: 'No zones found near this location'));
        }
        
        final zoneData = result.data[0];
        return Right({
          'zone_id': zoneData['zone_id'],
          'zone_name': zoneData['zone_name'],
          'distance_meters': zoneData['distance_meters'],
        });
      } on PostgrestException catch (e) {
        return Left(ServerFailure(message: 'Database error: ${e.message}'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  /// Add a new address for a user
  @override
  Future<Either<Failure, Address>> addAddress(String userId, Address address) async {
    if (await networkInfo.isConnected) {
      try {
        final newAddress = await remoteDataSource.addAddress(userId, address);
        // Add to local cache
        await localDataSource.addAddress(userId, newAddress);
        return Right(newAddress);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        // Add locally and queue for remote update when connection is restored
        final newAddress = await localDataSource.addAddress(userId, address);
        return Right(newAddress);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Update an existing address
  @override
  Future<Either<Failure, Address>> updateAddress(String userId, Address address) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedAddress = await remoteDataSource.updateAddress(userId, address);
        // Update local cache
        await localDataSource.updateAddress(userId, updatedAddress);
        return Right(updatedAddress);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        // Update locally and queue for remote update when connection is restored
        final updatedAddress = await localDataSource.updateAddress(userId, address);
        return Right(updatedAddress);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Delete an address
  @override
  Future<Either<Failure, bool>> deleteAddress(String userId, String addressId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteAddress(userId, addressId);
        // Update local cache
        await localDataSource.deleteAddress(userId, addressId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        // Delete locally and queue for remote update when connection is restored
        final result = await localDataSource.deleteAddress(userId, addressId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Update a user profile
  @override
  Future<Either<Failure, UserProfile>> updateUserProfile(UserProfile profile) async {
    if (await networkInfo.isConnected) {
      try {
        // Convert UserProfile to UserProfileModel if needed
        final profileModel = profile is UserProfileModel
            ? profile
            : UserProfileModel(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                profileImageUrl: profile.profileImageUrl,
                dateOfBirth: profile.dateOfBirth,
                gender: profile.gender,
                lastUpdated: profile.lastUpdated,
                preferences: profile.preferences,
              );

        final updatedProfile = await remoteDataSource.updateUserProfile(profileModel);
        // Update local cache
        await localDataSource.updateUserProfile(updatedProfile);
        return Right(updatedProfile);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        // Convert UserProfile to UserProfileModel if needed
        final profileModel = profile is UserProfileModel
            ? profile
            : UserProfileModel(
                id: profile.id,
                userId: profile.userId,
                fullName: profile.fullName,
                profileImageUrl: profile.profileImageUrl,
                dateOfBirth: profile.dateOfBirth,
                gender: profile.gender,
                lastUpdated: profile.lastUpdated,
                preferences: profile.preferences,
              );

        // Update locally and queue for remote update when connection is restored
        final updatedProfile = await localDataSource.updateUserProfile(profileModel);
        return Right(updatedProfile);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
