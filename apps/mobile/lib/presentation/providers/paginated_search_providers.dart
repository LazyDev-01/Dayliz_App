import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../core/services/search_service.dart';
import '../../domain/entities/product.dart';
import '../../core/errors/failures.dart';
import 'enhanced_search_providers.dart'; // For searchServiceProvider

/// Paginated search state for lazy loading
class PaginatedSearchState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final String query;

  const PaginatedSearchState({
    required this.products,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    this.error,
    required this.currentPage,
    required this.query,
  });

  factory PaginatedSearchState.initial(String query) {
    return PaginatedSearchState(
      products: [],
      isLoading: false,
      isLoadingMore: false,
      hasMore: true,
      error: null,
      currentPage: 0,
      query: query,
    );
  }

  PaginatedSearchState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
    String? query,
  }) {
    return PaginatedSearchState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      query: query ?? this.query,
    );
  }

  bool get isEmpty => products.isEmpty && !isLoading;
  bool get hasProducts => products.isNotEmpty;
  bool get hasError => error != null;
}

/// Paginated search notifier for managing lazy loading
class PaginatedSearchNotifier extends StateNotifier<PaginatedSearchState> {
  final SearchService _searchService;
  static const int _itemsPerPage = 15; // Reduced for true lazy loading

  PaginatedSearchNotifier(this._searchService, String query) 
      : super(PaginatedSearchState.initial(query));

  /// Search with fresh query (reset pagination)
  Future<void> search(String query) async {
    final normalizedQuery = query.trim();

    if (normalizedQuery.isEmpty) {
      state = PaginatedSearchState.initial(normalizedQuery);
      return;
    }

    // Don't search if it's the same query and we already have results
    if (state.query == normalizedQuery && state.hasProducts && !state.hasError) {
      return;
    }

    // Reset state for new search
    state = state.copyWith(
      query: normalizedQuery,
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
    if (state.isLoadingMore || !state.hasMore || state.query.trim().isEmpty) {
      debugPrint('🔍 PaginatedSearch: LoadMore blocked - isLoadingMore: ${state.isLoadingMore}, hasMore: ${state.hasMore}, query: "${state.query}"');
      return;
    }

    debugPrint('🔍 PaginatedSearch: Loading more products - current page: ${state.currentPage}, total products: ${state.products.length}');
    state = state.copyWith(isLoadingMore: true, error: null);
    await _loadPage(state.currentPage + 1);
  }

  /// Load specific page
  Future<void> _loadPage(int page) async {
    try {
      final result = await _searchService.searchProductsPaginated(
        query: state.query,
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

          // Add to search history if first page and has results
          if (page == 1 && newProducts.isNotEmpty) {
            _searchService.addToHistory(state.query);
          }

          debugPrint('🔍 PaginatedSearch: Page $page loaded ${newProducts.length} products. Total: ${allProducts.length}. HasMore: $actuallyHasMore');
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
      await search(state.query);
    } else {
      await loadMore();
    }
  }

  /// Clear search results
  void clear() {
    state = PaginatedSearchState.initial('');
  }

  /// Reset search state completely
  void reset() {
    state = PaginatedSearchState.initial('');
  }
}

/// Paginated search provider
final paginatedSearchProvider = StateNotifierProvider.family<
    PaginatedSearchNotifier, 
    PaginatedSearchState, 
    String
>((ref, query) {
  final searchService = ref.read(searchServiceProvider);
  return PaginatedSearchNotifier(searchService, query);
});

/// Current search query provider for pagination
final currentSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active paginated search provider (follows current query)
final activePaginatedSearchProvider = Provider<PaginatedSearchState>((ref) {
  final currentQuery = ref.watch(currentSearchQueryProvider);
  if (currentQuery.isEmpty) {
    return PaginatedSearchState.initial('');
  }
  return ref.watch(paginatedSearchProvider(currentQuery));
});

/// Search actions for paginated search
final paginatedSearchActionsProvider = Provider<PaginatedSearchActions>((ref) {
  return PaginatedSearchActions(ref);
});

class PaginatedSearchActions {
  final Ref _ref;

  PaginatedSearchActions(this._ref);

  /// Perform new search
  Future<void> search(String query) async {
    _ref.read(currentSearchQueryProvider.notifier).state = query;
    if (query.isNotEmpty) {
      await _ref.read(paginatedSearchProvider(query).notifier).search(query);
    }
  }

  /// Load more results
  Future<void> loadMore() async {
    final currentQuery = _ref.read(currentSearchQueryProvider);
    if (currentQuery.isNotEmpty) {
      await _ref.read(paginatedSearchProvider(currentQuery).notifier).loadMore();
    }
  }

  /// Retry failed request
  Future<void> retry() async {
    final currentQuery = _ref.read(currentSearchQueryProvider);
    if (currentQuery.isNotEmpty) {
      await _ref.read(paginatedSearchProvider(currentQuery).notifier).retry();
    }
  }

  /// Clear search
  void clear() {
    _ref.read(currentSearchQueryProvider.notifier).state = '';
  }

  /// Reset search completely
  void reset() {
    final currentQuery = _ref.read(currentSearchQueryProvider);
    _ref.read(currentSearchQueryProvider.notifier).state = '';
    if (currentQuery.isNotEmpty) {
      _ref.read(paginatedSearchProvider(currentQuery).notifier).reset();
    }
  }
}
