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

  // Local-first background sync management
  Timer? _backgroundSyncTimer;
  bool _isBackgroundSyncActive = false;
  DateTime? _lastSyncTime;
  DateTime? _lastUserActivity;

  // Intelligent sync intervals
  static const Duration _minSyncInterval = Duration(minutes: 5); // Minimum 5 minutes between syncs
  static const Duration _maxSyncInterval = Duration(minutes: 15); // Maximum 15 minutes without sync
  static const Duration _userActivityThreshold = Duration(minutes: 2); // Consider user active if activity within 2 minutes

  CartRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  }) {
    // Initialize activity tracking
    _lastUserActivity = DateTime.now();

    // Start intelligent background sync when hybrid mode is enabled
    if (_useDatabaseOperations) {
      _startIntelligentBackgroundSync();
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() async {
    try {
      // Track user activity for intelligent sync
      _recordUserActivity();

      // LOCAL-FIRST: Always return local data immediately (lazy sync strategy)
      debugPrint('🛒 CART REPO: Fetching from local storage (lazy sync strategy)');
      final localCartItems = await localDataSource.getCachedCartItems();

      return Right(localCartItems);
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
      // Track user activity for intelligent sync
      _recordUserActivity();

      // LOCAL-FIRST: Add to local storage immediately (no immediate database sync)
      debugPrint('🛒 CART REPO: Adding to local storage (lazy sync strategy)');
      final localCartItem = await localDataSource.addToLocalCart(
        product: product,
        quantity: quantity,
      );
      debugPrint('🛒 CART REPO: ✅ Local add completed instantly - database sync deferred');

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
      // LOCAL-FIRST: Remove from local storage immediately (no immediate database sync)
      debugPrint('🛒 CART REPO: Removing from local storage (lazy sync strategy)');
      final success = await localDataSource.removeFromLocalCart(
        cartItemId: cartItemId,
      );
      debugPrint('🛒 CART REPO: ✅ Local remove completed instantly - database sync deferred');

      return Right(success);
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
      // Track user activity for intelligent sync
      _recordUserActivity();

      // LOCAL-FIRST: Update local storage immediately (no immediate database sync)
      debugPrint('🛒 CART REPO: Updating local storage (lazy sync strategy)');
      final updatedCartItem = await localDataSource.updateLocalQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );
      debugPrint('🛒 CART REPO: ✅ Local update completed instantly - database sync deferred');

      return Right(updatedCartItem);
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Unexpected error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> clearCart() async {
    debugPrint('🛒 CART REPO: Clearing entire cart');

    try {
      // Track user activity for intelligent sync
      _recordUserActivity();

      // LOCAL-FIRST: Clear local storage immediately (no immediate database sync)
      debugPrint('🛒 CART REPO: Clearing local storage (lazy sync strategy)');
      final success = await localDataSource.clearLocalCart();
      debugPrint('🛒 CART REPO: ✅ Local clear completed instantly - database sync deferred');

      return Right(success);
    } catch (e) {
      debugPrint('🛒 CART REPO: ❌ Unexpected error: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalPrice() async {
    try {
      // Track user activity for intelligent sync
      _recordUserActivity();

      // LOCAL-FIRST: Always get total price from local storage (lazy sync strategy)
      debugPrint('🛒 CART REPO: Getting total price from local storage (lazy sync strategy)');
      final totalPrice = await localDataSource.getLocalTotalPrice();
      debugPrint('🛒 CART REPO: ✅ Local total price: ₹$totalPrice');

      return Right(totalPrice);
    } on CartLocalException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getItemCount() async {
    try {
      // Track user activity for intelligent sync
      _recordUserActivity();

      // LOCAL-FIRST: Always get count from local storage (lazy sync strategy)
      debugPrint('🛒 CART REPO: Getting item count from local storage (lazy sync strategy)');
      final itemCount = await localDataSource.getLocalItemCount();
      debugPrint('🛒 CART REPO: ✅ Local item count: $itemCount');

      return Right(itemCount);
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

  /// Record user activity for intelligent sync timing
  void _recordUserActivity() {
    _lastUserActivity = DateTime.now();
  }

  /// Lazy database sync - sync local cart with database when needed
  /// This is the main sync method called when user navigates to cart or checkout
  @override
  Future<Either<Failure, bool>> syncCartWithDatabase() async {
    if (!_useDatabaseOperations) {
      debugPrint('🔄 LAZY SYNC: Database operations disabled, skipping sync');
      return const Right(true);
    }

    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        debugPrint('🔄 LAZY SYNC: No network connection, skipping sync');
        return const Right(false);
      }

      debugPrint('🔄 LAZY SYNC: Starting cart synchronization with database...');

      // Get current local cart items
      final localCartItems = await localDataSource.getCachedCartItems();
      debugPrint('🔄 LAZY SYNC: Found ${localCartItems.length} local cart items');

      // Get current database cart items
      final remoteCartItems = await remoteDataSource.getCartItems();
      debugPrint('🔄 LAZY SYNC: Found ${remoteCartItems.length} database cart items');

      // Clear database cart first (clean slate approach)
      await remoteDataSource.clearCart();
      debugPrint('🔄 LAZY SYNC: Database cart cleared');

      // Sync all local items to database
      for (final localItem in localCartItems) {
        await remoteDataSource.addToCart(
          product: localItem.product,
          quantity: localItem.quantity,
        );
      }

      debugPrint('🔄 LAZY SYNC: ✅ Successfully synced ${localCartItems.length} items to database');
      _lastSyncTime = DateTime.now();

      return const Right(true);
    } catch (e) {
      debugPrint('🔄 LAZY SYNC: ❌ Sync failed: $e');
      return Left(ServerFailure(message: 'Failed to sync cart: $e'));
    }
  }

  /// Check if user has been active recently
  bool _isUserActive() {
    if (_lastUserActivity == null) return false;
    return DateTime.now().difference(_lastUserActivity!) < _userActivityThreshold;
  }

  /// Check if sync is needed based on time and activity
  bool _shouldSync() {
    if (_lastSyncTime == null) return true; // First sync

    final timeSinceLastSync = DateTime.now().difference(_lastSyncTime!);

    // Force sync if max interval exceeded
    if (timeSinceLastSync > _maxSyncInterval) return true;

    // Sync if user is active and minimum interval passed
    if (_isUserActive() && timeSinceLastSync > _minSyncInterval) return true;

    return false;
  }



  /// Start intelligent background sync with activity-based timing
  void _startIntelligentBackgroundSync() {
    if (!_useDatabaseOperations) return;

    debugPrint('🔄 CART SYNC: Starting intelligent background sync');
    debugPrint('🔄 CART SYNC: Min interval: ${_minSyncInterval.inMinutes}min, Max interval: ${_maxSyncInterval.inMinutes}min');
    _isBackgroundSyncActive = true;

    // Check every minute if sync is needed (much less aggressive)
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _performIntelligentBackgroundSync();
    });
  }

  /// Stop background sync with proper cleanup
  void _stopBackgroundSync() {
    debugPrint('🔄 CART SYNC: Stopping intelligent background sync');
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
    _isBackgroundSyncActive = false;
  }

  /// Perform intelligent background sync only when needed
  Future<void> _performIntelligentBackgroundSync() async {
    if (!_useDatabaseOperations || !_isBackgroundSyncActive) return;

    // Only sync if conditions are met
    if (!_shouldSync()) {
      return; // Skip this sync cycle
    }

    try {
      final isConnected = await networkInfo.isConnected;
      if (!isConnected) {
        debugPrint('🔄 CART SYNC: Skipping sync - no network connection');
        return;
      }

      debugPrint('🔄 CART SYNC: Performing intelligent background sync...');

      // Use the new lazy sync method
      await syncCartWithDatabase();

      // Update last sync time
      _lastSyncTime = DateTime.now();

      debugPrint('🔄 CART SYNC: ✅ Intelligent sync completed');
    } catch (e) {
      debugPrint('🔄 CART SYNC: ❌ Intelligent sync failed: $e');
      // Don't throw error - this is background operation
    }
  }

  @override
  Future<Either<Failure, bool>> migrateGuestCartToUser() async {
    try {
      debugPrint('🔄 CART MIGRATION: Starting guest cart migration to authenticated user');

      // Get current local cart items (guest cart)
      final localCartItems = await localDataSource.getCachedCartItems();

      if (localCartItems.isEmpty) {
        debugPrint('✅ CART MIGRATION: No guest cart items to migrate');
        return const Right(true);
      }

      debugPrint('🔄 CART MIGRATION: Found ${localCartItems.length} guest cart items to migrate');

      // If database operations are disabled, just keep local cart as-is
      if (!_useDatabaseOperations) {
        debugPrint('✅ CART MIGRATION: Database operations disabled, keeping local cart');
        return const Right(true);
      }

      // Check network connectivity
      if (!(await networkInfo.isConnected)) {
        debugPrint('⚠️ CART MIGRATION: No network connection, migration will happen on next sync');
        return const Right(true);
      }

      // Migrate each item to the database
      int successCount = 0;
      int failureCount = 0;

      for (final cartItem in localCartItems) {
        try {
          // Add item to remote database
          await remoteDataSource.addToCart(
            product: cartItem.product,
            quantity: cartItem.quantity,
          );
          successCount++;
          debugPrint('✅ CART MIGRATION: Migrated item ${cartItem.product.name}');
        } catch (e) {
          failureCount++;
          debugPrint('❌ CART MIGRATION: Failed to migrate item ${cartItem.product.name}: $e');
        }
      }

      debugPrint('🎯 CART MIGRATION: Migration completed - Success: $successCount, Failed: $failureCount');

      // If all items migrated successfully, we can consider it a success
      // Even if some failed, the user still has their local cart
      if (successCount > 0) {
        debugPrint('✅ CART MIGRATION: Migration successful');
        return const Right(true);
      } else if (failureCount > 0) {
        debugPrint('⚠️ CART MIGRATION: Some items failed to migrate, but local cart preserved');
        return const Right(true); // Still return success since local cart is preserved
      }

      return const Right(true);

    } on CartException catch (e) {
      debugPrint('❌ CART MIGRATION: CartException: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } on CartLocalException catch (e) {
      debugPrint('❌ CART MIGRATION: CartLocalException: ${e.message}');
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      debugPrint('❌ CART MIGRATION: Unexpected error: $e');
      return Left(ServerFailure(message: 'Cart migration failed: ${e.toString()}'));
    }
  }

  /// Dispose resources and cleanup
  void dispose() {
    debugPrint('🔄 LAZY SYNC: Disposing repository resources...');
    _stopBackgroundSync();
  }
}