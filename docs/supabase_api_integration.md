# Supabase API Integration for Clean Architecture

This document outlines how to integrate Supabase with the clean architecture implementation in the Dayliz App. It provides guidelines for implementing data sources that connect to the Supabase backend while adhering to clean architecture principles.

## Basic Integration Principles

1. **Separation of Concerns**
   - Use the repository pattern to keep database access logic separate from business logic
   - Data sources should implement repository interfaces defined in the domain layer

2. **Error Handling**
   - Map Supabase errors to domain failures (e.g., ServerFailure, CacheFailure)
   - Use Either<Failure, T> for error handling with fpdart library

3. **Model Mapping**
   - Use entity-specific mapping between Supabase JSON and domain entities
   - Create model classes if there's a need for serialization/deserialization

## DataSource Implementation Example

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product.dart';
import '../../core/errors/exceptions.dart';

abstract class ProductRemoteDataSource {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  // Other methods...
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient _supabaseClient;

  ProductRemoteDataSourceImpl({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabaseClient
          .from('product_details_view')
          .select()
          .limit(20)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _mapProductFromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(message: 'Failed to fetch products: ${e.toString()}');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final response = await _supabaseClient
          .from('product_details_view')
          .select()
          .eq('id', id)
          .single();

      return _mapProductFromJson(response);
    } catch (e) {
      throw ServerException(message: 'Failed to fetch product: ${e.toString()}');
    }
  }

  // Private helper method to map JSON to Product entity
  Product _mapProductFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: (json['price'] as num).toDouble(),
      discountPercentage: json['discount_percentage'] != null
          ? (json['discount_percentage'] as num).toDouble()
          : null,
      rating: json['ratings_avg'] != null
          ? (json['ratings_avg'] as num).toDouble()
          : null,
      reviewCount: json['review_count'],
      mainImageUrl: json['main_image_url'] ?? '',
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'])
          : null,
      inStock: json['in_stock'] ?? true,
      stockQuantity: json['stock_quantity'],
      categoryId: json['category_id'] ?? '',
      subcategoryId: json['subcategory_id'],
      brand: json['brand'],
      attributes: json['attributes'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      onSale: json['is_on_sale'] ?? false,
    );
  }
}
```

## Repository Implementation Example

```dart
import 'package:dartz/dartz.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../datasources/product_remote_data_source.dart';
import '../datasources/product_local_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    if (await networkInfo.isConnected) {
      try {
        final products = await remoteDataSource.getProducts();
        await localDataSource.cacheProducts(products);
        return Right(products);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localProducts = await localDataSource.getLastProducts();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final product = await remoteDataSource.getProductById(id);
        await localDataSource.cacheProduct(product);
        return Right(product);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localProduct = await localDataSource.getProductById(id);
        return Right(localProduct);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  // Other methods...
}
```

## Dependency Injection Setup

```dart
// Register Supabase client
sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

// Register data sources
sl.registerLazySingleton<ProductRemoteDataSource>(
  () => ProductRemoteDataSourceImpl(supabaseClient: sl()),
);
sl.registerLazySingleton<ProductLocalDataSource>(
  () => ProductLocalDataSourceImpl(sharedPreferences: sl()),
);

// Register repositories
sl.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(
    remoteDataSource: sl(),
    localDataSource: sl(),
    networkInfo: sl(),
  ),
);
```

## Working with RLS (Row Level Security)

Supabase uses PostgreSQL's Row Level Security to control access to data. When implementing data sources, ensure that:

1. **Authentication**: Use the right authentication token when making requests:

```dart
// In a remote data source implementation
final user = await _supabaseClient.auth.currentUser;
if (user == null) {
  throw AuthException(message: 'User is not authenticated');
}

// Then make authenticated requests
final response = await _supabaseClient
    .from('addresses')
    .select()
    .eq('user_id', user.id)
    .order('is_default', ascending: false);
```

2. **Policies**: Understand the RLS policies in place for each table:

```dart
// For tables with RLS policies that only allow users to view their own data
// e.g., addresses, orders, cart_items, etc.
await _supabaseClient
    .from('orders')
    .select('*, order_items(*)')
    .eq('user_id', user.id)
    .order('created_at', ascending: false);
```

## Using Database Views

The schema alignment has created several database views to simplify data access:

1. **product_details_view**: Use for product listings and detail pages

```dart
final response = await _supabaseClient
    .from('product_details_view')
    .select()
    .eq('category_id', categoryId)
    .limit(20);
```

2. **user_profile_view**: Use for user profile information

```dart
final response = await _supabaseClient
    .from('user_profile_view')
    .select()
    .eq('user_id', userId)
    .single();
```

3. **order_details_view**: Use for order history and details

```dart
final response = await _supabaseClient
    .from('order_details_view')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);
```

## Error Handling

Map Supabase errors to domain failures:

```dart
try {
  // Supabase operation
} on PostgrestException catch (e) {
  if (e.code == 'PGRST301') {
    throw NotFoundException(message: 'Resource not found');
  } else {
    throw ServerException(message: 'Database error: ${e.message}');
  }
} on AuthException catch (e) {
  throw AuthenticationException(message: 'Authentication error: ${e.message}');
} catch (e) {
  throw ServerException(message: 'Unexpected error: ${e.toString()}');
}
```

## Testing Considerations

1. **Mock the SupabaseClient**:
   
```dart
class MockSupabaseClient extends Mock implements SupabaseClient {}
```

2. **Create test fixtures**:

```dart
// test/fixtures/product_fixture.json
{
  "id": "123e4567-e89b-12d3-a456-426614174000",
  "name": "Test Product",
  "price": 99.99,
  // Other fields...
}
```

3. **Write tests that verify correct mapping**:

```dart
test('should return Product when the response is successful', () async {
  // Arrange
  when(mockSupabaseClient.from(any).select(any)).thenAnswer(
    (_) async => [jsonDecode(fixture('product_fixture.json'))],
  );
  
  // Act
  final result = await dataSource.getProducts();
  
  // Assert
  expect(result.first.id, '123e4567-e89b-12d3-a456-426614174000');
  expect(result.first.name, 'Test Product');
});
```

## Best Practices

1. **Use database views** when possible to simplify data access.
2. **Implement caching** for frequently accessed data like products and categories.
3. **Handle offline scenarios** gracefully by storing critical data locally.
4. **Map errors** to meaningful domain failures to provide better user feedback.
5. **Use JWTs securely** by implementing proper token refresh mechanisms.
6. **Validate inputs** before sending them to the database.
7. **Implement pagination** for large data sets.
8. **Use batch operations** when performing multiple related operations.

## Next Steps

1. Implement all remote data sources for the existing entities:
   - UserRemoteDataSource
   - ProductRemoteDataSource
   - CategoryRemoteDataSource
   - CartRemoteDataSource
   - OrderRemoteDataSource
   - WishlistRemoteDataSource
   - AddressRemoteDataSource

2. Create appropriate local data sources for offline support.

3. Update repository implementations to use these data sources.

4. Add proper error handling and caching strategies. 