# Repository Integration Plan

## Overview

This document outlines the plan for integrating the new database features into the existing repository implementations. Instead of creating new repository implementation files, we'll update the existing ones to use the database features while maintaining compatibility with the current codebase.

## Issues Encountered

When attempting to create separate repository implementation files, we encountered several issues:

1. **Missing Entity Classes**: The `ProductSearchResult` entity was missing.
2. **Method Signature Mismatches**: The method signatures in the new implementations didn't match the repository interfaces.
3. **Missing Method Implementations**: Several required methods were not implemented in the new repository classes.
4. **Constructor Parameter Mismatches**: The model constructors didn't match the parameters used in the new implementations.

## Integration Approach

Instead of replacing the existing repository implementations, we'll enhance them by adding the database features. This approach ensures that all required methods are implemented and the method signatures match.

### 1. ProductRepository Integration

Update the existing `ProductRepositoryImpl` to use full-text search:

```dart
// In the existing ProductRepositoryImpl class

// Add a SupabaseClient field
final SupabaseClient supabaseClient;

// Update the constructor to include the SupabaseClient
ProductRepositoryImpl({
  required this.remoteDataSource,
  required this.localDataSource,
  required this.networkInfo,
  required this.supabaseClient,
});

// Enhance the searchProducts method to use full-text search
@override
Future<Either<Failure, List<Product>>> searchProducts({
  String? query,
  String? categoryId,
  String? subcategoryId,
  double? minPrice,
  double? maxPrice,
  int? limit,
  int? page,
  String? sortBy,
  bool? ascending,
}) async {
  if (await networkInfo.isConnected) {
    try {
      // Use full-text search if query is provided
      if (query != null && query.isNotEmpty) {
        final result = await supabaseClient.rpc(
          'search_products_full_text',
          params: {
            'search_query': query,
            'category_id_param': categoryId,
            'subcategory_id_param': subcategoryId,
            'min_price': minPrice,
            'max_price': maxPrice,
            'in_stock_only': true,
            'on_sale_only': false,
            'sort_by': sortBy ?? 'relevance',
            'page_number': page ?? 1,
            'page_size': limit ?? 20,
          },
        );
        
        if (result.error != null) {
          // Fall back to standard implementation if the database function fails
          return await _getProductsStandard(
            query: query,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            minPrice: minPrice,
            maxPrice: maxPrice,
            limit: limit,
            page: page,
            sortBy: sortBy,
            ascending: ascending,
          );
        }
        
        final products = (result.data as List)
            .map((item) => ProductModel.fromJson(item))
            .toList();
        
        return Right(products);
      } else {
        // Use standard implementation for non-search queries
        return await _getProductsStandard(
          query: query,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          minPrice: minPrice,
          maxPrice: maxPrice,
          limit: limit,
          page: page,
          sortBy: sortBy,
          ascending: ascending,
        );
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  } else {
    // If offline, use local data source
    try {
      final localProducts = await localDataSource.getCachedProducts();
      return Right(localProducts);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}

// Helper method for standard product retrieval
Future<Either<Failure, List<Product>>> _getProductsStandard({
  String? query,
  String? categoryId,
  String? subcategoryId,
  double? minPrice,
  double? maxPrice,
  int? limit,
  int? page,
  String? sortBy,
  bool? ascending,
}) async {
  try {
    final remoteProducts = await remoteDataSource.getProducts(
      query: query,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      limit: limit,
      page: page,
      sortBy: sortBy,
      ascending: ascending,
    );
    
    await localDataSource.cacheProducts(remoteProducts);
    return Right(remoteProducts);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  }
}
```

### 2. CartRepository Integration

Update the existing `CartRepositoryImpl` to use the `get_user_cart` database function:

```dart
// In the existing CartRepositoryImpl class

// Add a SupabaseClient field
final SupabaseClient supabaseClient;

// Update the constructor to include the SupabaseClient
CartRepositoryImpl({
  required this.remoteDataSource,
  required this.localDataSource,
  required this.networkInfo,
  required this.supabaseClient,
});

// Enhance the getCartItems method to use the database function
@override
Future<Either<Failure, List<CartItem>>> getCartItems() async {
  if (await networkInfo.isConnected) {
    try {
      // Try to use the database function
      final result = await supabaseClient.rpc('get_user_cart');
      
      if (result.error != null) {
        // Fall back to standard implementation if the database function fails
        return await _getCartItemsStandard();
      }
      
      final cartItems = (result.data as List).map((item) {
        // Convert the JSON response to CartItemModel
        final productJson = {
          'id': item['product_id'],
          'name': item['product_name'],
          'description': item['product_description'],
          'price': item['product_price'],
          'discount_percentage': item['discount_percentage'],
          'main_image_url': item['main_image_url'],
          'in_stock': item['in_stock'],
          'stock_quantity': item['stock_quantity'],
        };
        
        final product = ProductModel.fromJson(productJson);
        
        return CartItemModel(
          id: item['cart_item_id'],
          product: product,
          quantity: item['quantity'],
          addedAt: DateTime.parse(item['added_at']),
        );
      }).toList();
      
      // Cache the cart items locally
      await localDataSource.cacheCartItems(cartItems);
      
      return Right(cartItems);
    } catch (e) {
      // Fall back to standard implementation if any error occurs
      return await _getCartItemsStandard();
    }
  } else {
    // If offline, use local data source
    try {
      final localCartItems = await localDataSource.getCachedCartItems();
      return Right(localCartItems);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    }
  }
}

// Helper method for standard cart item retrieval
Future<Either<Failure, List<CartItem>>> _getCartItemsStandard() async {
  try {
    final remoteCartItems = await remoteDataSource.getCartItems();
    await localDataSource.cacheCartItems(remoteCartItems);
    return Right(remoteCartItems);
  } on ServerException catch (e) {
    return Left(ServerFailure(message: e.message));
  }
}
```

## Implementation Plan

1. **Create Required Entities**: Create any missing entity classes like `ProductSearchResult`.
2. **Update Dependency Injection**: Update the dependency injection to include the `SupabaseClient` in the repository constructors.
3. **Enhance Existing Repositories**: Update the existing repository implementations one by one to use the database features.
4. **Test Each Repository**: Test each repository after updating it to ensure it works correctly.
5. **Document Changes**: Document the changes made to each repository.

## Next Steps

1. Create the `ProductSearchResult` entity class.
2. Update the dependency injection to include the `SupabaseClient` in the repository constructors.
3. Update the `ProductRepositoryImpl` to use full-text search.
4. Update the `CartRepositoryImpl` to use the `get_user_cart` database function.
5. Update the `UserProfileRepositoryImpl` to use geospatial queries.
6. Update the `OrderRepositoryImpl` to use the `get_user_orders` and `get_order_details` functions.
7. Update the `WishlistRepositoryImpl` to use the `get_user_wishlist` function.

## Conclusion

By enhancing the existing repository implementations rather than replacing them, we can leverage the new database features while maintaining compatibility with the current codebase. This approach ensures that all required methods are implemented and the method signatures match, avoiding the issues encountered with the separate repository implementation files.
