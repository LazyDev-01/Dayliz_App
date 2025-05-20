import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../datasources/wishlist_local_data_source.dart';
import '../datasources/wishlist_remote_data_source.dart';
import '../models/product_model.dart';
import '../models/wishlist_item_model.dart';

/// Implementation of the WishlistRepository that uses both remote and local data sources
/// Updated to use the new database functions for improved performance
class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource remoteDataSource;
  final WishlistLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SupabaseClient supabaseClient;

  WishlistRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.supabaseClient,
  });

  /// Get all wishlist items for the current user
  @override
  Future<Either<Failure, List<WishlistItem>>> getWishlistItems() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItems = await remoteDataSource.getWishlistItems();
        return Right(remoteItems);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localItems = await localDataSource.getWishlistItems();
        return Right(localItems);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Add a product to the wishlist
  @override
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteItem = await remoteDataSource.addToWishlist(productId);
        await localDataSource.addToWishlist(productId);
        return Right(remoteItem);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final localItem = await localDataSource.addToWishlist(productId);
        return Right(localItem);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Remove a product from the wishlist
  @override
  Future<Either<Failure, bool>> removeFromWishlist(String wishlistItemId) async {
    if (await networkInfo.isConnected) {
      try {
        final success = await remoteDataSource.removeFromWishlist(wishlistItemId);
        await localDataSource.removeFromWishlist(wishlistItemId);
        return Right(success);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final success = await localDataSource.removeFromWishlist(wishlistItemId);
        return Right(success);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Check if a product is in the wishlist
  @override
  Future<Either<Failure, bool>> isInWishlist(String productId) async {
    if (await networkInfo.isConnected) {
      try {
        final isInWishlist = await remoteDataSource.isInWishlist(productId);
        return Right(isInWishlist);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final isInWishlist = await localDataSource.isInWishlist(productId);
        return Right(isInWishlist);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Get all products in the wishlist
  /// Uses the new get_user_wishlist database function
  @override
  Future<Either<Failure, List<Product>>> getWishlistProducts() async {
    if (await networkInfo.isConnected) {
      try {
        // Use the database function to get wishlist items with product details in a single query
        final result = await supabaseClient.rpc('get_user_wishlist');
        
        if (result.error != null) {
          // If the database function fails, fall back to the standard implementation
          return _getWishlistProductsStandard();
        }
        
        final products = (result.data as List).map((item) {
          return ProductModel(
            id: item['product_id'],
            name: item['product_name'],
            description: item['product_description'],
            price: item['product_price'] != null 
                ? double.parse(item['product_price'].toString()) 
                : 0.0,
            discountPercentage: item['discount_percentage'] != null 
                ? double.parse(item['discount_percentage'].toString()) 
                : 0.0,
            mainImageUrl: item['main_image_url'],
            inStock: item['in_stock'] ?? true,
            stockQuantity: item['stock_quantity'] ?? 0,
            categoryId: item['category_id'],
            subcategoryId: item['subcategory_id'],
            categoryName: item['category_name'],
            subcategoryName: item['subcategory_name'],
            brand: '',
            tags: [],
            attributes: {},
            images: [],
            averageRating: 0.0,
            reviewCount: 0,
          );
        }).toList();
        
        // Cache the wishlist products locally
        await localDataSource.cacheWishlistProducts(products);
        
        return Right(products);
      } on PostgrestException catch (e) {
        debugPrint('Database error in getWishlistProducts: ${e.message}');
        // If the database function fails, fall back to the standard implementation
        return _getWishlistProductsStandard();
      } catch (e) {
        debugPrint('Error in getWishlistProducts: $e');
        // If any other error occurs, fall back to the standard implementation
        return _getWishlistProductsStandard();
      }
    } else {
      // If offline, use local data source
      try {
        final localProducts = await localDataSource.getCachedWishlistProducts();
        return Right(localProducts);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Standard implementation of getWishlistProducts as a fallback
  Future<Either<Failure, List<Product>>> _getWishlistProductsStandard() async {
    try {
      final remoteProducts = await remoteDataSource.getWishlistProducts();
      await localDataSource.cacheWishlistProducts(remoteProducts);
      return Right(remoteProducts);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
