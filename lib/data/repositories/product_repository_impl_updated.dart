import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_search_result.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_local_data_source.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

/// Implementation of the ProductRepository that uses both remote and local data sources
/// Updated to use the new database features for improved performance
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SupabaseClient supabaseClient;

  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.supabaseClient,
  });

  /// Get a list of products with optional filters
  /// Uses the standard repository pattern
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

  /// Search products using full-text search
  /// Uses the new search_products_full_text database function
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
            });
        
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
      } on PostgrestException catch (e) {
        return Left(ServerFailure(message: 'Database error: ${e.message}'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      // Fallback to local search if offline
      try {
        final localProducts = await localDataSource.searchCachedProducts(query);
        return Right(ProductSearchResult(
          products: localProducts,
          totalCount: localProducts.length,
          page: 1,
          pageSize: localProducts.length,
        ));
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
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

  /// Get related products for a product
  /// Uses the new get_related_products database function
  @override
  Future<Either<Failure, List<Product>>> getRelatedProducts(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await supabaseClient
            .rpc('get_related_products', params: {
              'product_id_param': productId,
              'limit_param': 10,
            });
        
        if (result.error != null) {
          return Left(ServerFailure(message: result.error!.message));
        }
        
        final products = (result.data as List)
            .map((item) => ProductModel.fromJson(item))
            .toList();
        
        return Right(products);
      } on PostgrestException catch (e) {
        return Left(ServerFailure(message: 'Database error: ${e.message}'));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      // Fallback to standard implementation if offline
      return await _getProducts(
        getRemoteData: () => remoteDataSource.getRelatedProducts(productId),
        getCachedData: () => localDataSource.getLastRelatedProducts(productId),
        cacheData: (products) => localDataSource.cacheRelatedProducts(productId, products),
      );
    }
  }

  /// Get products by category
  /// Uses the standard repository pattern
  @override
  Future<Either<Failure, List<Product>>> getProductsByCategory(String categoryId) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProductsByCategory(categoryId),
      getCachedData: () => localDataSource.getLastProductsByCategory(categoryId),
      cacheData: (products) => localDataSource.cacheProductsByCategory(categoryId, products),
    );
  }

  /// Get products by list of IDs
  /// Uses the standard repository pattern
  @override
  Future<Either<Failure, List<Product>>> getProductsByIds(List<String> ids) async {
    return await _getProducts(
      getRemoteData: () => remoteDataSource.getProductsByIds(ids),
      getCachedData: () => localDataSource.getLastProductsByIds(ids),
      cacheData: (products) => localDataSource.cacheProductsByIds(ids, products),
    );
  }

  /// Helper method to get products with caching
  Future<Either<Failure, List<Product>>> _getProducts({
    required Future<List<ProductModel>> Function() getRemoteData,
    required Future<List<ProductModel>> Function() getCachedData,
    required Future<void> Function(List<ProductModel>) cacheData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteProducts = await getRemoteData();
        await cacheData(remoteProducts);
        return Right(remoteProducts);
      } on ServerException catch (e) {
        try {
          final localProducts = await getCachedData();
          return Right(localProducts);
        } on CacheException {
          return Left(ServerFailure(message: e.message));
        }
      }
    } else {
      try {
        final localProducts = await getCachedData();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      }
    }
  }
}
