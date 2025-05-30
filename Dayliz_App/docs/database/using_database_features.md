# Using Database Features in Clean Architecture

This guide explains how to use the database features implemented for the Dayliz App in the clean architecture implementation.

## Overview

The database features implemented for the Dayliz App provide a solid foundation for the clean architecture implementation. By using these features, you can improve performance, enable advanced search capabilities, and add real-time features to your application.

## Repository Implementation

In clean architecture, repositories serve as the bridge between the domain layer and the data layer. They abstract away the details of data storage and retrieval, allowing the domain layer to focus on business logic without being concerned with how data is stored or retrieved.

When implementing repositories, you should use the database features to improve performance and functionality:

### 1. Using Database Functions

Database functions encapsulate complex SQL queries, making them easier to use and maintain. Here's an example of how to use the `get_user_cart` function in a repository:

```dart
@override
Future<Either<Failure, List<CartItem>>> getUserCart(String userId) async {
  if (await networkInfo.isConnected) {
    try {
      final result = await supabaseClient
          .rpc('get_user_cart', params: {'user_id_param': userId})
          .execute();
      
      if (result.error != null) {
        return Left(ServerFailure(message: result.error!.message));
      }
      
      final cartItems = (result.data as List)
          .map((item) => CartItemModel.fromJson(item))
          .toList();
      
      return Right(cartItems);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    return Left(NetworkFailure());
  }
}
```

### 2. Using Full-Text Search

Full-text search improves search performance and relevance. Here's an example of how to use the `search_products_full_text` function in a repository:

```dart
@override
Future<Either<Failure, ProductSearchResult>> searchProducts({
  required String query,
  String? categoryId,
  String? subcategoryId,
  double? minPrice,
  double? maxPrice,
  bool inStockOnly = true,
  bool onSaleOnly = false,
  String sortBy = 'relevance',
  int page = 1,
  int pageSize = 20,
}) async {
  if (await networkInfo.isConnected) {
    try {
      final result = await supabaseClient
          .rpc('search_products_full_text', params: {
            'search_query': query,
            'category_id_param': categoryId,
            'subcategory_id_param': subcategoryId,
            'min_price': minPrice,
            'max_price': maxPrice,
            'in_stock_only': inStockOnly,
            'on_sale_only': onSaleOnly,
            'sort_by': sortBy,
            'page_number': page,
            'page_size': pageSize,
          })
          .execute();
      
      if (result.error != null) {
        return Left(ServerFailure(message: result.error!.message));
      }
      
      final products = (result.data as List)
          .map((item) => ProductModel.fromJson(item))
          .toList();
      
      final totalCount = products.isNotEmpty
          ? (result.data[0]['total_count'] as int)
          : 0;
      
      return Right(ProductSearchResult(
        products: products,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    return Left(NetworkFailure());
  }
}
```

### 3. Using Geospatial Queries

Geospatial queries enable location-based features. Here's an example of how to use the `find_addresses_within_radius` function in a repository:

```dart
@override
Future<Either<Failure, List<Address>>> findAddressesWithinRadius({
  required double latitude,
  required double longitude,
  required double radiusMeters,
  String? userId,
}) async {
  if (await networkInfo.isConnected) {
    try {
      final result = await supabaseClient
          .rpc('find_addresses_within_radius', params: {
            'lat': latitude,
            'lng': longitude,
            'radius_meters': radiusMeters,
            'user_id_param': userId,
          })
          .execute();
      
      if (result.error != null) {
        return Left(ServerFailure(message: result.error!.message));
      }
      
      final addresses = (result.data as List)
          .map((item) => AddressModel.fromJson(item))
          .toList();
      
      return Right(addresses);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    return Left(NetworkFailure());
  }
}
```

### 4. Using Real-Time Notifications

Real-time notifications keep users informed of order status changes. Here's an example of how to use the notifications table in a repository:

```dart
@override
Future<Either<Failure, List<Notification>>> getUserNotifications(String userId) async {
  if (await networkInfo.isConnected) {
    try {
      final result = await supabaseClient
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .execute();
      
      if (result.error != null) {
        return Left(ServerFailure(message: result.error!.message));
      }
      
      final notifications = (result.data as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
      
      return Right(notifications);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    return Left(NetworkFailure());
  }
}

@override
Future<Either<Failure, bool>> markNotificationAsRead(String notificationId) async {
  if (await networkInfo.isConnected) {
    try {
      final result = await supabaseClient
          .rpc('mark_notification_as_read', params: {
            'notification_id_param': notificationId,
          })
          .execute();
      
      if (result.error != null) {
        return Left(ServerFailure(message: result.error!.message));
      }
      
      return Right(result.data as bool);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  } else {
    return Left(NetworkFailure());
  }
}
```

## Use Cases

In clean architecture, use cases (or interactors) represent the business logic of the application. They use repositories to access data and perform operations. Here's an example of how to use the database features in a use case:

### Search Products Use Case

```dart
class SearchProductsUseCase implements UseCase<ProductSearchResult, SearchProductsParams> {
  final ProductRepository repository;

  SearchProductsUseCase(this.repository);

  @override
  Future<Either<Failure, ProductSearchResult>> call(SearchProductsParams params) {
    return repository.searchProducts(
      query: params.query,
      categoryId: params.categoryId,
      subcategoryId: params.subcategoryId,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      inStockOnly: params.inStockOnly,
      onSaleOnly: params.onSaleOnly,
      sortBy: params.sortBy,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class SearchProductsParams {
  final String query;
  final String? categoryId;
  final String? subcategoryId;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final bool onSaleOnly;
  final String sortBy;
  final int page;
  final int pageSize;

  SearchProductsParams({
    required this.query,
    this.categoryId,
    this.subcategoryId,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = true,
    this.onSaleOnly = false,
    this.sortBy = 'relevance',
    this.page = 1,
    this.pageSize = 20,
  });
}
```

## Conclusion

By using the database features implemented for the Dayliz App in your clean architecture implementation, you can improve performance, enable advanced search capabilities, and add real-time features to your application. The examples provided in this guide show how to use these features in repositories and use cases, but the same principles apply to other parts of the clean architecture implementation.
