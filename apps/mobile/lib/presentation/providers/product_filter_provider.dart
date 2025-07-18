import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../../domain/entities/product_filter.dart';
import '../../core/models/pagination_models.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products_paginated_usecase.dart';
import '../../di/dependency_injection.dart' show sl;

/// Product filter state notifier
class ProductFilterNotifier extends StateNotifier<ProductFilter> {
  ProductFilterNotifier(this._ref) : super(const ProductFilter.empty()) {
    _loadPersistedFilter();
  }

  final Ref _ref;
  Timer? _debounceTimer;
  static const String _filterKey = 'product_filter_state';

  /// Load persisted filter state
  Future<void> _loadPersistedFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = prefs.getString(_filterKey);
      if (filterJson != null) {
        final filterMap = json.decode(filterJson) as Map<String, dynamic>;
        state = ProductFilter.fromJson(filterMap);
      }
    } catch (e) {
      // If loading fails, keep default empty state
    }
  }

  /// Persist filter state
  Future<void> _persistFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filterJson = json.encode(state.toJson());
      await prefs.setString(_filterKey, filterJson);
    } catch (e) {
      // Silently fail if persistence fails
    }
  }

  /// Add a filter with debounced application
  void addFilter(FilterCriteria filter) {
    state = state.addFilter(filter);
    _persistFilter();
    _debouncedApplyFilters();
  }

  /// Remove a filter by type
  void removeFilter(String filterType) {
    state = state.removeFilter(filterType);
    _persistFilter();
    _debouncedApplyFilters();
  }

  /// Update sort option
  void updateSort(SortOption sortOption) {
    state = state.updateSort(sortOption);
    _persistFilter();
    _debouncedApplyFilters();
  }

  /// Update search query
  void updateSearch(String? query) {
    state = state.updateSearch(query);
    _persistFilter();
    _debouncedApplyFilters();
  }

  /// Clear all filters
  void clearAll() {
    state = state.clearAll();
    _persistFilter();
    _debouncedApplyFilters();
  }

  /// Apply filters with debouncing to prevent excessive API calls
  void _debouncedApplyFilters() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _applyFilters();
    });
  }

  /// Apply current filters to product providers
  void _applyFilters() {
    // Trigger refresh of filtered products
    _ref.read(filteredProductsProvider.notifier).applyFilters(state);
  }

  /// Apply filters immediately (for user-initiated actions)
  void applyFiltersImmediately() {
    _debounceTimer?.cancel();
    _applyFilters();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for product filter state
final productFilterProvider = StateNotifierProvider<ProductFilterNotifier, ProductFilter>((ref) {
  return ProductFilterNotifier(ref);
});

/// Filtered products state
class FilteredProductsState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;

  const FilteredProductsState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 1,
  });

  FilteredProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
  }) {
    return FilteredProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Notifier for filtered products
class FilteredProductsNotifier extends StateNotifier<FilteredProductsState> {
  FilteredProductsNotifier() : super(const FilteredProductsState());

  ProductFilter? _currentFilter;

  /// Apply filters and load products
  Future<void> applyFilters(ProductFilter filter) async {
    if (_currentFilter == filter) return; // No change in filters

    _currentFilter = filter;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Convert filter to GetProductsPaginatedParams
      final params = _filterToParams(filter, page: 1);
      
      // Get product repository
      final repository = sl<ProductRepository>();
      
      // Fetch filtered products
      final result = await repository.getProductsPaginated(
        pagination: params.pagination,
        categoryId: params.categoryId,
        subcategoryId: params.subcategoryId,
        searchQuery: params.searchQuery,
        sortBy: params.sortBy,
        ascending: params.ascending,
        minPrice: params.minPrice,
        maxPrice: params.maxPrice,
      );

      result.fold(
        (failure) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: failure.message,
          );
        },
        (paginatedResponse) {
          state = state.copyWith(
            isLoading: false,
            products: paginatedResponse.data.cast<Product>(),
            totalCount: paginatedResponse.meta.totalItems,
            currentPage: 1,
            hasMore: paginatedResponse.meta.hasNextPage,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load filtered products: $e',
      );
    }
  }

  /// Load more products (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || _currentFilter == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final params = _filterToParams(_currentFilter!, page: nextPage);
      
      final repository = sl<ProductRepository>();
      
      final result = await repository.getProductsPaginated(
        pagination: params.pagination,
        categoryId: params.categoryId,
        subcategoryId: params.subcategoryId,
        searchQuery: params.searchQuery,
        sortBy: params.sortBy,
        ascending: params.ascending,
        minPrice: params.minPrice,
        maxPrice: params.maxPrice,
      );

      result.fold(
        (failure) {
          state = state.copyWith(isLoadingMore: false);
        },
        (paginatedResponse) {
          final updatedProducts = [...state.products, ...paginatedResponse.data.cast<Product>()];
          state = state.copyWith(
            isLoadingMore: false,
            products: updatedProducts,
            currentPage: nextPage,
            hasMore: paginatedResponse.meta.hasNextPage,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Convert ProductFilter to GetProductsPaginatedParams
  GetProductsPaginatedParams _filterToParams(ProductFilter filter, {required int page}) {
    // Extract filter parameters
    String? categoryId;
    String? subcategoryId;
    double? minPrice;
    double? maxPrice;

    for (final criteria in filter.filters) {
      switch (criteria.type) {
        case 'category':
          categoryId = criteria.parameters['category_id'] as String?;
          subcategoryId = criteria.parameters['subcategory_id'] as String?;
          break;
        case 'price_range':
          minPrice = criteria.parameters['min_price'] as double?;
          maxPrice = criteria.parameters['max_price'] as double?;
          break;
      }
    }

    // Convert sort option
    String? sortBy;
    bool? ascending;
    switch (filter.sortOption) {
      case SortOption.relevance:
        sortBy = 'relevance_score';
        ascending = false;
        break;
      case SortOption.priceLowToHigh:
        sortBy = 'retail_sale_price';
        ascending = true;
        break;
      case SortOption.priceHighToLow:
        sortBy = 'retail_sale_price';
        ascending = false;
        break;
      case SortOption.discounts:
        sortBy = 'discount_percentage';
        ascending = false;
        break;
    }

    return GetProductsPaginatedParams(
      pagination: PaginationParams(page: page, limit: 20),
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      searchQuery: filter.searchQuery,
      sortBy: sortBy,
      ascending: ascending,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}

/// Provider for filtered products
final filteredProductsProvider = StateNotifierProvider<FilteredProductsNotifier, FilteredProductsState>((ref) {
  return FilteredProductsNotifier();
});

/// Provider for filter suggestions (would fetch from backend)
final filterSuggestionsProvider = FutureProvider<List<FilterSuggestion>>((ref) async {
  // This would call the backend API to get filter suggestions
  // For now, return some mock suggestions
  return [
    const FilterSuggestion(
      type: 'price_range',
      label: 'Under ₹100',
      value: {'max_price': 100},
    ),
    const FilterSuggestion(
      type: 'price_range',
      label: '₹100 - ₹500',
      value: {'min_price': 100, 'max_price': 500},
    ),
    const FilterSuggestion(
      type: 'stock',
      label: 'In Stock Only',
      value: {'in_stock_only': true},
    ),
  ];
});
