# Repository Implementation Guide

This guide explains how to use the updated repository implementations that leverage the new database features in the Dayliz App.

## Overview

We've updated the repository implementations to use the new database features we added during the performance optimization phase. These updates improve performance, reduce data transfer, and enable advanced features like full-text search and geospatial queries.

## Updated Repositories

The following repositories have been updated:

1. **ProductRepositoryImpl**: Uses full-text search for improved product search
2. **CartRepositoryImpl**: Uses the `get_user_cart` function for efficient cart retrieval
3. **UserProfileRepositoryImpl**: Uses geospatial queries for address-related features
4. **OrderRepositoryImpl**: Uses the `get_user_orders` and `get_order_details` functions
5. **WishlistRepositoryImpl**: Uses the `get_user_wishlist` function

## How to Use the Updated Repositories

### 1. Update Dependency Injection

First, update the dependency injection to use the updated repositories:

```dart
// In lib/di/dependency_injection.dart

// Product Repository
sl.registerLazySingleton<ProductRepository>(
  () => ProductRepositoryImpl(
    remoteDataSource: sl<ProductRemoteDataSource>(),
    localDataSource: sl<ProductLocalDataSource>(),
    networkInfo: sl<NetworkInfo>(),
    supabaseClient: Supabase.instance.client,
  ),
);

// Cart Repository
sl.registerLazySingleton<CartRepository>(
  () => CartRepositoryImpl(
    remoteDataSource: sl<CartRemoteDataSource>(),
    localDataSource: sl<CartLocalDataSource>(),
    networkInfo: sl<NetworkInfo>(),
    supabaseClient: Supabase.instance.client,
  ),
);

// User Profile Repository
sl.registerLazySingleton<UserProfileRepository>(
  () => UserProfileRepositoryImpl(
    remoteDataSource: sl<UserProfileDataSource>(instanceName: 'remote'),
    localDataSource: sl<UserProfileDataSource>(instanceName: 'local'),
    networkInfo: sl<NetworkInfo>(),
    supabaseClient: Supabase.instance.client,
  ),
);

// Order Repository
sl.registerLazySingleton<OrderRepository>(
  () => OrderRepositoryImpl(
    remoteDataSource: sl<OrderDataSource>(),
    localDataSource: sl<OrderDataSource>(instanceName: 'local'),
    networkInfo: sl<NetworkInfo>(),
    supabaseClient: Supabase.instance.client,
  ),
);

// Wishlist Repository
sl.registerLazySingleton<WishlistRepository>(
  () => WishlistRepositoryImpl(
    remoteDataSource: sl<WishlistRemoteDataSource>(),
    localDataSource: sl<WishlistLocalDataSource>(),
    networkInfo: sl<NetworkInfo>(),
    supabaseClient: Supabase.instance.client,
  ),
);
```

### 2. Update Use Cases

The use cases don't need to be updated since they depend on the repository interfaces, which haven't changed. The updated repositories still implement the same interfaces, just with improved implementations.

### 3. Using Full-Text Search

The `ProductRepositoryImpl` now includes a new `searchProducts` method that uses full-text search:

```dart
// In a use case or provider
final result = await productRepository.searchProducts(
  query: 'organic apple',
  categoryId: '123e4567-e89b-12d3-a456-426614174000',
  minPrice: 1.0,
  maxPrice: 10.0,
  inStockOnly: true,
  onSaleOnly: false,
  sortBy: 'relevance',
  page: 1,
  pageSize: 20,
);
```

### 4. Using Geospatial Queries

The `UserProfileRepositoryImpl` now includes methods for geospatial queries:

```dart
// Find addresses within a radius
final result = await userProfileRepository.findAddressesWithinRadius(
  latitude: 37.7749,
  longitude: -122.4194,
  radiusMeters: 5000,
  userId: '123e4567-e89b-12d3-a456-426614174000',
);

// Find the nearest zone
final result = await userProfileRepository.findNearestZone(
  latitude: 37.7749,
  longitude: -122.4194,
);
```

### 5. Using Database Functions for Complex Operations

The other repositories use database functions for complex operations:

```dart
// Get cart items with product details
final result = await cartRepository.getCartItems();

// Get orders with details
final result = await orderRepository.getOrders();

// Get order details
final result = await orderRepository.getOrderById('123e4567-e89b-12d3-a456-426614174000');

// Get wishlist products
final result = await wishlistRepository.getWishlistProducts();
```

## Fallback Mechanisms

All updated repositories include fallback mechanisms to handle cases where the database functions fail or are not available. This ensures that the app continues to work even if there are issues with the database functions.

For example, if the `get_user_cart` function fails, the `CartRepositoryImpl` will fall back to the standard implementation:

```dart
try {
  // Use the database function
  final result = await supabaseClient.rpc('get_user_cart');
  
  if (result.error != null) {
    // If the database function fails, fall back to the standard implementation
    return _getCartItemsStandard();
  }
  
  // Process the result
  // ...
} catch (e) {
  // If any error occurs, fall back to the standard implementation
  return _getCartItemsStandard();
}
```

## Error Handling

The updated repositories maintain the same error handling approach as the original repositories:

1. **Network Errors**: If there's no network connection, the repositories will try to use cached data
2. **Server Errors**: If there's an error from the server, the repositories will return a `ServerFailure`
3. **Cache Errors**: If there's an error with the local cache, the repositories will return a `CacheFailure`

## Testing

When testing the updated repositories, you'll need to mock the Supabase client and its RPC method:

```dart
// In your test file
void main() {
  late ProductRepositoryImpl repository;
  late MockProductRemoteDataSource mockRemoteDataSource;
  late MockProductLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockRemoteDataSource = MockProductRemoteDataSource();
    mockLocalDataSource = MockProductLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockSupabaseClient = MockSupabaseClient();
    repository = ProductRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      supabaseClient: mockSupabaseClient,
    );
  });

  group('searchProducts', () {
    test('should return products when the call to Supabase is successful', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockSupabaseClient.rpc(
        'search_products_full_text',
        params: anyNamed('params'),
      )).thenAnswer((_) async => PostgrestResponse(
        data: [
          {
            'product_id': '123',
            'product_name': 'Test Product',
            'product_description': 'Test Description',
            'product_price': 10.0,
            'discount_percentage': 0.0,
            'main_image_url': 'https://example.com/image.jpg',
            'in_stock': true,
            'stock_quantity': 10,
            'total_count': 1,
          }
        ],
        count: 1,
        status: 200,
        statusText: 'OK',
      ));

      // Act
      final result = await repository.searchProducts(query: 'test');

      // Assert
      expect(result, isA<Right<Failure, ProductSearchResult>>());
      final products = (result as Right).value.products;
      expect(products.length, 1);
      expect(products[0].name, 'Test Product');
    });
  });
}
```

## Conclusion

By updating the repository implementations to use the new database features, we've improved the performance and capabilities of the Dayliz App. These updates reduce the amount of data transferred between the app and the database, improve search relevance, and enable advanced features like geospatial queries.

The updated repositories maintain the same interfaces as the original repositories, so they can be used as drop-in replacements without changing the use cases or presentation layer.
