import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/product.dart';
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

/// Cart state class to manage cart-related state
class CartState {
  final bool isLoading;
  final String? errorMessage;
  final List<CartItem> items;
  final double totalPrice;
  final int itemCount;

  /// Total quantity of items (sum of all quantities)
  int get totalQuantity => items.fold(0, (total, item) => total + item.quantity);

  CartState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.totalPrice = 0.0,
    this.itemCount = 0,
  });

  CartState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CartItem>? items,
    double? totalPrice,
    int? itemCount,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      items: items ?? this.items,
      totalPrice: totalPrice ?? this.totalPrice,
      itemCount: itemCount ?? this.itemCount,
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
    // Initialize cart data
    _loadCartData();
  }

  /// Internal method to load initial cart data
  Future<void> _loadCartData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    await _refreshCartData();
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

  /// Get all items in the cart
  Future<void> getCartItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _refreshCartData();
  }

  /// Add a product to the cart
  Future<bool> addToCart({required Product product, required int quantity}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await addToCartUseCase(
      AddToCartParams(product: product, quantity: quantity),
    );
    
    late bool success;
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (cartItem) {
        _refreshCartData();
        success = true;
      },
    );
    
    return success;
  }

  /// Remove an item from the cart
  Future<bool> removeFromCart({required String cartItemId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await removeFromCartUseCase(
      RemoveFromCartParams(cartItemId: cartItemId),
    );
    
    late bool success;
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (removed) {
        _refreshCartData();
        success = removed;
      },
    );
    
    return success;
  }

  /// Update the quantity of an item in the cart
  Future<bool> updateQuantity({required String cartItemId, required int quantity}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await updateCartQuantityUseCase(
      UpdateCartQuantityParams(cartItemId: cartItemId, quantity: quantity),
    );
    
    late bool success;
    
    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: _mapFailureToMessage(failure),
        );
        success = false;
      },
      (cartItem) {
        _refreshCartData();
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

  /// Refresh cart data
  Future<void> refreshCart() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _refreshCartData();
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

/// Cart item count provider
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartNotifierProvider).itemCount;
});

/// Cart item existence checker provider
final isProductInCartProvider = FutureProvider.family<bool, String>((ref, productId) async {
  return await ref.read(cartNotifierProvider.notifier).isInCart(productId: productId);
});