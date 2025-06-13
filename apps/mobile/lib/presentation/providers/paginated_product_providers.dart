import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../di/dependency_injection.dart';
import '../../core/models/pagination_models.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_products_paginated_usecase.dart';

/// State class for paginated products
@immutable
class PaginatedProductsState {
  final IList<Product> products;
  final PaginationMeta? meta;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasReachedEnd;

  const PaginatedProductsState({
    required this.products,
    this.meta,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasReachedEnd = false,
  });

  const PaginatedProductsState.initial()
      : products = const IListConst([]),
        meta = null,
        isLoading = false,
        isLoadingMore = false,
        errorMessage = null,
        hasReachedEnd = false;

  PaginatedProductsState copyWith({
    IList<Product>? products,
    PaginationMeta? meta,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasReachedEnd,
    bool clearError = false,
  }) {
    return PaginatedProductsState(
      products: products ?? this.products,
      meta: meta ?? this.meta,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
    );
  }

  bool get isEmpty => products.isEmpty && !isLoading;
  bool get isNotEmpty => products.isNotEmpty;
  int get length => products.length;
  bool get canLoadMore => meta?.hasNextPage == true && !isLoadingMore && !hasReachedEnd;

  @override
  String toString() => 'PaginatedProductsState(products: ${products.length}, isLoading: $isLoading, hasReachedEnd: $hasReachedEnd)';
}

/// Notifier for paginated products
class PaginatedProductsNotifier extends StateNotifier<PaginatedProductsState> {
  final GetProductsPaginatedUseCase _getProductsPaginatedUseCase;
  GetProductsPaginatedParams? _currentParams;

  PaginatedProductsNotifier(this._getProductsPaginatedUseCase) : super(const PaginatedProductsState.initial());

  /// Load first page of products
  Future<void> loadProducts(GetProductsPaginatedParams params) async {
    if (state.isLoading) return;

    _currentParams = params;
    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _getProductsPaginatedUseCase.call(params);

    result.fold(
      (failure) {
        debugPrint('❌ Failed to load products: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (paginatedResponse) {
        debugPrint('✅ Loaded ${paginatedResponse.data.length} products (page ${paginatedResponse.meta.currentPage})');
        state = state.copyWith(
          products: paginatedResponse.data.toIList(),
          meta: paginatedResponse.meta,
          isLoading: false,
          hasReachedEnd: !paginatedResponse.meta.hasNextPage,
          clearError: true,
        );
      },
    );
  }

  /// Load next page of products (infinite scroll)
  Future<void> loadMoreProducts() async {
    if (!state.canLoadMore || _currentParams == null) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);

    final nextPageParams = _currentParams!.nextPage();
    final result = await _getProductsPaginatedUseCase.call(nextPageParams);

    result.fold(
      (failure) {
        debugPrint('❌ Failed to load more products: ${failure.message}');
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: failure.message,
        );
      },
      (paginatedResponse) {
        debugPrint('✅ Loaded ${paginatedResponse.data.length} more products (page ${paginatedResponse.meta.currentPage})');
        
        // Append new products to existing list
        final updatedProducts = state.products.addAll(paginatedResponse.data);
        
        state = state.copyWith(
          products: updatedProducts,
          meta: paginatedResponse.meta,
          isLoadingMore: false,
          hasReachedEnd: !paginatedResponse.meta.hasNextPage,
          clearError: true,
        );
        
        // Update current params for next load
        _currentParams = nextPageParams;
      },
    );
  }

  /// Refresh products (pull to refresh)
  Future<void> refreshProducts() async {
    if (_currentParams == null) return;

    // Reset to first page
    final firstPageParams = GetProductsPaginatedParams(
      pagination: PaginationParams(page: 1, limit: _currentParams!.pagination?.limit ?? 50),
      categoryId: _currentParams!.categoryId,
      subcategoryId: _currentParams!.subcategoryId,
      searchQuery: _currentParams!.searchQuery,
      sortBy: _currentParams!.sortBy,
      ascending: _currentParams!.ascending,
      minPrice: _currentParams!.minPrice,
      maxPrice: _currentParams!.maxPrice,
    );

    await loadProducts(firstPageParams);
  }

  /// Clear all products and reset state
  void clearProducts() {
    state = const PaginatedProductsState.initial();
    _currentParams = null;
  }

  /// Update sort order and reload
  Future<void> updateSort({String? sortBy, bool? ascending}) async {
    if (_currentParams == null) return;

    final updatedParams = GetProductsPaginatedParams(
      pagination: PaginationParams(page: 1, limit: _currentParams!.pagination?.limit ?? 50),
      categoryId: _currentParams!.categoryId,
      subcategoryId: _currentParams!.subcategoryId,
      searchQuery: _currentParams!.searchQuery,
      sortBy: sortBy ?? _currentParams!.sortBy,
      ascending: ascending ?? _currentParams!.ascending,
      minPrice: _currentParams!.minPrice,
      maxPrice: _currentParams!.maxPrice,
    );

    await loadProducts(updatedParams);
  }
}

/// Provider for paginated products by subcategory
final paginatedProductsBySubcategoryProvider = 
    StateNotifierProvider.family<PaginatedProductsNotifier, PaginatedProductsState, String>(
  (ref, subcategoryId) {
    final useCase = sl<GetProductsPaginatedUseCase>();
    final notifier = PaginatedProductsNotifier(useCase);
    
    // Auto-load products for this subcategory
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadProducts(
        GetProductsPaginatedParams.forSubcategory(subcategoryId: subcategoryId),
      );
    });
    
    return notifier;
  },
);

/// Provider for paginated products by category
final paginatedProductsByCategoryProvider = 
    StateNotifierProvider.family<PaginatedProductsNotifier, PaginatedProductsState, String>(
  (ref, categoryId) {
    final useCase = sl<GetProductsPaginatedUseCase>();
    final notifier = PaginatedProductsNotifier(useCase);
    
    // Auto-load products for this category
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadProducts(
        GetProductsPaginatedParams.forCategory(categoryId: categoryId),
      );
    });
    
    return notifier;
  },
);

/// Provider for paginated search results
final paginatedSearchProductsProvider = 
    StateNotifierProvider.family<PaginatedProductsNotifier, PaginatedProductsState, String>(
  (ref, searchQuery) {
    final useCase = sl<GetProductsPaginatedUseCase>();
    final notifier = PaginatedProductsNotifier(useCase);
    
    // Auto-load search results
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadProducts(
        GetProductsPaginatedParams.forSearch(searchQuery: searchQuery),
      );
    });
    
    return notifier;
  },
);

/// Provider for all products with pagination
final paginatedAllProductsProvider = 
    StateNotifierProvider<PaginatedProductsNotifier, PaginatedProductsState>(
  (ref) {
    final useCase = sl<GetProductsPaginatedUseCase>();
    final notifier = PaginatedProductsNotifier(useCase);
    
    // Auto-load all products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifier.loadProducts(GetProductsPaginatedParams.all());
    });
    
    return notifier;
  },
);
