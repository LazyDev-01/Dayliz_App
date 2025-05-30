import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

/// Implementation of the product repository
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  /// Constructor for ProductRepositoryImpl
  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  /// Helper method to handle product operations and manage caching
  Future<Either<Failure, List<Product>>> _getProducts({
    required Future<List<ProductModel>> Function() getRemoteData,
    required Future<List<ProductModel>> Function() getCachedData,
    required Future<void> Function(List<ProductModel>) cacheData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Get data from remote source
        final remoteProducts = await getRemoteData();
        // Cache the data
        await cacheData(remoteProducts);
        // Return the data
        return Right(remoteProducts);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      // No internet connection, try to get cached data
      try {
        final localProducts = await getCachedData();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Get a list of products with optional filters
  @override
  Future<Either<Failure, List<Product>>> getProducts({
    int? page,
    int? limit,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  }) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProducts(
        page: page,
        limit: limit,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        searchQuery: searchQuery,
        sortBy: sortBy,
        ascending: ascending,
        minPrice: minPrice,
        maxPrice: maxPrice,
      ),
      getCachedData: () => localDataSource.getCachedProducts(),
      cacheData: (products) => localDataSource.cacheProducts(products),
    );
  }

  /// Get a product by ID
  @override
  Future<Either<Failure, Product>> getProductById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProduct = await remoteDataSource.getProductById(id);
        await localDataSource.cacheProduct(remoteProduct);
        return Right(remoteProduct);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      try {
        final localProduct = await localDataSource.getCachedProductById(id);
        return Right(localProduct);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }

  /// Get featured products
  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts({int? limit}) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getFeaturedProducts(limit: limit),
      getCachedData: () => localDataSource.getCachedFeaturedProducts(),
      cacheData: (products) => localDataSource.cacheFeaturedProducts(products),
    );
  }

  /// Get products on sale
  @override
  Future<Either<Failure, List<Product>>> getProductsOnSale({
    int? page,
    int? limit,
  }) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProductsOnSale(
        page: page,
        limit: limit,
      ),
      getCachedData: () => localDataSource.getCachedProductsOnSale(),
      cacheData: (products) => localDataSource.cacheProductsOnSale(products),
    );
  }

  /// Get related products for a specific product
  @override
  Future<Either<Failure, List<Product>>> getRelatedProducts({
    required String productId,
    int? limit,
  }) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getRelatedProducts(
        productId: productId,
        limit: limit,
      ),
      getCachedData: () => localDataSource.getCachedRelatedProducts(productId),
      cacheData: (products) => localDataSource.cacheRelatedProducts(productId, products),
    );
  }

  /// Search products by query
  @override
  Future<Either<Failure, List<Product>>> searchProducts({
    required String query,
    int? page,
    int? limit,
  }) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.searchProducts(
        query: query,
        page: page,
        limit: limit,
      ),
      getCachedData: () => localDataSource.getCachedSearchResults(query),
      cacheData: (products) => localDataSource.cacheSearchResults(query, products),
    );
  }

  /// Get products by category
  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(String categoryId) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProductsByCategory(categoryId),
      getCachedData: () => localDataSource.getLastProductsByCategory(categoryId),
      cacheData: (products) => localDataSource.cacheProductsByCategory(categoryId, products),
    );
  }

  /// Get products by list of IDs
  @override
  Future<Either<Failure, List<Product>>> getProductsByIds(List<String> ids) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProductsByIds(ids),
      getCachedData: () => localDataSource.getLastProductsByIds(ids),
      cacheData: (products) => localDataSource.cacheProductsByIds(ids, products),
    );
  }
} 