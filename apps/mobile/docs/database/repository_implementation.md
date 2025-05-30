# Repository Implementation for Clean Architecture

This document outlines the implementation of repositories in the clean architecture, focusing on how they interact with the Supabase database.

## Overview

In clean architecture, repositories serve as the bridge between the domain layer and the data layer. They abstract away the details of data storage and retrieval, allowing the domain layer to focus on business logic without being concerned with how data is stored or retrieved.

The repository implementation in the Dayliz App follows these principles:

1. **Domain-Centric**: Repositories return domain entities, not data models
2. **Error Handling**: Repositories handle data source errors and convert them to domain failures
3. **Network Awareness**: Repositories check for network connectivity before making remote requests
4. **Caching**: Repositories cache data locally for offline access

## Repository Structure

Each repository follows a similar structure:

```dart
class SomeRepositoryImpl implements SomeRepository {
  final SomeDataSource remoteDataSource;
  final SomeDataSource localDataSource;
  final NetworkInfo networkInfo;

  SomeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, SomeEntity>> getSomeEntity(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final entity = await remoteDataSource.getSomeEntity(id);
        await localDataSource.cacheSomeEntity(entity);
        return Right(entity);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localEntity = await localDataSource.getSomeEntity(id);
        return Right(localEntity);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
```

## UserProfileRepository Implementation

The `UserProfileRepositoryImpl` is a good example of a repository implementation in the Dayliz App. It handles user profile data and addresses, with methods for retrieving, creating, updating, and deleting data.

### Key Features

1. **Network Awareness**: Checks for network connectivity before making remote requests
2. **Local Caching**: Caches data locally for offline access
3. **Error Handling**: Converts exceptions to domain failures
4. **Entity Mapping**: Maps between data models and domain entities

### Example Methods

#### Get User Profile

```dart
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
```

#### Update User Profile

```dart
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
```

## Data Source Implementation

The repository relies on data sources to interact with the actual data storage. In the Dayliz App, there are two types of data sources:

1. **Remote Data Source**: Interacts with the Supabase database
2. **Local Data Source**: Interacts with local storage (e.g., SharedPreferences, Hive)

### Supabase Data Source

The `UserProfileSupabaseAdapter` is an implementation of the `UserProfileDataSource` interface that uses Supabase to store and retrieve data.

#### Key Features

1. **Supabase Integration**: Uses the Supabase client to interact with the database
2. **Error Handling**: Wraps Supabase errors in domain-specific exceptions
3. **Data Mapping**: Maps between Supabase data and domain entities

#### Example Methods

```dart
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
```

## Conclusion

The repository implementation in the Dayliz App follows clean architecture principles, providing a clean separation between the domain layer and the data layer. By abstracting away the details of data storage and retrieval, the domain layer can focus on business logic without being concerned with how data is stored or retrieved.

The implementation also provides robust error handling, network awareness, and local caching, ensuring that the app can function even when offline.
