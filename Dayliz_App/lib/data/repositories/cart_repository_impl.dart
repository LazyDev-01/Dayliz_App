import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_data_source.dart';
import '../datasources/cart_remote_data_source.dart';

/// Implementation of the [CartRepository] that uses remote and local data sources
class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;
  final CartLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final remoteCartItems = await remoteDataSource.getCartItems();
          await localDataSource.cacheCartItems(remoteCartItems);
          return Right(remoteCartItems);
        } catch (e) {
          // If remote data source fails, try to get from local
        }
      }
      
      // Return local cart items if offline or remote fails
      final localCartItems = await localDataSource.getCachedCartItems();
      return Right(localCartItems);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

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
          
          if (success) {
            // Update local cache
            await localDataSource.removeFromLocalCart(cartItemId: cartItemId);
          }
          
          return Right(success);
        } catch (e) {
          // If remote data source fails, remove from local
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

  @override
  Future<Either<Failure, CartItem>> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final updatedCartItem = await remoteDataSource.updateQuantity(
            cartItemId: cartItemId,
            quantity: quantity,
          );
          
          // Update local cache
          await localDataSource.updateLocalQuantity(
            cartItemId: cartItemId,
            quantity: quantity,
          );
          
          return Right(updatedCartItem);
        } catch (e) {
          // If remote data source fails, update local
        }
      }
      
      // Update local cart if offline or remote fails
      final updatedCartItem = await localDataSource.updateLocalQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      
      return Right(updatedCartItem);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearCart() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final success = await remoteDataSource.clearCart();
          
          if (success) {
            // Clear local cache
            await localDataSource.clearLocalCart();
          }
          
          return Right(success);
        } catch (e) {
          // If remote data source fails, clear local
        }
      }
      
      // Clear local cart if offline or remote fails
      final success = await localDataSource.clearLocalCart();
      
      return Right(success);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPrice() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final totalPrice = await remoteDataSource.getTotalPrice();
          return Right(totalPrice);
        } catch (e) {
          // If remote data source fails, get from local
        }
      }
      
      // Get from local cart if offline or remote fails
      final totalPrice = await localDataSource.getLocalTotalPrice();
      
      return Right(totalPrice);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getItemCount() async {
    try {
      if (await networkInfo.isConnected) {
        try {
          final itemCount = await remoteDataSource.getItemCount();
          return Right(itemCount);
        } catch (e) {
          // If remote data source fails, get from local
        }
      }
      
      // Get from local cart if offline or remote fails
      final itemCount = await localDataSource.getLocalItemCount();
      
      return Right(itemCount);
    } on CartException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

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