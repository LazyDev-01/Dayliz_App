import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show debugPrint;
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

  // Feature flag for hybrid cart strategy - enabled for production readiness
  static const bool _useDatabaseOperations = true; // Hybrid mode: local-first with background sync

  // Background sync management
  Timer? _backgroundSyncTimer;
  bool _isBackgroundSyncActive = false;
  static const Duration _backgroundSyncInterval = Duration(seconds: 30);

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) {
    // Start background sync when hybrid mode is enabled
    if (_useDatabaseOperations) {
      _startBackgroundSync();
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() async {
    try {
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        debugPrint('🛒 CART REPO: Using local-only mode for early launch');
        final localCartItems = await localDataSource.getCachedCartItems();
        return Right(localCartItems);
      }

      // Future: Database sync implementation (preserved for post-launch)
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
    debugPrint('🛒 CART REPO: Adding ${product.name} (qty: $quantity) to cart');

    try {
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        debugPrint('🛒 CART REPO: Using local-only mode - adding to local storage...');
        final localCartItem = await localDataSource.addToLocalCart(
          product: product,
          quantity: quantity,
        );
        debugPrint('🛒 CART REPO: ✅ Local add completed');
        return Right(localCartItem);
      }

      // Future: Database sync implementation (preserved for post-launch)
      final isConnected = await networkInfo.isConnected;
      debugPrint('🛒 CART REPO: Network connected: $isConnected');

      if (isConnected) {
        try {
          debugPrint('🛒 CART REPO: Attempting remote add to cart...');
          final remoteCartItem = await remoteDataSource.addToCart(
            product: product,
            quantity: quantity,
          );

          debugPrint('🛒 CART REPO: ✅ Remote add successful, updating local cache...');
          // Update local cache with the database cart item (including correct ID)
          await _syncLocalCartWithDatabase();

          debugPrint('🛒 CART REPO: ✅ Database sync completed successfully');
          return Right(remoteCartItem);
        } catch (e) {
          debugPrint('🛒 CART REPO: ❌ Remote add failed: $e');
          debugPrint('🛒 CART REPO: Falling back to local storage...');
          // If remote data source fails, add to local
        }
      } else {
        debugPrint('🛒 CART REPO: No network connection, using local storage');
      }

      // Add to local cart if offline or remote fails
      debugPrint('🛒 CART REPO: Adding to local storage...');
      final localCartItem = await localDataSource.addToLocalCart(
        product: product,
        quantity: quantity,
      );

      debugPrint('🛒 CART REPO: ✅ Local add completed');
      return Right(localCartItem);
    } on CartException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartLocalException: ${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Unexpected error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> removeFromCart({
    required String cartItemId,
  }) async {
    debugPrint('🛒 CART REPO: Removing cart item: $cartItemId');

    try {
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        debugPrint('🛒 CART REPO: Using local-only mode - removing from local storage...');
        final success = await localDataSource.removeFromLocalCart(
          cartItemId: cartItemId,
        );
        debugPrint('🛒 CART REPO: ✅ Local remove completed');
        return Right(success);
      }

      // Future: Database sync implementation (preserved for post-launch)
      final isConnected = await networkInfo.isConnected;
      debugPrint('🛒 CART REPO: Network connected: $isConnected');

      if (isConnected) {
        try {
          debugPrint('🛒 CART REPO: Attempting remote remove from cart...');
          final success = await remoteDataSource.removeFromCart(
            cartItemId: cartItemId,
          );

          if (success) {
            debugPrint('🛒 CART REPO: ✅ Remote remove successful, syncing local cache...');
            // Sync local cache with database to ensure consistency
            await _syncLocalCartWithDatabase();
            debugPrint('🛒 CART REPO: ✅ Database sync completed successfully');
          }

          return Right(success);
        } catch (e) {
          debugPrint('🛒 CART REPO: ❌ Remote remove failed: $e');
          debugPrint('🛒 CART REPO: Falling back to local storage...');
          // If remote data source fails, remove from local
        }
      } else {
        debugPrint('🛒 CART REPO: No network connection, using local storage');
      }

      // Remove from local cart if offline or remote fails
      debugPrint('🛒 CART REPO: Removing from local storage...');
      final success = await localDataSource.removeFromLocalCart(
        cartItemId: cartItemId,
      );

      debugPrint('🛒 CART REPO: ✅ Local remove completed');
      return Right(success);
    } on CartException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartLocalException: ${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Unexpected error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CartItem>> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    debugPrint('🛒 CART REPO: Updating cart item: $cartItemId to quantity: $quantity');

    try {
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        debugPrint('🛒 CART REPO: Using local-only mode - updating local storage...');
        final updatedCartItem = await localDataSource.updateLocalQuantity(
          cartItemId: cartItemId,
          quantity: quantity,
        );
        debugPrint('🛒 CART REPO: ✅ Local update completed');
        return Right(updatedCartItem);
      }

      // Future: Database sync implementation (preserved for post-launch)
      final isConnected = await networkInfo.isConnected;
      debugPrint('🛒 CART REPO: Network connected: $isConnected');

      if (isConnected) {
        try {
          debugPrint('🛒 CART REPO: Attempting remote quantity update...');
          final updatedCartItem = await remoteDataSource.updateQuantity(
            cartItemId: cartItemId,
            quantity: quantity,
          );

          debugPrint('🛒 CART REPO: ✅ Remote update successful, syncing local cache...');
          // Sync local cache with database to ensure consistency
          await _syncLocalCartWithDatabase();

          debugPrint('🛒 CART REPO: ✅ Database sync completed successfully');
          return Right(updatedCartItem);
        } catch (e) {
          debugPrint('🛒 CART REPO: ❌ Remote update failed: $e');
          debugPrint('🛒 CART REPO: Falling back to local storage...');
          // If remote data source fails, update local
        }
      } else {
        debugPrint('🛒 CART REPO: No network connection, using local storage');
      }

      // Update local cart if offline or remote fails
      debugPrint('🛒 CART REPO: Updating local storage...');
      final updatedCartItem = await localDataSource.updateLocalQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      debugPrint('🛒 CART REPO: ✅ Local update completed');
      return Right(updatedCartItem);
    } on CartException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartLocalException: ${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Unexpected error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearCart() async {
    debugPrint('🛒 CART REPO: Clearing entire cart');

    try {
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        debugPrint('🛒 CART REPO: Using local-only mode - clearing local storage...');
        final success = await localDataSource.clearLocalCart();
        debugPrint('🛒 CART REPO: ✅ Local clear completed');
        return Right(success);
      }

      // Future: Database sync implementation (preserved for post-launch)
      final isConnected = await networkInfo.isConnected;
      debugPrint('🛒 CART REPO: Network connected: $isConnected');

      if (isConnected) {
        try {
          debugPrint('🛒 CART REPO: Attempting remote cart clear...');
          final success = await remoteDataSource.clearCart();

          if (success) {
            debugPrint('🛒 CART REPO: ✅ Remote clear successful, syncing local cache...');
            // Sync local cache with database (should be empty now)
            await _syncLocalCartWithDatabase();
            debugPrint('🛒 CART REPO: ✅ Database sync completed successfully');
          }

          return Right(success);
        } catch (e) {
          debugPrint('🛒 CART REPO: ❌ Remote clear failed: $e');
          debugPrint('🛒 CART REPO: Falling back to local storage...');
          // If remote data source fails, clear local
        }
      } else {
        debugPrint('🛒 CART REPO: No network connection, using local storage');
      }

      // Clear local cart if offline or remote fails
      debugPrint('🛒 CART REPO: Clearing local storage...');
      final success = await localDataSource.clearLocalCart();

      debugPrint('🛒 CART REPO: ✅ Local clear completed');
      return Right(success);
    } on CartException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      debugPrint('🛒 CART REPO: ❌ CartLocalException: ${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Unexpected error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPrice() async {
    try {
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        final totalPrice = await localDataSource.getLocalTotalPrice();
        return Right(totalPrice);
      }

      // Future: Database sync implementation (preserved for post-launch)
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
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        final itemCount = await localDataSource.getLocalItemCount();
        return Right(itemCount);
      }

      // Future: Database sync implementation (preserved for post-launch)
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
      // Early launch: Use only local storage for faster market reach
      if (!_useDatabaseOperations) {
        final isInCart = await localDataSource.isInLocalCart(
          productId: productId,
        );
        return Right(isInCart);
      }

      // Future: Database sync implementation (preserved for post-launch)
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

  /// Start background sync for hybrid cart strategy
  void _startBackgroundSync() {
    if (!_useDatabaseOperations) return;

    debugPrint('🔄 CART SYNC: Starting background sync (interval: ${_backgroundSyncInterval.inSeconds}s)');
    _isBackgroundSyncActive = true;

    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (timer) {
      _performBackgroundSync();
    });
  }

  /// Stop background sync
  void _stopBackgroundSync() {
    debugPrint('🔄 CART SYNC: Stopping background sync');
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
    _isBackgroundSyncActive = false;
  }

  /// Perform background sync validation
  Future<void> _performBackgroundSync() async {
    if (!_useDatabaseOperations || !_isBackgroundSyncActive) return;

    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        debugPrint('🔄 CART SYNC: Skipping background sync - no network connection');
        return;
      }

      debugPrint('🔄 CART SYNC: Performing background validation...');

      // Sync local cart with database to ensure consistency
      await _syncLocalCartWithDatabase();

      debugPrint('🔄 CART SYNC: ✅ Background sync completed');
    } catch (e) {
      debugPrint('🔄 CART SYNC: ❌ Background sync failed: $e');
      // Don't throw error - this is background operation
    }
  }

  /// Trigger immediate sync for critical operations
  Future<void> _triggerImmediateSync() async {
    if (!_useDatabaseOperations) return;

    try {
      final isConnected = await networkInfo.isConnected;
      if (isConnected) {
        debugPrint('🚀 CART SYNC: Triggering immediate sync...');
        await _syncLocalCartWithDatabase();
        debugPrint('🚀 CART SYNC: ✅ Immediate sync completed');
      } else {
        debugPrint('🚀 CART SYNC: Skipping immediate sync - no network connection');
      }
    } catch (e) {
      debugPrint('🚀 CART SYNC: ❌ Immediate sync failed: $e');
      // Don't throw error - sync failure shouldn't break cart operations
    }
  }

  /// Dispose resources
  void dispose() {
    _stopBackgroundSync();
  }

  /// Sync local cart with database to ensure IDs match
  /// Enhanced for hybrid cart strategy with real-time validation
  Future<void> _syncLocalCartWithDatabase() async {
    // Skip sync if hybrid mode is disabled
    if (!_useDatabaseOperations) {
      debugPrint('🛒 CART REPO: Skipping database sync - hybrid mode disabled');
      return;
    }

    try {
      debugPrint('🛒 CART REPO: Syncing local cart with database...');

      // Get cart items from database (with correct UUIDs)
      final remoteCartItems = await remoteDataSource.getCartItems();

      // Update local cache with database items (this ensures IDs match)
      await localDataSource.cacheCartItems(remoteCartItems);

      debugPrint('🛒 CART REPO: ✅ Local cart synced with database (${remoteCartItems.length} items)');
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Failed to sync local cart with database: $e');
      // Don't throw error - this is a sync operation, not critical
    }
  }
}