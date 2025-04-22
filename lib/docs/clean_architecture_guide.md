# Clean Architecture Implementation Guide for Dayliz Application

## Overview

This guide outlines our approach to implementing Clean Architecture in the Dayliz application. The project has migrated from a traditional model/entity pattern to a simplified architecture that uses domain entities directly throughout all layers.

## Key Principles

1. **Domain-Centric Design**: Domain entities are the core of the application and do not depend on any external frameworks or UI components.
2. **Dependency Rule**: Dependencies always point inward, with outer layers depending on inner layers, never the reverse.
3. **Entities as First-Class Citizens**: Domain entities are used directly across all layers instead of creating duplicate model classes.
4. **Separation of Concerns**: Each layer has distinct responsibilities and boundaries.

## Project Structure

```
lib/
├── data/
│   ├── datasources/      # Remote and local data sources
│   └── repositories/     # Repository implementations
├── domain/
│   ├── entities/         # Core domain entities
│   ├── repositories/     # Repository interfaces
│   └── usecases/         # Business logic use cases
├── presentation/
│   ├── bloc/             # State management
│   ├── pages/            # UI screens
│   └── widgets/          # Reusable UI components
└── core/                 # Shared utilities and constants
```

## Layers Explained

### Domain Layer

The innermost layer containing:

1. **Entities**: Core business objects with no dependencies.
2. **Repository Interfaces**: Define methods for data operations without implementation details.
3. **Use Cases**: Encapsulate business logic operations that can be performed in the application.

Example Repository Interface:
```dart
abstract class UserProfileRepository {
  Future<Either<Failure, UserProfile>> getUserProfile(String userId);
  Future<Either<Failure, List<Address>>> getUserAddresses(String userId);
  Future<Either<Failure, Address>> addAddress(String userId, Address address);
  Future<Either<Failure, bool>> deleteAddress(String userId, String addressId);
}
```

### Data Layer

Implements the repositories defined in the domain layer:

1. **Data Sources**: Handle API calls and local storage operations.
2. **Repository Implementations**: Implement repository interfaces, manage network connectivity, and handle exceptions.

Example Repository Implementation:
```dart
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
  Future<Either<Failure, List<Address>>> getUserAddresses(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final addresses = await remoteDataSource.getUserAddresses(userId);
        await localDataSource.cacheUserAddresses(userId, addresses);
        return Right(addresses);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final addresses = await localDataSource.getCachedUserAddresses(userId);
        return Right(addresses);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
```

### Presentation Layer

Manages UI components and user interactions:

1. **BLoC/Cubit**: Manages state and business logic of UI components.
2. **Pages**: Complete screens composing multiple widgets.
3. **Widgets**: Reusable UI components.

## Migration Guidelines

### From Model/Entity Pattern to Direct Entity Usage

Previously, our application used:
- Domain entities for business logic
- Data models for serialization/deserialization

We've simplified this by using domain entities directly across all layers:

1. **Before**:
```dart
// In data layer
class AddressModel extends Address {
  // Duplicate properties and mapping logic
}

// In repositories
Future<List<Address>> getUserAddresses() async {
  List<AddressModel> models = await dataSource.getAddresses();
  return models.map((model) => model as Address).toList();
}
```

2. **After**:
```dart
// Directly use the entity
Future<List<Address>> getUserAddresses() async {
  return await dataSource.getAddresses();
}
```

### Implementation Steps

1. **For Existing Models/Entities**:
   - Add JSON serialization methods to the domain entity if needed
   - Update repositories to work directly with entities
   - Update data sources to return entities directly
   - Remove unnecessary model classes

2. **For New Features**:
   - Create the domain entity with all business logic
   - Define repository interfaces in the domain layer
   - Implement data sources that work directly with entities
   - Create repository implementations that handle error cases and network connectivity
   - Develop presentation layer components that consume entities via repositories

## Error Handling

Implement consistent error handling across the application:

1. **Exceptions**:
   - `ServerException`: For remote data source errors
   - `CacheException`: For local data source errors
   - Always include meaningful error messages

2. **Failures**:
   - `ServerFailure`: For network-related failures
   - `CacheFailure`: For local storage failures
   - Use named parameters for better readability

Example:
```dart
// Exception with message
throw ServerException(message: 'Failed to fetch user addresses');

// Returning failures with dartz's Either
return Left(ServerFailure(message: 'Network error: ${e.message}'));
```

## Testing Guidelines

1. **Entity Tests**: Verify entity behavior and business rules
2. **Repository Tests**: Test repository logic with mocked data sources
3. **UseCase Tests**: Verify business logic with mocked repositories
4. **BLoC/Cubit Tests**: Test state management with mocked use cases

Example Repository Test:
```dart
test('getUserAddresses should return addresses when remote call is successful', () async {
  // Arrange
  when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
  when(mockRemoteDataSource.getUserAddresses(any))
      .thenAnswer((_) async => tAddresses);
  
  // Act
  final result = await repository.getUserAddresses(tUserId);
  
  // Assert
  verify(mockRemoteDataSource.getUserAddresses(tUserId));
  verify(mockLocalDataSource.cacheUserAddresses(tUserId, tAddresses));
  expect(result, equals(Right(tAddresses)));
});
```

## Best Practices

1. **Use Immutable Entities**: Implement `copyWith` methods for updates
2. **Consistent Error Handling**: Use `Either<Failure, T>` for repository return types
3. **Dependency Injection**: Use GetIt for service location and dependency management
4. **Separate Network Logic**: Use a NetworkInfo service to check connectivity status
5. **Test Coverage**: Aim for high test coverage, especially in domain and data layers

## Common Pitfalls to Avoid

1. **Breaking the Dependency Rule**: Never let inner layers depend on outer layers
2. **Circular Dependencies**: Use proper abstractions to prevent circular dependencies
3. **Business Logic in Presentation**: Keep business logic in use cases, not in UI components
4. **Ignoring Error Handling**: Always handle exceptions and convert them to appropriate failures
5. **Duplicating Code**: Favor composition over inheritance for code reuse 