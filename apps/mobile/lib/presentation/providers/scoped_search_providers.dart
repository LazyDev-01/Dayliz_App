import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../core/services/search_service.dart';
import '../../domain/entities/product.dart';
import '../../core/errors/failures.dart';
import 'enhanced_search_providers.dart'; // For searchServiceProvider

/// Scoped search parameters for provider family
class ScopedSearchParams {
  final String query;
  final String? subcategoryId;
  final String? categoryId;
  final String? subcategoryName; // For UI display

  const ScopedSearchParams({
    required this.query,
    this.subcategoryId,
    this.categoryId,
    this.subcategoryName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScopedSearchParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          subcategoryId == other.subcategoryId &&
          categoryId == other.categoryId;

  @override
  int get hashCode =>
      query.hashCode ^
      subcategoryId.hashCode ^
      categoryId.hashCode;

  @override
  String toString() => 'ScopedSearchParams(query: $query, subcategoryId: $subcategoryId, categoryId: $categoryId)';
}

/// Scoped search state for lazy loading within specific scope
class ScopedSearchState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final ScopedSearchParams params;

  const ScopedSearchState({
    required this.products,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.error,
    required this.currentPage,
    required this.params,
  });

  factory ScopedSearchState.initial(ScopedSearchParams params) {
    return ScopedSearchState(
      products: [],
      isLoading: false,
      isLoadingMore: false,
      hasMore: true,
      error: null,
      currentPage: 0,
      params: params,
    );
  }

  ScopedSearchState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    ScopedSearchParams? params,
  }) {
    return ScopedSearchState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      params: params ?? this.params,
    );
  }

  bool get isEmpty => products.isEmpty && !isLoading;
  bool get hasProducts => products.isNotEmpty;
  bool get hasError => error != null;
  String get scopeDisplayName => params.subcategoryName ?? 'Category';
}

/// Scoped search notifier for managing lazy loading within scope
class ScopedSearchNotifier extends StateNotifier<ScopedSearchState> {
  final SearchService _searchService;
  static const int _itemsPerPage = 20;

  ScopedSearchNotifier(this._searchService, ScopedSearchParams params) 
      : super(ScopedSearchState.initial(params));

  /// Search with fresh query within scope (reset pagination)
  Future<void> search(ScopedSearchParams params) async {
    if (params.query.trim().isEmpty) {
      state = ScopedSearchState.initial(params);
      return;
    }

    // Don't search if it's the same query and scope and we already have results
    if (state.params == params && state.hasProducts && !state.hasError) {
      return;
    }

    // Reset state for new search
    state = state.copyWith(
      params: params,
      products: [],
      currentPage: 0,
      isLoading: true,
      isLoadingMore: false,
      hasMore: true,
      error: null,
    );

    await _loadPage(1);
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.params.query.trim().isEmpty) {
      debugPrint('🔍 ScopedSearch: LoadMore blocked - isLoadingMore: ${state.isLoadingMore}, hasMore: ${state.hasMore}, query: "${state.params.query}"');
      return;
    }

    debugPrint('🔍 ScopedSearch: Loading more scoped products - current page: ${state.currentPage}, total products: ${state.products.length}');
    state = state.copyWith(isLoadingMore: true, error: null);
    await _loadPage(state.currentPage + 1);
  }

  /// Load specific page
  Future<void> _loadPage(int page) async {
    try {
      final result = await _searchService.searchProductsScoped(
        query: state.params.query,
        subcategoryId: state.params.subcategoryId,
        categoryId: state.params.categoryId,
        page: page,
        limit: _itemsPerPage,
        useCache: true,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            isLoadingMore: false,
            error: failure.message,
          );
        },
        (newProducts) {
          final allProducts = page == 1 
              ? newProducts 
              : [...state.products, ...newProducts];

          // More robust "hasMore" logic
          final hasMore = newProducts.length == _itemsPerPage;
          
          // Additional check: if we got fewer products than requested, no more pages
          final actuallyHasMore = hasMore && newProducts.isNotEmpty;

          state = state.copyWith(
            products: allProducts,
            currentPage: page,
            isLoading: false,
            isLoadingMore: false,
            hasMore: actuallyHasMore,
            error: null,
          );
          
          debugPrint('🔍 ScopedSearch: Page $page loaded ${newProducts.length} products. Total: ${allProducts.length}. HasMore: $actuallyHasMore');
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Retry loading current page
  Future<void> retry() async {
    if (state.products.isEmpty) {
      await search(state.params);
    } else {
      await loadMore();
    }
  }

  /// Clear search results
  void clear() {
    state = ScopedSearchState.initial(state.params);
  }

  /// Reset search state completely
  void reset() {
    state = ScopedSearchState.initial(ScopedSearchParams(query: ''));
  }
}

/// Scoped search provider
final scopedSearchProvider = StateNotifierProvider.family<
    ScopedSearchNotifier, 
    ScopedSearchState, 
    ScopedSearchParams
>((ref, params) {
  final searchService = ref.read(searchServiceProvider);
  return ScopedSearchNotifier(searchService, params);
});

/// Current scoped search parameters provider
final currentScopedSearchParamsProvider = StateProvider<ScopedSearchParams?>((ref) => null);

/// Active scoped search provider (follows current params)
final activeScopedSearchProvider = Provider<ScopedSearchState?>((ref) {
  final currentParams = ref.watch(currentScopedSearchParamsProvider);
  if (currentParams == null) {
    return null;
  }
  return ref.watch(scopedSearchProvider(currentParams));
});

/// Scoped search actions for managing scoped search
final scopedSearchActionsProvider = Provider<ScopedSearchActions>((ref) {
  return ScopedSearchActions(ref);
});

class ScopedSearchActions {
  final Ref _ref;

  ScopedSearchActions(this._ref);

  /// Perform new scoped search
  Future<void> search(ScopedSearchParams params) async {
    _ref.read(currentScopedSearchParamsProvider.notifier).state = params;
    await _ref.read(scopedSearchProvider(params).notifier).search(params);
  }

  /// Load more results
  Future<void> loadMore() async {
    final currentParams = _ref.read(currentScopedSearchParamsProvider);
    if (currentParams != null) {
      await _ref.read(scopedSearchProvider(currentParams).notifier).loadMore();
    }
  }

  /// Retry failed request
  Future<void> retry() async {
    final currentParams = _ref.read(currentScopedSearchParamsProvider);
    if (currentParams != null) {
      await _ref.read(scopedSearchProvider(currentParams).notifier).retry();
    }
  }

  /// Clear search
  void clear() {
    _ref.read(currentScopedSearchParamsProvider.notifier).state = null;
  }

  /// Reset search completely
  void reset() {
    final currentParams = _ref.read(currentScopedSearchParamsProvider);
    _ref.read(currentScopedSearchParamsProvider.notifier).state = null;
    if (currentParams != null) {
      _ref.read(scopedSearchProvider(currentParams).notifier).reset();
    }
  }
}
