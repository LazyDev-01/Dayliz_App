// Example implementation of Product entity and related components
// following clean architecture principles

// ------------------ DOMAIN LAYER ------------------

// 1. Entity (Domain Layer)
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final List<String> categories;
  final String imageUrl;
  final bool isAvailable;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categories,
    required this.imageUrl,
    required this.isAvailable,
    required this.createdAt,
  });

  // Factory constructor for creating Product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      categories: List<String>.from(json['categories']),
      imageUrl: json['imageUrl'],
      isAvailable: json['isAvailable'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // Method to convert Product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'categories': categories,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Immutable update method
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    List<String>? categories,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      categories: categories ?? this.categories,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.price == price &&
        listEquals(other.categories, categories) &&
        other.imageUrl == imageUrl &&
        other.isAvailable == isAvailable &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        price.hashCode ^
        categories.hashCode ^
        imageUrl.hashCode ^
        isAvailable.hashCode ^
        createdAt.hashCode;
  }
}

// Helper function for list comparison in the equals override
bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// 2. Repository Interface (Domain Layer)
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
  Future<Either<Failure, Product>> getProductById(String id);
  Future<Either<Failure, Product>> addProduct(Product product);
  Future<Either<Failure, Product>> updateProduct(Product product);
  Future<Either<Failure, bool>> deleteProduct(String id);
}

// 3. Use Case (Domain Layer)
class GetProducts {
  final ProductRepository repository;

  GetProducts(this.repository);

  Future<Either<Failure, List<Product>>> call() async {
    return await repository.getProducts();
  }
}

class GetProductById {
  final ProductRepository repository;

  GetProductById(this.repository);

  Future<Either<Failure, Product>> call(String id) async {
    return await repository.getProductById(id);
  }
}

// ------------------ DATA LAYER ------------------

// 4. Data Source Interface (Data Layer)
abstract class ProductDataSource {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  Future<Product> addProduct(Product product);
  Future<Product> updateProduct(Product product);
  Future<bool> deleteProduct(String id);
}

// 5. Remote Data Source Implementation (Data Layer)
class ProductRemoteDataSource implements ProductDataSource {
  final http.Client client;
  final String baseUrl;

  ProductRemoteDataSource({required this.client, required this.baseUrl});

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> productsJson = json.decode(response.body);
        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        throw ServerException(
            message: 'Failed to fetch products: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Error connecting to server: ${e.toString()}');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
            message: 'Failed to fetch product: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Error connecting to server: ${e.toString()}');
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
            message: 'Failed to add product: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Error connecting to server: ${e.toString()}');
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/products/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw ServerException(
            message: 'Failed to update product: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Error connecting to server: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw ServerException(
            message: 'Failed to delete product: ${response.statusCode}');
      }
    } catch (e) {
      throw ServerException(message: 'Error connecting to server: ${e.toString()}');
    }
  }
}

// 6. Local Data Source Implementation (Data Layer)
class ProductLocalDataSource implements ProductDataSource {
  final SharedPreferences sharedPreferences;

  ProductLocalDataSource({required this.sharedPreferences});

  @override
  Future<List<Product>> getProducts() async {
    try {
      final jsonString = sharedPreferences.getString('CACHED_PRODUCTS');
      if (jsonString != null) {
        final List<dynamic> decoded = json.decode(jsonString);
        return decoded.map((item) => Product.fromJson(item)).toList();
      } else {
        throw CacheException(message: 'No cached products found');
      }
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve cached products: ${e.toString()}');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final products = await getProducts();
      final product = products.firstWhere(
        (product) => product.id == id,
        orElse: () => throw CacheException(message: 'Product not found in cache'),
      );
      return product;
    } catch (e) {
      throw CacheException(message: 'Failed to retrieve cached product: ${e.toString()}');
    }
  }

  @override
  Future<Product> addProduct(Product product) async {
    try {
      final products = await getProducts();
      final updatedProducts = [...products, product];
      await cacheProducts(updatedProducts);
      return product;
    } catch (e) {
      throw CacheException(message: 'Failed to add product to cache: ${e.toString()}');
    }
  }

  @override
  Future<Product> updateProduct(Product product) async {
    try {
      final products = await getProducts();
      final updatedProducts = products.map((p) {
        if (p.id == product.id) {
          return product;
        }
        return p;
      }).toList();
      await cacheProducts(updatedProducts);
      return product;
    } catch (e) {
      throw CacheException(message: 'Failed to update cached product: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteProduct(String id) async {
    try {
      final products = await getProducts();
      final updatedProducts = products.where((p) => p.id != id).toList();
      await cacheProducts(updatedProducts);
      return true;
    } catch (e) {
      throw CacheException(message: 'Failed to delete product from cache: ${e.toString()}');
    }
  }

  Future<void> cacheProducts(List<Product> products) async {
    try {
      final String jsonString = json.encode(
        products.map((product) => product.toJson()).toList(),
      );
      await sharedPreferences.setString('CACHED_PRODUCTS', jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to cache products: ${e.toString()}');
    }
  }
}

// 7. Repository Implementation (Data Layer)
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource remoteDataSource;
  final ProductDataSource localDataSource;
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
        await (localDataSource as ProductLocalDataSource).cacheProducts(products);
        return Right(products);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final products = await localDataSource.getProducts();
        return Right(products);
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
        return Right(product);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final product = await localDataSource.getProductById(id);
        return Right(product);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  @override
  Future<Either<Failure, Product>> addProduct(Product product) async {
    if (await networkInfo.isConnected) {
      try {
        final newProduct = await remoteDataSource.addProduct(product);
        await localDataSource.addProduct(newProduct);
        return Right(newProduct);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Product>> updateProduct(Product product) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedProduct = await remoteDataSource.updateProduct(product);
        await localDataSource.updateProduct(updatedProduct);
        return Right(updatedProduct);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteProduct(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deleteProduct(id);
        await localDataSource.deleteProduct(id);
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(ServerFailure(message: 'No internet connection'));
    }
  }
}

// ------------------ PRESENTATION LAYER ------------------

// 8. State Class (Presentation Layer)
abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductsLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;

  const ProductsLoaded(this.products);

  @override
  List<Object> get props => [products];
}

class ProductLoaded extends ProductState {
  final Product product;

  const ProductLoaded(this.product);

  @override
  List<Object> get props => [product];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object> get props => [message];
}

// 9. Cubit (Presentation Layer)
class ProductCubit extends Cubit<ProductState> {
  final GetProducts getProducts;
  final GetProductById getProductById;
  final AddProduct addProduct;
  final UpdateProduct updateProduct;
  final DeleteProduct deleteProduct;

  ProductCubit({
    required this.getProducts,
    required this.getProductById,
    required this.addProduct,
    required this.updateProduct,
    required this.deleteProduct,
  }) : super(ProductInitial());

  Future<void> fetchProducts() async {
    emit(ProductsLoading());
    final result = await getProducts();
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (products) => emit(ProductsLoaded(products)),
    );
  }

  Future<void> fetchProductById(String id) async {
    emit(ProductsLoading());
    final result = await getProductById(id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductLoaded(product)),
    );
  }

  Future<void> createProduct(Product product) async {
    emit(ProductsLoading());
    final result = await addProduct(product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductLoaded(product)),
    );
  }

  Future<void> editProduct(Product product) async {
    emit(ProductsLoading());
    final result = await updateProduct(product);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductLoaded(product)),
    );
  }

  Future<void> removeProduct(String id) async {
    emit(ProductsLoading());
    final result = await deleteProduct(id);
    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (success) {
        if (success) {
          fetchProducts();
        } else {
          emit(const ProductError('Failed to delete product'));
        }
      },
    );
  }
}

// 10. Dependency Injection (Core Layer)
void setupProductDependencies() {
  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(
      client: sl<http.Client>(),
      baseUrl: sl<String>(instanceName: 'baseUrl'),
    ),
  );

  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSource(
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl<ProductRemoteDataSource>(),
      localDataSource: sl<ProductLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProducts(sl<ProductRepository>()));
  sl.registerLazySingleton(() => GetProductById(sl<ProductRepository>()));
  sl.registerLazySingleton(() => AddProduct(sl<ProductRepository>()));
  sl.registerLazySingleton(() => UpdateProduct(sl<ProductRepository>()));
  sl.registerLazySingleton(() => DeleteProduct(sl<ProductRepository>()));

  // BLoC/Cubit
  sl.registerFactory(
    () => ProductCubit(
      getProducts: sl<GetProducts>(),
      getProductById: sl<GetProductById>(),
      addProduct: sl<AddProduct>(),
      updateProduct: sl<UpdateProduct>(),
      deleteProduct: sl<DeleteProduct>(),
    ),
  );
}

// Required imports for the example
// import 'dart:convert';
// import 'package:dartz/dartz.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:your_app/core/error/exceptions.dart';
// import 'package:your_app/core/error/failures.dart';
// import 'package:your_app/core/network/network_info.dart';
// import 'package:your_app/di/service_locator.dart' as sl; 