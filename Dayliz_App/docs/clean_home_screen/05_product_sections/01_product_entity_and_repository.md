# Clean Home Screen: Product Entity and Repository

## 1. Product Domain Layer

The product domain layer defines the core business objects and rules related to products, independent of any external frameworks or technologies.

### 1.1 Product Entity

```dart
// lib/domain/entities/product.dart
class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final List<String>? additionalImages;
  final double rating;
  final int reviewCount;
  final bool inStock;
  final int? stockQuantity;
  final String? categoryId;
  final List<String>? tags;
  final bool isFeatured;
  final bool isOnSale;
  final DateTime? createdAt;
  final Map<String, dynamic>? attributes;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.additionalImages,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.inStock = true,
    this.stockQuantity,
    this.categoryId,
    this.tags,
    this.isFeatured = false,
    this.isOnSale = false,
    this.createdAt,
    this.attributes,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  double get discountPercentage {
    if (!hasDiscount) return 0.0;
    return ((originalPrice! - price) / originalPrice! * 100).roundToDouble();
  }

  bool get isNew {
    if (createdAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    return difference.inDays <= 14; // Consider products added in the last 14 days as new
  }
}
```

### 1.2 Product Value Objects

```dart
// lib/domain/value_objects/product_sort_option.dart
enum ProductSortOption {
  newest,
  priceHighToLow,
  priceLowToHigh,
  popularity,
  rating,
}

// lib/domain/value_objects/product_filter.dart
class ProductFilter {
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final bool? inStock;
  final bool? onSale;
  final List<String>? tags;
  final Map<String, List<String>>? attributes;

  const ProductFilter({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.inStock,
    this.onSale,
    this.tags,
    this.attributes,
  });

  ProductFilter copyWith({
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    bool? inStock,
    bool? onSale,
    List<String>? tags,
    Map<String, List<String>>? attributes,
  }) {
    return ProductFilter(
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      inStock: inStock ?? this.inStock,
      onSale: onSale ?? this.onSale,
      tags: tags ?? this.tags,
      attributes: attributes ?? this.attributes,
    );
  }
}
```

## 2. Product Data Layer

The product data layer handles the implementation details of how product data is retrieved, stored, and manipulated.

### 2.1 Product Model

```dart
// lib/data/models/product_model.dart
class ProductModel extends Product {
  const ProductModel({
    required String id,
    required String name,
    String? description,
    required double price,
    double? originalPrice,
    String? imageUrl,
    List<String>? additionalImages,
    double rating = 0.0,
    int reviewCount = 0,
    bool inStock = true,
    int? stockQuantity,
    String? categoryId,
    List<String>? tags,
    bool isFeatured = false,
    bool isOnSale = false,
    DateTime? createdAt,
    Map<String, dynamic>? attributes,
  }) : super(
          id: id,
          name: name,
          description: description,
          price: price,
          originalPrice: originalPrice,
          imageUrl: imageUrl,
          additionalImages: additionalImages,
          rating: rating,
          reviewCount: reviewCount,
          inStock: inStock,
          stockQuantity: stockQuantity,
          categoryId: categoryId,
          tags: tags,
          isFeatured: isFeatured,
          isOnSale: isOnSale,
          createdAt: createdAt,
          attributes: attributes,
        );

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'],
      additionalImages: json['additional_images'] != null
          ? List<String>.from(json['additional_images'])
          : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      reviewCount: json['review_count'] ?? 0,
      inStock: json['in_stock'] ?? true,
      stockQuantity: json['stock_quantity'],
      categoryId: json['category_id'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isFeatured: json['is_featured'] ?? false,
      isOnSale: json['is_on_sale'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'additional_images': additionalImages,
      'rating': rating,
      'review_count': reviewCount,
      'in_stock': inStock,
      'stock_quantity': stockQuantity,
      'category_id': categoryId,
      'tags': tags,
      'is_featured': isFeatured,
      'is_on_sale': isOnSale,
      'created_at': createdAt?.toIso8601String(),
      'attributes': attributes,
    };
  }
}
```

### 2.2 Product Data Sources

#### 2.2.1 Remote Data Source

```dart
// lib/data/datasources/product_remote_data_source.dart
abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    ProductFilter? filter,
    ProductSortOption? sortOption,
    int? limit,
    int? offset,
  });
  
  Future<List<ProductModel>> getFeaturedProducts({int? limit});
  
  Future<List<ProductModel>> getSaleProducts({int? limit});
  
  Future<List<ProductModel>> getNewArrivals({int? limit});
  
  Future<ProductModel> getProductById(String id);
  
  Future<List<ProductModel>> getRelatedProducts(String productId, {int? limit});
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  ProductRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<List<ProductModel>> getProducts({
    ProductFilter? filter,
    ProductSortOption? sortOption,
    int? limit,
    int? offset,
  }) async {
    // Build query parameters
    final queryParams = <String, String>{};
    
    if (filter != null) {
      if (filter.categoryId != null) {
        queryParams['category_id'] = filter.categoryId!;
      }
      if (filter.minPrice != null) {
        queryParams['min_price'] = filter.minPrice!.toString();
      }
      if (filter.maxPrice != null) {
        queryParams['max_price'] = filter.maxPrice!.toString();
      }
      if (filter.inStock != null) {
        queryParams['in_stock'] = filter.inStock!.toString();
      }
      if (filter.onSale != null) {
        queryParams['on_sale'] = filter.onSale!.toString();
      }
      if (filter.tags != null && filter.tags!.isNotEmpty) {
        queryParams['tags'] = filter.tags!.join(',');
      }
      // Handle attributes if needed
    }
    
    if (sortOption != null) {
      queryParams['sort'] = sortOption.toString().split('.').last;
    }
    
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    
    if (offset != null) {
      queryParams['offset'] = offset.toString();
    }
    
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List;
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw ServerException();
    }
  }
  
  @override
  Future<List<ProductModel>> getFeaturedProducts({int? limit}) async {
    final queryParams = <String, String>{
      'is_featured': 'true',
    };
    
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List;
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw ServerException();
    }
  }
  
  @override
  Future<List<ProductModel>> getSaleProducts({int? limit}) async {
    final queryParams = <String, String>{
      'is_on_sale': 'true',
    };
    
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List;
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw ServerException();
    }
  }
  
  @override
  Future<List<ProductModel>> getNewArrivals({int? limit}) async {
    final queryParams = <String, String>{
      'sort': 'newest',
    };
    
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    
    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: queryParams);
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List;
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw ServerException();
    }
  }
  
  @override
  Future<ProductModel> getProductById(String id) async {
    final uri = Uri.parse('$baseUrl/products/$id');
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return ProductModel.fromJson(jsonData);
    } else {
      throw ServerException();
    }
  }
  
  @override
  Future<List<ProductModel>> getRelatedProducts(String productId, {int? limit}) async {
    final queryParams = <String, String>{};
    
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }
    
    final uri = Uri.parse('$baseUrl/products/$productId/related')
        .replace(queryParameters: queryParams);
    
    final response = await client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body) as List;
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw ServerException();
    }
  }
}
```

#### 2.2.2 Local Data Source

```dart
// lib/data/datasources/product_local_data_source.dart
abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getCachedProducts();
  
  Future<void> cacheProducts(List<ProductModel> products);
  
  Future<ProductModel?> getCachedProductById(String id);
  
  Future<void> cacheProduct(ProductModel product);
}

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences sharedPreferences;

  ProductLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final jsonString = sharedPreferences.getString('cached_products');
    if (jsonString != null) {
      final jsonData = json.decode(jsonString) as List;
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } else {
      throw CacheException();
    }
  }

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final jsonData = products.map((product) => product.toJson()).toList();
    final jsonString = json.encode(jsonData);
    await sharedPreferences.setString('cached_products', jsonString);
  }

  @override
  Future<ProductModel?> getCachedProductById(String id) async {
    final jsonString = sharedPreferences.getString('cached_product_$id');
    if (jsonString != null) {
      final jsonData = json.decode(jsonString);
      return ProductModel.fromJson(jsonData);
    }
    return null;
  }

  @override
  Future<void> cacheProduct(ProductModel product) async {
    final jsonString = json.encode(product.toJson());
    await sharedPreferences.setString('cached_product_${product.id}', jsonString);
  }
}
```

## 3. Product Repository

### 3.1 Repository Interface

```dart
// lib/domain/repositories/product_repository.dart
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts({
    ProductFilter? filter,
    ProductSortOption? sortOption,
    int? limit,
    int? offset,
  });
  
  Future<Either<Failure, List<Product>>> getFeaturedProducts({int? limit});
  
  Future<Either<Failure, List<Product>>> getSaleProducts({int? limit});
  
  Future<Either<Failure, List<Product>>> getNewArrivals({int? limit});
  
  Future<Either<Failure, Product>> getProductById(String id);
  
  Future<Either<Failure, List<Product>>> getRelatedProducts(String productId, {int? limit});
}
```

### 3.2 Repository Implementation

```dart
// lib/data/repositories/product_repository_impl.dart
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
  Future<Either<Failure, List<Product>>> getProducts({
    ProductFilter? filter,
    ProductSortOption? sortOption,
    int? limit,
    int? offset,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getProducts(
          filter: filter,
          sortOption: sortOption,
          limit: limit,
          offset: offset,
        );
        await localDataSource.cacheProducts(remoteProducts);
        return Right(remoteProducts);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localProducts = await localDataSource.getCachedProducts();
        // Apply filters locally if needed
        return Right(localProducts);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts({int? limit}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getFeaturedProducts(limit: limit);
        return Right(remoteProducts);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localProducts = await localDataSource.getCachedProducts();
        final featuredProducts = localProducts
            .where((product) => product.isFeatured)
            .take(limit ?? localProducts.length)
            .toList();
        return Right(featuredProducts);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getSaleProducts({int? limit}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getSaleProducts(limit: limit);
        return Right(remoteProducts);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localProducts = await localDataSource.getCachedProducts();
        final saleProducts = localProducts
            .where((product) => product.isOnSale)
            .take(limit ?? localProducts.length)
            .toList();
        return Right(saleProducts);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getNewArrivals({int? limit}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getNewArrivals(limit: limit);
        return Right(remoteProducts);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localProducts = await localDataSource.getCachedProducts();
        // Sort by creation date
        final sortedProducts = List<ProductModel>.from(localProducts)
          ..sort((a, b) {
            if (a.createdAt == null || b.createdAt == null) return 0;
            return b.createdAt!.compareTo(a.createdAt!);
          });
        
        final newArrivals = sortedProducts
            .take(limit ?? sortedProducts.length)
            .toList();
        return Right(newArrivals);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProduct = await remoteDataSource.getProductById(id);
        await localDataSource.cacheProduct(remoteProduct);
        return Right(remoteProduct);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localProduct = await localDataSource.getCachedProductById(id);
        if (localProduct != null) {
          return Right(localProduct);
        } else {
          return Left(CacheFailure());
        }
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Product>>> getRelatedProducts(String productId, {int? limit}) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await remoteDataSource.getRelatedProducts(
          productId,
          limit: limit,
        );
        return Right(remoteProducts);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      // For offline mode, we could try to find products in the same category
      // This is a simplified implementation
      try {
        final product = await localDataSource.getCachedProductById(productId);
        if (product != null && product.categoryId != null) {
          final localProducts = await localDataSource.getCachedProducts();
          final relatedProducts = localProducts
              .where((p) => p.id != productId && p.categoryId == product.categoryId)
              .take(limit ?? 10)
              .toList();
          return Right(relatedProducts);
        } else {
          return const Right([]);
        }
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
```

## 4. Dependency Injection

```dart
// lib/injection_container.dart (partial)
final sl = GetIt.instance;

Future<void> initProductDependencies() async {
  // Use cases
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetSaleProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetNewArrivalsUseCase(sl()));
  sl.registerLazySingleton(() => GetProductByIdUseCase(sl()));
  sl.registerLazySingleton(() => GetRelatedProductsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(
      client: sl(),
      baseUrl: sl<AppConfig>().apiBaseUrl,
    ),
  );
  
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );
}
```

## 5. Next Steps

In the following sections, we will cover:

1. **Product Use Cases**: Implementation of the use cases for retrieving different types of products
2. **Product State Management**: State management for product data using Riverpod
3. **Product Card Widget**: Reusable product card component for displaying products
4. **Featured Products Section**: Implementation of the featured products section
5. **Sale Products Section**: Implementation of the sale/discount products section
6. **New Arrivals Section**: Implementation of the new arrivals section
