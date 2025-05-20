import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';
import '../datasources/cart_remote_data_source.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

/// Implementation of the CartRepository that uses both remote and local data sources
/// Updated to use the new database functions for improved performance
class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SupabaseClient supabaseClient;

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.supabaseClient,
  });

  /// Get all cart items for the current user
  /// Uses the new get_user_cart database function for improved performance
  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() async {
    if (await networkInfo.isConnected) {
      try {
        // Use the database function to get cart items with product details in a single query
        final result = await supabaseClient.rpc('get_user_cart');
        
        if (result.error != null) {
          // If the database function fails, fall back to the standard implementation
          return _getCartItemsStandard();
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
      } on PostgrestException catch (e) {
        debugPrint('Database error in getCartItems: ${e.message}');
        // If the database function fails, fall back to the standard implementation
        return _getCartItemsStandard();
      } catch (e) {
        debugPrint('Error in getCartItems: $e');
        // If any other error occurs, fall back to the standard implementation
        return _getCartItemsStandard();
      }
    } else {
      // If offline, use local data source
      try {
        final localCartItems = await localDataSource.getCachedCartItems();
        return Right(localCartItems);
      } on CacheException catch (e) {
        return Left(CacheFailure(message: e.message));
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  /// Standard implementation of getCartItems as a fallback
  Future<Either<Failure, List<CartItem>>> _getCartItemsStandard() async {
    try {
      final remoteCartItems = await remoteDataSource.getCartItems();
      await localDataSource.cacheCartItems(remoteCartItems);
      return Right(remoteCartItems);
    } on CartException catch (e) {
      try {
        final localCartItems = await localDataSource.getCachedCartItems();
        return Right(localCartItems);
      } on CartLocalException {
        return Left(ServerFailure(message: e.message));
      }
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Add a product to the cart
  @override
  Future<Either<Failure, CartItem>> addToCart({
    required Product product,
    required int quantity,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteCartItem = await remoteDataSource.addToCart(
            product: product,
            quantity: quantity,
          );
          
          // Update local cache
          await localDataSource.addToLocalCart(
            product: product,
            quantity: quantity,
          );
          
          return Right(remoteCartItem);
        } catch (e) {
          // If remote data source fails, add to local
          debugPrint('Failed to add to remote cart: $e');
        }
      }
      
      // Add to local cart if offline or remote fails
      final localCartItem = await localDataSource.addToLocalCart(
        product: product,
        quantity: quantity,
      );
      
      return Right(localCartItem);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Update the quantity of a cart item
  @override
  Future<Either<Failure, CartItem>> updateCartItemQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteCartItem = await remoteDataSource.updateCartItemQuantity(
            cartItemId: cartItemId,
            quantity: quantity,
          );
          
          // Update local cache
          await localDataSource.updateLocalCartItemQuantity(
            cartItemId: cartItemId,
            quantity: quantity,
          );
          
          return Right(remoteCartItem);
        } catch (e) {
          // If remote data source fails, update local
          debugPrint('Failed to update remote cart item: $e');
        }
      }
      
      // Update local cart if offline or remote fails
      final localCartItem = await localDataSource.updateLocalCartItemQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      
      return Right(localCartItem);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Remove an item from the cart
  @override
  Future<Either<Failure, bool>> removeFromCart({
    required String cartItemId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final success = await remoteDataSource.removeFromCart(
            cartItemId: cartItemId,
          );
          
          // Update local cache
          await localDataSource.removeFromLocalCart(
            cartItemId: cartItemId,
          );
          
          return Right(success);
        } catch (e) {
          // If remote data source fails, remove from local
          debugPrint('Failed to remove from remote cart: $e');
        }
      }
      
      // Remove from local cart if offline or remote fails
      final success = await localDataSource.removeFromLocalCart(
        cartItemId: cartItemId,
      );
      
      return Right(success);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Check if a product is in the cart
  @override
  Future<Either<Failure, bool>> isInCart({
    required String productId,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final isInCart = await remoteDataSource.isInCart(
            productId: productId,
          );
          return Right(isInCart);
        } catch (e) {
          // If remote data source fails, check local
          debugPrint('Failed to check remote cart: $e');
        }
      }
      
      // Check local cart if offline or remote fails
      final isInCart = await localDataSource.isInLocalCart(
        productId: productId,
      );
      
      return Right(isInCart);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
