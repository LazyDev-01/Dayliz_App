import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/product.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_featured_products_usecase.dart';
import '../../domain/usecases/get_sale_products_usecase.dart';
import '../../core/errors/failures.dart';
import '../../di/dependency_injection.dart' as di;
import 'category_providers.dart';

/// State class for featured products
class FeaturedProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final bool hasLoaded; // Track if loading has been attempted

  const FeaturedProductsState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasLoaded = false,
  });

  FeaturedProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
    bool? hasLoaded,
  }) {
    return FeaturedProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// State class for sale products
class SaleProductsState {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final bool hasLoaded; // Track if loading has been attempted

  const SaleProductsState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasLoaded = false,
  });

  SaleProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? errorMessage,
    bool? hasLoaded,
  }) {
    return SaleProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

/// Featured products notifier
class FeaturedProductsNotifier extends StateNotifier<FeaturedProductsState> {
  final GetFeaturedProductsUseCase getFeaturedProductsUseCase;

  FeaturedProductsNotifier({
    required this.getFeaturedProductsUseCase,
  }) : super(const FeaturedProductsState());

  Future<void> loadFeaturedProducts({int? limit = 10}) async {
    try {
      debugPrint('🏠 FEATURED: Starting to load featured products with limit: $limit');
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await getFeaturedProductsUseCase(
        GetFeaturedProductsParams(limit: limit),
      );

      result.fold(
        (failure) {
          debugPrint('🏠 FEATURED: Failed to load featured products: $failure');
          state = state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
            hasLoaded: true,
          );
        },
        (products) {
          debugPrint('🏠 FEATURED: Successfully loaded ${products.length} featured products');
          state = state.copyWith(
            isLoading: false,
            products: products,
            hasLoaded: true,
          );
        },
      );
    } catch (e) {
      debugPrint('🏠 FEATURED: Exception while loading featured products: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
        hasLoaded: true,
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error';
    }
  }
}

/// Sale products notifier
class SaleProductsNotifier extends StateNotifier<SaleProductsState> {
  final GetSaleProductsUseCase getSaleProductsUseCase;

  SaleProductsNotifier({
    required this.getSaleProductsUseCase,
  }) : super(const SaleProductsState());

  Future<void> loadSaleProducts({int? limit = 10}) async {
    try {
      debugPrint('🏠 SALE: Starting to load sale products with limit: $limit');
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await getSaleProductsUseCase(
        GetSaleProductsParams(limit: limit),
      );

      result.fold(
        (failure) {
          debugPrint('🏠 SALE: Failed to load sale products: $failure');
          state = state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
            hasLoaded: true,
          );
        },
        (products) {
          debugPrint('🏠 SALE: Successfully loaded ${products.length} sale products');
          state = state.copyWith(
            isLoading: false,
            products: products,
            hasLoaded: true,
          );
        },
      );
    } catch (e) {
      debugPrint('🏠 SALE: Exception while loading sale products: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error: ${e.toString()}',
        hasLoaded: true,
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'Unexpected error';
    }
  }
}

/// Featured products provider
final featuredProductsNotifierProvider =
    StateNotifierProvider<FeaturedProductsNotifier, FeaturedProductsState>((ref) {
  try {
    debugPrint('🏠 PROVIDER: Creating FeaturedProductsNotifier...');
    final useCase = di.sl<GetFeaturedProductsUseCase>();
    debugPrint('🏠 PROVIDER: GetFeaturedProductsUseCase retrieved successfully');
    return FeaturedProductsNotifier(
      getFeaturedProductsUseCase: useCase,
    );
  } catch (e) {
    debugPrint('🏠 PROVIDER: Error creating FeaturedProductsNotifier: $e');
    rethrow;
  }
});

/// Sale products provider
final saleProductsNotifierProvider =
    StateNotifierProvider<SaleProductsNotifier, SaleProductsState>((ref) {
  try {
    debugPrint('🏠 PROVIDER: Creating SaleProductsNotifier...');
    final useCase = di.sl<GetSaleProductsUseCase>();
    debugPrint('🏠 PROVIDER: GetSaleProductsUseCase retrieved successfully');
    return SaleProductsNotifier(
      getSaleProductsUseCase: useCase,
    );
  } catch (e) {
    debugPrint('🏠 PROVIDER: Error creating SaleProductsNotifier: $e');
    rethrow;
  }
});

/// Convenience providers for accessing data
final featuredProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(featuredProductsNotifierProvider).products;
});

final featuredProductsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(featuredProductsNotifierProvider).isLoading;
});

final featuredProductsErrorProvider = Provider<String?>((ref) {
  return ref.watch(featuredProductsNotifierProvider).errorMessage;
});

final saleProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(saleProductsNotifierProvider).products;
});

final saleProductsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(saleProductsNotifierProvider).isLoading;
});

final saleProductsErrorProvider = Provider<String?>((ref) {
  return ref.watch(saleProductsNotifierProvider).errorMessage;
});

/// Home screen categories provider (limited for home screen display)
final homeScreenCategoriesProvider = Provider<List<Category>>((ref) {
  final allCategories = ref.watch(categoriesProvider);
  return allCategories.when(
    data: (categories) => categories.take(4).toList(), // Show only first 4 categories on home screen
    loading: () => [],
    error: (_, __) => [],
  );
});

final homeScreenCategoriesLoadingProvider = Provider<bool>((ref) {
  final categoriesAsync = ref.watch(categoriesProvider);
  return categoriesAsync.isLoading;
});
