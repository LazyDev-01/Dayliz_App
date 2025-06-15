import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartz/dartz.dart';

import '../../core/services/search_service.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../core/errors/failures.dart';
import '../../di/injection_container.dart' as di;

/// Enhanced search providers with advanced functionality
/// Replaces the basic search providers with more robust implementations

// Search service provider
final searchServiceProvider = Provider<SearchService>((ref) {
  final productRepository = di.sl<ProductRepository>();
  return SearchService(productRepository);
});

/// Current search query provider - tracks immediate user input
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced search query provider - delays search execution for performance
final debouncedSearchQueryProvider = StateProvider<String>((ref) => '');

// Search debouncer provider
final searchDebouncerProvider = Provider<void>((ref) {
  Timer? timer;

  ref.listen<String>(searchQueryProvider, (_, newQuery) {
    if (timer != null) {
      timer!.cancel();
    }

    timer = Timer(const Duration(milliseconds: 300), () {
      ref.read(debouncedSearchQueryProvider.notifier).state = newQuery;
    });
  });

  ref.onDispose(() {
    timer?.cancel();
  });
});

// Enhanced search results provider with proper error handling
final enhancedSearchResultsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.trim().isEmpty) {
    return [];
  }

  try {
    final searchService = ref.read(searchServiceProvider);

    final result = await searchService.searchProducts(
      query: query,
      limit: 50, // Increased limit for better results
      useCache: true,
    );

    return result.fold(
      (failure) {
        // Don't modify other providers during build - let the UI handle the error
        throw Exception(failure.message);
      },
      (products) {
        return products;
      },
    );
  } catch (e) {
    // Re-throw the error to be handled by the FutureProvider's error state
    rethrow;
  }
});

// Search history provider
final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(ref.read(searchServiceProvider)),
);

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final SearchService _searchService;

  SearchHistoryNotifier(this._searchService) : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    state = _searchService.getSearchHistory();
  }

  Future<void> removeFromHistory(String query) async {
    await _searchService.removeFromHistory(query);
    state = _searchService.getSearchHistory();
  }

  Future<void> clearHistory() async {
    await _searchService.clearHistory();
    state = [];
  }

  void refreshHistory() {
    state = _searchService.getSearchHistory();
  }
}

// Popular searches provider
final popularSearchesProvider = Provider<List<String>>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return searchService.getPopularSearches();
});

// Search suggestions provider - immediate, no debouncing
final searchSuggestionsProvider = Provider.family<List<String>, String>((ref, query) {
  if (query.trim().isEmpty) return [];

  final searchService = ref.read(searchServiceProvider); // Use read for immediate response
  return searchService.getSearchSuggestions(query);
});



// Search analytics provider
final searchAnalyticsProvider = Provider<Map<String, int>>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return searchService.getSearchAnalytics();
});

// Search cache statistics provider
final searchCacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final searchService = ref.watch(searchServiceProvider);
  return searchService.getCacheStats();
});

// Search state provider - combines all search-related state
final searchStateProvider = Provider<SearchState>((ref) {
  final query = ref.watch(searchQueryProvider);
  final debouncedQuery = ref.watch(debouncedSearchQueryProvider);
  final history = ref.watch(searchHistoryProvider);
  final suggestions = ref.watch(searchSuggestionsProvider(query));
  final popularSearches = ref.watch(popularSearchesProvider);

  return SearchState(
    query: query,
    debouncedQuery: debouncedQuery,
    isLoading: false, // Loading state handled by FutureProvider
    error: null, // Error state handled by FutureProvider
    history: history,
    suggestions: suggestions,
    popularSearches: popularSearches,
  );
});

// Search state data class
class SearchState {
  final String query;
  final String debouncedQuery;
  final bool isLoading;
  final String? error;
  final List<String> history;
  final List<String> suggestions;
  final List<String> popularSearches;

  const SearchState({
    required this.query,
    required this.debouncedQuery,
    required this.isLoading,
    this.error,
    required this.history,
    required this.suggestions,
    required this.popularSearches,
  });

  bool get hasQuery => query.trim().isNotEmpty;
  bool get hasResults => debouncedQuery.trim().isNotEmpty;
  bool get hasError => error != null;
  bool get hasHistory => history.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get hasPopularSearches => popularSearches.isNotEmpty;

  SearchState copyWith({
    String? query,
    String? debouncedQuery,
    bool? isLoading,
    String? error,
    List<String>? history,
    List<String>? suggestions,
    List<String>? popularSearches,
  }) {
    return SearchState(
      query: query ?? this.query,
      debouncedQuery: debouncedQuery ?? this.debouncedQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      history: history ?? this.history,
      suggestions: suggestions ?? this.suggestions,
      popularSearches: popularSearches ?? this.popularSearches,
    );
  }
}

// Search actions provider - provides methods for search operations
final searchActionsProvider = Provider<SearchActions>((ref) {
  return SearchActions(ref);
});

class SearchActions {
  final Ref _ref;

  SearchActions(this._ref);

  void updateQuery(String query) {
    _ref.read(searchQueryProvider.notifier).state = query;
  }

  void clearQuery() {
    _ref.read(searchQueryProvider.notifier).state = '';
    _ref.read(debouncedSearchQueryProvider.notifier).state = '';
  }

  void selectSuggestion(String suggestion) {
    _ref.read(searchQueryProvider.notifier).state = suggestion;
    _ref.read(debouncedSearchQueryProvider.notifier).state = suggestion;
  }

  Future<void> removeFromHistory(String query) async {
    await _ref.read(searchHistoryProvider.notifier).removeFromHistory(query);
  }

  Future<void> clearHistory() async {
    await _ref.read(searchHistoryProvider.notifier).clearHistory();
  }

  void clearCache() {
    _ref.read(searchServiceProvider).clearCache();
  }

  void refreshHistory() {
    _ref.read(searchHistoryProvider.notifier).refreshHistory();
  }
}
