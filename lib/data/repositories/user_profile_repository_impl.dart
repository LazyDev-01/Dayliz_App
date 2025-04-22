import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/address.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/user_profile_repository.dart';
import '../datasources/user_profile_data_source.dart';
import '../models/user_profile_model.dart';

/// Implementation of [UserProfileRepository] that manages user profile data
class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource remoteDataSource;
  final UserProfileDataSource localDataSource;
  final NetworkInfo networkInfo;

  UserProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

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

  @override
  Future<Either<Failure, bool>> setDefaultAddress(String userId, String addressId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.setDefaultAddress(userId, addressId);
        // Update local cache
        await localDataSource.setDefaultAddress(userId, addressId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        // Update locally and queue for remote update when connection is restored
        final result = await localDataSource.setDefaultAddress(userId, addressId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

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
                displayName: profile.displayName,
                bio: profile.bio,
                profileImageUrl: profile.profileImageUrl,
                dateOfBirth: profile.dateOfBirth,
                gender: profile.gender,
                isPublic: profile.isPublic,
                lastUpdated: profile.lastUpdated,
                preferences: profile.preferences,
                addresses: profile.addresses,
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
                displayName: profile.displayName,
                bio: profile.bio,
                profileImageUrl: profile.profileImageUrl,
                dateOfBirth: profile.dateOfBirth,
                gender: profile.gender,
                isPublic: profile.isPublic,
                lastUpdated: profile.lastUpdated,
                preferences: profile.preferences,
                addresses: profile.addresses,
              );
                
        // Update locally and queue for remote update when connection is restored
        final updatedProfile = await localDataSource.updateUserProfile(profileModel);
        return Right(updatedProfile);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, String>> updateProfileImage(String userId, File imageFile) async {
    if (await networkInfo.isConnected) {
      try {
        final imagePath = await remoteDataSource.updateProfileImage(userId, imageFile);
        // Update local cache
        await localDataSource.updateProfileImage(userId, imageFile);
        return Right(imagePath);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteProfileImage(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteProfileImage(userId);
        // Update local cache
        await localDataSource.deleteProfileImage(userId);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.updateUserPreferences(userId, preferences);
        // Update local cache
        await localDataSource.updateUserPreferences(userId, preferences);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        // Update locally and queue for remote update when connection is restored
        final result = await localDataSource.updateUserPreferences(userId, preferences);
        return Right(result);
      } on ServerException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
} 