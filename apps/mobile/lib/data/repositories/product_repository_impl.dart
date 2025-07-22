import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/models/pagination_models.dart';
import '../../core/network/network_info.dart';
import '../../core/repositories/base_repository.dart';
import '../../core/config/network_config.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../datasources/product_supabase_data_source.dart';
import '../models/product_model.dart';

/// Implementation of the product repository with standardized error handling
class ProductRepositoryImpl extends BaseRepository implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  /// Constructor for ProductRepositoryImpl
  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  /// Get products with pagination support
  @override
  Future<Either<Failure, PaginatedResponse<Product>>> getProductsPaginated({
    PaginationParams? pagination,
    String? categoryId,
    String? subcategoryId,
    String? searchQuery,
    String? sortBy,
    bool? ascending,
    double? minPrice,
    double? maxPrice,
  }) async {
    // Use base repository's error handling with cache fallback
    return executeWithCache<PaginatedResponse<Product>>(
      // Network operation
      () async {
        if (remoteDataSource is ProductSupabaseDataSource) {
          final supabaseDataSource = remoteDataSource as ProductSupabaseDataSource;
          return await supabaseDataSource.getProductsPaginated(
            pagination: pagination,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            searchQuery: searchQuery,
            sortBy: sortBy,
            ascending: ascending,
            minPrice: minPrice,
            maxPrice: maxPrice,
          );
        } else {
          // Fallback to legacy method and wrap in pagination response
          final products = await remoteDataSource.getProducts(
            page: pagination?.page,
            limit: pagination?.limit,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            searchQuery: searchQuery,
            sortBy: sortBy,
            ascending: ascending,
            minPrice: minPrice,
            maxPrice: maxPrice,
          );

          // Create pagination metadata (estimated)
          final meta = PaginationMeta.fromParams(
            params: pagination ?? const PaginationParams.defaultProducts(),
            totalItems: products.length, // This is an estimate
          );

          return PaginatedResponse(data: products, meta: meta);
        }
      },
      // Cache operation (try to get cached data)
      () async {
        try {
          final cachedProducts = await localDataSource.getCachedProducts();
          if (cachedProducts.isNotEmpty) {
            final meta = PaginationMeta.fromParams(
              params: pagination ?? const PaginationParams.defaultProducts(),
              totalItems: cachedProducts.length,
            );
            return PaginatedResponse(data: cachedProducts, meta: meta);
          }
        } catch (e) {
          // Cache read failed
        }
        return null;
      },
      // Cache store operation
      (data) async {
        // Convert Product entities to ProductModel for caching
        final productModels = data.data.map((product) {
          if (product is ProductModel) {
            return product;
          } else {
            // Convert Product entity to ProductModel if needed
            return ProductModel.fromProduct(product);
          }
        }).toList();
        await _cacheProducts(productModels);
      },
      operationType: NetworkOperation.data,
      operationName: 'get products paginated',
    );
  }

  /// Cache products for offline access
  Future<void> _cacheProducts(List<ProductModel> products) async {
    try {
      await localDataSource.cacheProducts(products);
    } catch (_) {
      // Silently fail if caching is not supported or fails
    }
  }

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

  /// Search products within specific scope (subcategory or category)
  @override
  Future<Either<Failure, List<Product>>> searchProductsScoped({
    required String query,
    String? subcategoryId,
    String? categoryId,
    int? page,
    int? limit,
  }) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProducts(
        searchQuery: query,
        subcategoryId: subcategoryId,
        categoryId: categoryId,
        page: page,
        limit: limit,
      ),
      getCachedData: () => localDataSource.getCachedSearchResults('${query}_scoped'),
      cacheData: (products) => localDataSource.cacheSearchResults('${query}_scoped', products),
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