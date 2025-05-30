import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/usecases/get_wishlist_items_usecase.dart';
import '../../domain/usecases/add_to_wishlist_usecase.dart';
import '../../domain/usecases/remove_from_wishlist_usecase.dart';
import '../../domain/usecases/is_in_wishlist_usecase.dart';
import '../../domain/usecases/clear_wishlist_usecase.dart';
import '../../domain/usecases/get_wishlist_products_usecase.dart';
import '../../di/dependency_injection.dart';

/// Wishlist state class
class WishlistState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;

  const WishlistState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Create a copy of the state with updated fields
  WishlistState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WishlistState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Wishlist notifier that manages wishlist state
class WishlistNotifier extends StateNotifier<WishlistState> {
  final GetWishlistProductsUseCase getWishlistProductsUseCase;
  final AddToWishlistUseCase addToWishlistUseCase;
  final RemoveFromWishlistUseCase removeFromWishlistUseCase;
  final IsInWishlistUseCase isInWishlistUseCase;
  final ClearWishlistUseCase clearWishlistUseCase;

  WishlistNotifier({
    required this.getWishlistProductsUseCase,
    required this.addToWishlistUseCase,
    required this.removeFromWishlistUseCase,
    required this.isInWishlistUseCase,
    required this.clearWishlistUseCase,
  }) : super(const WishlistState());

  /// Load wishlist products
  Future<void> loadWishlistProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await getWishlistProductsUseCase(NoParams());
    
    state = result.fold(
      (failure) => state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (products) => state.copyWith(
        products: products,
        isLoading: false,
      ),
    );
  }

  /// Add a product to the wishlist
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await addToWishlistUseCase(
      AddToWishlistParams(productId: productId),
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => loadWishlistProducts(),
    );
    
    return result;
  }

  /// Remove a product from the wishlist
  Future<Either<Failure, bool>> removeFromWishlist(String productId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await removeFromWishlistUseCase(
      RemoveFromWishlistParams(productId: productId),
    );
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => loadWishlistProducts(),
    );
    
    return result;
  }

  /// Check if a product is in the wishlist
  Future<bool> isInWishlist(String productId) async {
    final result = await isInWishlistUseCase(
      IsInWishlistParams(productId: productId),
    );
    
    return result.fold(
      (failure) => false,
      (isInWishlist) => isInWishlist,
    );
  }

  /// Clear the wishlist
  Future<Either<Failure, bool>> clearWishlist() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await clearWishlistUseCase(NoParams());
    
    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        products: const [],
        isLoading: false,
      ),
    );
    
    return result;
  }

  /// Toggle a product in the wishlist (add if not present, remove if present)
  Future<void> toggleWishlist(String productId) async {
    final isInWishlistResult = await isInWishlist(productId);
    
    if (isInWishlistResult) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }
}

/// Provider for wishlist notifier
final wishlistNotifierProvider = StateNotifierProvider<WishlistNotifier, WishlistState>((ref) {
  return WishlistNotifier(
    getWishlistProductsUseCase: sl<GetWishlistProductsUseCase>(),
    addToWishlistUseCase: sl<AddToWishlistUseCase>(),
    removeFromWishlistUseCase: sl<RemoveFromWishlistUseCase>(),
    isInWishlistUseCase: sl<IsInWishlistUseCase>(),
    clearWishlistUseCase: sl<ClearWishlistUseCase>(),
  );
});

/// Provider for wishlist loading state
final wishlistLoadingProvider = Provider<bool>((ref) {
  return ref.watch(wishlistNotifierProvider).isLoading;
});

/// Provider for wishlist error message
final wishlistErrorProvider = Provider<String?>((ref) {
  return ref.watch(wishlistNotifierProvider).errorMessage;
});

/// Provider for wishlist products
final wishlistProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(wishlistNotifierProvider).products;
});

/// Provider to check if a product is in the wishlist
final isProductInWishlistProvider = FutureProvider.family<bool, String>((ref, productId) async {
  return await ref.read(wishlistNotifierProvider.notifier).isInWishlist(productId);
}); 