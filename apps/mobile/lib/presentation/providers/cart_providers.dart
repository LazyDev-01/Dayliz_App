import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../core/errors/failures.dart';
import '../../core/models/coupon.dart';
import '../../core/services/coupon_service.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/usecases/get_cart_items_usecase.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_quantity_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_total_price_usecase.dart';
import '../../domain/usecases/get_cart_item_count_usecase.dart';
import '../../domain/usecases/is_in_cart_usecase.dart';

// Get the service locator instance
final sl = GetIt.instance;

// Verify cart dependencies are registered
bool _checkCartDependencies() {
  try {
    return sl.isRegistered<GetCartItemsUseCase>();
  } catch (e) {
    return false;
  }
}

final bool _cartDependenciesRegistered = _checkCartDependencies();

/// Cart state class to manage cart-related state
class CartState {
  final bool isLoading;
  final String? errorMessage;
  final List<CartItem> items;
  final double totalPrice;
  final int itemCount;
  final AppliedCoupon? appliedCoupon;
  final String? couponErrorMessage;

  // Hybrid cart strategy: Track items being validated
  final Set<String> validatingItemIds;
  final bool isBackgroundSyncing;

  /// Total quantity of items (sum of all quantities)
  int get totalQuantity => items.fold(0, (total, item) => total + item.quantity);

  /// Check if a specific item is being validated
  bool isItemValidating(String itemId) => validatingItemIds.contains(itemId);

  CartState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.totalPrice = 0.0,
    this.itemCount = 0,
    this.appliedCoupon,
    this.couponErrorMessage,
    this.validatingItemIds = const {},
    this.isBackgroundSyncing = false,
  });

  CartState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CartItem>? items,
    double? totalPrice,
    int? itemCount,
    AppliedCoupon? appliedCoupon,
    String? couponErrorMessage,
    Set<String>? validatingItemIds,
    bool? isBackgroundSyncing,
    bool clearError = false,
    bool clearCouponError = false,
    bool clearCoupon = false,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      itemCount: itemCount ?? this.itemCount,
      appliedCoupon: clearCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      couponErrorMessage: clearCouponError ? null : (couponErrorMessage ?? this.couponErrorMessage),
      validatingItemIds: validatingItemIds ?? this.validatingItemIds,
      isBackgroundSyncing: isBackgroundSyncing ?? this.isBackgroundSyncing,
    );
  }
}

/// Cart notifier for handling cart operations
class CartNotifier extends StateNotifier<CartState> {
  final GetCartItemsUseCase getCartItemsUseCase;
  final AddToCartUseCase addToCartUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final UpdateCartQuantityUseCase updateCartQuantityUseCase;
  final ClearCartUseCase clearCartUseCase;
  final GetCartTotalPriceUseCase getCartTotalPriceUseCase;
  final GetCartItemCountUseCase getCartItemCountUseCase;
  final IsInCartUseCase isInCartUseCase;

  // Timer for background operations that needs proper cleanup
  Timer? _backgroundTimer;

  CartNotifier({
    required this.getCartItemsUseCase,
    required this.addToCartUseCase,
    required this.removeFromCartUseCase,
    required this.updateCartQuantityUseCase,
    required this.clearCartUseCase,
    required this.getCartTotalPriceUseCase,
    required this.getCartItemCountUseCase,
    required this.isInCartUseCase,
  }) : super(CartState()) {
    // Lazy initialization - only load cart data when first accessed
    debugPrint('🛒 CART NOTIFIER: Initialized with lazy loading strategy');
  }

  /// Lazy initialization - only called when cart data is first accessed
  Future<void> _ensureInitialized() async {
    // Skip if already initialized (has items or has been loaded)
    if (state.items.isNotEmpty || state.isLoading) return;

    debugPrint('🛒 CART LAZY INIT: First access detected, initializing cart data...');
    await getCartItems();
  }











  /// Refreshes all cart data (items, total price, count)
  Future<void> _refreshCartData() async {
    final itemsResult = await getCartItemsUseCase();

    itemsResult.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFailureToMessage(failure),
      ),
      (items) async {
        // Get total price
        final totalPriceResult = await getCartTotalPriceUseCase();
        // Get item count
        final itemCountResult = await getCartItemCountUseCase();

        double totalPrice = 0;
        int itemCount = 0;

        totalPriceResult.fold(
          (failure) => null,
          (price) => totalPrice = price,
        );

        itemCountResult.fold(
          (failure) => null,
          (count) => itemCount = count,
        );

        state = state.copyWith(
          isLoading: false,
          items: items,
          totalPrice: totalPrice,
          itemCount: itemCount,
        );
      },
    );
  }

  /// Get all items in the cart with lazy initialization
  Future<void> getCartItems() async {
    // Prevent multiple simultaneous loads
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    await _refreshCartData();
  }

  /// Add a product to the cart with optimistic updates
  Future<bool> addToCart({required Product product, required int quantity}) async {
    // Ensure cart is initialized before operations
    await _ensureInitialized();

    // Store original state for rollback
    final originalItems = List<CartItem>.from(state.items);
    final originalTotalPrice = state.totalPrice;
    final originalItemCount = state.itemCount;

    // Check if product already exists in cart
    final existingItemIndex = state.items.indexWhere((item) => item.product.id == product.id);

    List<CartItem> updatedItems;

    if (existingItemIndex != -1) {
      // Update existing item quantity
      updatedItems = List<CartItem>.from(state.items);
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item (create temporary cart item for optimistic update)
      updatedItems = List<CartItem>.from(state.items);
      final tempCartItem = CartItem(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
        product: product,
        quantity: quantity,
        addedAt: DateTime.now(),
      );
      updatedItems.add(tempCartItem);
    }

    // Calculate new totals optimistically
    final newTotalPrice = updatedItems.fold<double>(
      0.0,
      (total, item) => total + (item.product.discountedPrice * item.quantity),
    );
    final newItemCount = updatedItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    // Update state immediately (optimistic)
    state = state.copyWith(
      items: updatedItems,
      totalPrice: newTotalPrice,
      itemCount: newItemCount,
      errorMessage: null,
    );

    debugPrint('🛒 ADD TO CART: Updated cart count to $newItemCount (optimistic)');

    // Perform actual add in background
    final result = await addToCartUseCase(
      AddToCartParams(product: product, quantity: quantity),
    );

    late bool success;

    result.fold(
      (failure) {
        // Rollback on failure
        state = state.copyWith(
          items: originalItems,
          totalPrice: originalTotalPrice,
          itemCount: originalItemCount,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (cartItem) {
        // Success - replace temp item with real cart item if it was a new addition
        if (existingItemIndex == -1) {
          final finalItems = List<CartItem>.from(updatedItems);
          final tempItemIndex = finalItems.indexWhere((item) => item.id.startsWith('temp_'));
          if (tempItemIndex != -1) {
            finalItems[tempItemIndex] = cartItem;
            state = state.copyWith(items: finalItems);
          }
        }
        success = true;
      },
    );

    return success;
  }

  /// Remove an item from the cart with optimistic updates
  Future<bool> removeFromCart({required String cartItemId}) async {
    // Store original state for rollback
    final originalItems = List<CartItem>.from(state.items);
    final originalTotalPrice = state.totalPrice;
    final originalItemCount = state.itemCount;

    // Find the item to remove
    final itemIndex = state.items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex == -1) {
      state = state.copyWith(errorMessage: 'Item not found in cart');
      return false;
    }

    // Optimistic update: Remove item immediately
    final updatedItems = List<CartItem>.from(state.items);
    updatedItems.removeAt(itemIndex);

    // Calculate new totals optimistically
    final newTotalPrice = updatedItems.fold<double>(
      0.0,
      (total, item) => total + (item.product.price * item.quantity),
    );
    final newItemCount = updatedItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    // Update state immediately (optimistic)
    state = state.copyWith(
      items: updatedItems,
      totalPrice: newTotalPrice,
      itemCount: newItemCount,
      errorMessage: null,
    );



    // Perform actual removal in background
    final result = await removeFromCartUseCase(
      RemoveFromCartParams(cartItemId: cartItemId),
    );

    late bool success;

    result.fold(
      (failure) {
        // Rollback on failure
        state = state.copyWith(
          items: originalItems,
          totalPrice: originalTotalPrice,
          itemCount: originalItemCount,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (removed) {
        // Success - keep the optimistic update
        success = removed;
      },
    );

    return success;
  }

  /// Update the quantity of an item in the cart with optimistic updates
  Future<bool> updateQuantity({required String cartItemId, required int quantity}) async {
    // Store original state for rollback
    final originalItems = List<CartItem>.from(state.items);
    final originalTotalPrice = state.totalPrice;
    final originalItemCount = state.itemCount;

    // Find the item to update
    final itemIndex = state.items.indexWhere((item) => item.id == cartItemId);
    if (itemIndex == -1) {
      state = state.copyWith(errorMessage: 'Item not found in cart');
      return false;
    }

    final originalItem = state.items[itemIndex];

    // Optimistic update: Update UI immediately
    final updatedItems = List<CartItem>.from(state.items);
    updatedItems[itemIndex] = originalItem.copyWith(quantity: quantity);

    // Calculate new totals optimistically
    final newTotalPrice = updatedItems.fold<double>(
      0.0,
      (total, item) => total + (item.product.discountedPrice * item.quantity),
    );
    final newItemCount = updatedItems.fold<int>(
      0,
      (total, item) => total + item.quantity,
    );

    // Update state immediately (optimistic)
    state = state.copyWith(
      items: updatedItems,
      totalPrice: newTotalPrice,
      itemCount: newItemCount,
      errorMessage: null,
    );



    // Perform actual update in background
    final result = await updateCartQuantityUseCase(
      UpdateCartQuantityParams(cartItemId: cartItemId, quantity: quantity),
    );

    late bool success;

    result.fold(
      (failure) {
        // Rollback on failure
        state = state.copyWith(
          items: originalItems,
          totalPrice: originalTotalPrice,
          itemCount: originalItemCount,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (cartItem) {
        // Success - keep the optimistic update
        success = true;
      },
    );

    return success;
  }

  /// Clear the cart
  Future<bool> clearCart() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await clearCartUseCase();

    late bool success;

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (cleared) {
        state = state.copyWith(
          isLoading: false,
          items: [],
          totalPrice: 0,
          itemCount: 0,
        );

        success = cleared;
      },
    );

    return success;
  }

  /// Check if a product is in the cart
  Future<bool> isInCart({required String productId}) async {
    final result = await isInCartUseCase(
      IsInCartParams(productId: productId),
    );

    return result.fold(
      (failure) => false,
      (isInCart) => isInCart,
    );
  }

  /// Apply coupon to cart
  Future<bool> applyCoupon(String couponCode) async {
    // Clear any previous coupon error
    state = state.copyWith(clearCouponError: true);

    // Calculate current cart total
    final cartTotal = state.items.fold<double>(0, (sum, item) => sum + (item.quantity * item.product.price));

    // Validate coupon
    final validationResult = CouponService.validateCoupon(couponCode, cartTotal);

    if (validationResult.isSuccess && validationResult.appliedCoupon != null) {
      // Apply coupon successfully
      state = state.copyWith(
        appliedCoupon: validationResult.appliedCoupon,
        clearCouponError: true,
      );
      debugPrint('🎫 COUPON: Applied $couponCode successfully');
      return true;
    } else {
      // Show error message
      state = state.copyWith(
        couponErrorMessage: validationResult.errorMessage,
        clearCoupon: true,
      );
      debugPrint('🎫 COUPON: Failed to apply $couponCode - ${validationResult.errorMessage}');
      return false;
    }
  }

  /// Remove applied coupon
  void removeCoupon() {
    state = state.copyWith(
      clearCoupon: true,
      clearCouponError: true,
    );
    debugPrint('🎫 COUPON: Removed applied coupon');
  }

  /// Refresh cart data silently (without loading state)
  Future<void> refreshCart() async {
    // Don't show loading state for refresh - keep current UI responsive

    // Get fresh cart items
    final itemsResult = await getCartItemsUseCase();

    itemsResult.fold(
      (failure) => state = state.copyWith(
        errorMessage: _mapFailureToMessage(failure),
      ),
      (items) async {
        // Get total price
        final totalPriceResult = await getCartTotalPriceUseCase();
        // Get item count
        final itemCountResult = await getCartItemCountUseCase();

        double totalPrice = 0;
        int itemCount = 0;

        totalPriceResult.fold(
          (failure) => null,
          (price) => totalPrice = price,
        );

        itemCountResult.fold(
          (failure) => null,
          (count) => itemCount = count,
        );

        state = state.copyWith(
          items: items,
          totalPrice: totalPrice,
          itemCount: itemCount,
          errorMessage: null, // Clear any previous errors on successful refresh
        );
      },
    );
  }

  /// Start validating specific cart items (for skeleton loading)
  void startItemValidation(List<String> itemIds) {
    final updatedValidatingIds = Set<String>.from(state.validatingItemIds)
      ..addAll(itemIds);

    state = state.copyWith(validatingItemIds: updatedValidatingIds);
    debugPrint('🔄 CART VALIDATION: Started validating items: $itemIds');
  }

  /// Stop validating specific cart items
  void stopItemValidation(List<String> itemIds) {
    final updatedValidatingIds = Set<String>.from(state.validatingItemIds)
      ..removeAll(itemIds);

    state = state.copyWith(validatingItemIds: updatedValidatingIds);
    debugPrint('🔄 CART VALIDATION: Stopped validating items: $itemIds');
  }

  /// Set background sync status
  void setBackgroundSyncStatus(bool isActive) {
    state = state.copyWith(isBackgroundSyncing: isActive);
    debugPrint('🔄 CART SYNC: Background sync status: $isActive');
  }

  /// Silent background validation for hybrid cart strategy (called by repository)
  Future<void> validateCartItems() async {
    if (state.items.isEmpty) return;

    debugPrint('🔄 CART VALIDATION: Repository-triggered silent validation...');

    try {
      // This is now handled by the repository's intelligent sync
      // Just refresh local state without triggering additional syncs
      final result = await getCartItemsUseCase();

      result.fold(
        (failure) {
          debugPrint('🔄 CART VALIDATION: ❌ Silent validation failed: ${failure.message}');
        },
        (items) {
          // Update state silently without triggering UI loading states
          final totalPrice = items.fold<double>(0.0, (total, item) => total + item.totalPrice);
          final itemCount = items.fold<int>(0, (total, item) => total + item.quantity);

          state = state.copyWith(
            items: items,
            totalPrice: totalPrice,
            itemCount: itemCount,
          );

          debugPrint('🔄 CART VALIDATION: ✅ Silent validation completed (${items.length} items)');
        },
      );
    } catch (e) {
      debugPrint('🔄 CART VALIDATION: ❌ Silent validation failed: $e');
      // Silent failure - no user notification needed for background validation
    }
  }

  /// Start background operations (like periodic sync)
  void startBackgroundOperations() {
    // Cancel any existing timer
    _backgroundTimer?.cancel();

    // Start a periodic timer for background operations (every 5 minutes)
    _backgroundTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      debugPrint('🔄 BACKGROUND: Periodic cart validation triggered');
      validateCartItems();
    });

    debugPrint('🔄 BACKGROUND: Background operations started');
  }

  /// Stop background operations
  void stopBackgroundOperations() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    debugPrint('🔄 BACKGROUND: Background operations stopped');
  }

  /// Sync local cart with database (lazy sync strategy)
  /// This is called when user navigates to cart screen or initiates checkout
  Future<void> syncCartWithDatabase() async {
    // Prevent multiple simultaneous syncs
    if (state.isBackgroundSyncing) {
      debugPrint('🔄 LAZY SYNC: Sync already in progress, skipping...');
      return;
    }

    debugPrint('🔄 LAZY SYNC: Starting cart sync from UI...');

    // Set background sync status
    state = state.copyWith(isBackgroundSyncing: true);

    try {
      // Call the repository sync method directly
      final cartRepository = sl<CartRepository>();
      final result = await cartRepository.syncCartWithDatabase();

      result.fold(
        (failure) {
          debugPrint('🔄 LAZY SYNC: ❌ Sync failed: ${failure.message}');
          // Don't show error to user - this is background operation
        },
        (success) {
          if (success) {
            debugPrint('🔄 LAZY SYNC: ✅ Sync completed successfully');
            // Refresh cart items to get updated data from database
            getCartItems();
          } else {
            debugPrint('🔄 LAZY SYNC: ⚠️ Sync skipped (offline or disabled)');
          }
        },
      );
    } catch (e) {
      debugPrint('🔄 LAZY SYNC: ❌ Unexpected error: $e');
    } finally {
      // Clear background sync status
      state = state.copyWith(isBackgroundSyncing: false);
    }
  }

  /// Dispose method to clean up resources and prevent memory leaks
  @override
  void dispose() {
    debugPrint('🧹 CART CLEANUP: Disposing CartNotifier resources...');

    // Cancel any background timers to prevent memory leaks
    _backgroundTimer?.cancel();
    _backgroundTimer = null;

    // Clear any pending operations
    state = state.copyWith(
      isLoading: false,
      isBackgroundSyncing: false,
      validatingItemIds: <String>{},
    );

    debugPrint('🧹 CART CLEANUP: CartNotifier disposed successfully');
    super.dispose();
  }
}

/// Helper to map failures to user-friendly messages
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return 'Server error occurred. Please try again later.';
    case NetworkFailure:
      return 'Network error. Please check your internet connection.';
    case CacheFailure:
      return 'Error retrieving local data. Please restart the app.';
    default:
      return failure.message;
  }
}

/// Cart providers

/// Main cart state provider
final cartNotifierProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  // Check if cart dependencies are registered
  if (!_cartDependenciesRegistered) {
    debugPrint('WARNING: Cart dependencies not registered properly. Cart functionality may not work.');
  }

  try {
    return CartNotifier(
      getCartItemsUseCase: sl<GetCartItemsUseCase>(),
      addToCartUseCase: sl<AddToCartUseCase>(),
      removeFromCartUseCase: sl<RemoveFromCartUseCase>(),
      updateCartQuantityUseCase: sl<UpdateCartQuantityUseCase>(),
      clearCartUseCase: sl<ClearCartUseCase>(),
      getCartTotalPriceUseCase: sl<GetCartTotalPriceUseCase>(),
      getCartItemCountUseCase: sl<GetCartItemCountUseCase>(),
      isInCartUseCase: sl<IsInCartUseCase>(),
    );
  } catch (e) {
    debugPrint('Error creating CartNotifier: $e');
    // Return a dummy CartNotifier with empty state to prevent app crashes
    throw StateError('Failed to initialize cart: $e');
  }
});

/// Convenience providers for specific cart states

/// Cart items provider
final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartNotifierProvider).items;
});

/// Cart loading state provider
final cartLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cartNotifierProvider).isLoading;
});

/// Cart error message provider
final cartErrorProvider = Provider<String?>((ref) {
  return ref.watch(cartNotifierProvider).errorMessage;
});

/// Cart total price provider
final cartTotalPriceProvider = Provider<double>((ref) {
  return ref.watch(cartNotifierProvider).totalPrice;
});

/// Cart background sync status provider
final cartBackgroundSyncProvider = Provider<bool>((ref) {
  return ref.watch(cartNotifierProvider).isBackgroundSyncing;
});

/// Cart item validation status provider
final cartValidatingItemsProvider = Provider<Set<String>>((ref) {
  return ref.watch(cartNotifierProvider).validatingItemIds;
});

/// Check if specific item is being validated
final isItemValidatingProvider = Provider.family<bool, String>((ref, itemId) {
  return ref.watch(cartNotifierProvider).isItemValidating(itemId);
});







/// Cart item existence checker provider
final isProductInCartProvider = FutureProvider.autoDispose.family<bool, String>((ref, productId) async {
  // First check the current cart items directly (faster)
  final cartItems = ref.watch(cartItemsProvider);
  for (var item in cartItems) {
    if (item.product.id == productId) {
      return true;
    }
  }

  // If not found in current items, check with the repository
  final isInCart = await ref.read(cartNotifierProvider.notifier).isInCart(productId: productId);
  return isInCart;
});