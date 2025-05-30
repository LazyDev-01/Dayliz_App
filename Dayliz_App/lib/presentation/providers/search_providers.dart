import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/product.dart';
import '../../domain/usecases/search_products_usecase.dart';
import '../../core/errors/failures.dart';
import '../../di/injection_container.dart' as di;

/// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for debounced search query to reduce API calls
final debouncedSearchQueryProvider = StateProvider<String>((ref) => '');

/// Provider to handle debounce logic for search
final searchDebouncerProvider = Provider<void>((ref) {
  Timer? timer;

  ref.listen<String>(searchQueryProvider, (_, newQuery) {
    if (timer != null) {
      timer!.cancel();
    }

    timer = Timer(const Duration(milliseconds: 500), () {
      ref.read(debouncedSearchQueryProvider.notifier).state = newQuery;
    });
  });
});

/// Provider for search loading state
final searchLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for search error message
final searchErrorProvider = StateProvider<String?>((ref) => null);

/// Provider for recent searches
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) => RecentSearchesNotifier(),
);

/// State notifier for managing recent searches
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  static const int _maxSearches = 5;

  RecentSearchesNotifier() : super([]) {
    _loadRecentSearches();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      state = searches;
    } catch (e) {
      // Silently handle error and use empty list
    }
  }

  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', state);
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Remove if already exists (to avoid duplicates)
    state = state.where((item) => item.toLowerCase() != query.toLowerCase()).toList();

    // Add to the beginning of the list
    final newState = [query, ...state];

    // Limit to max searches
    if (newState.length > _maxSearches) {
      state = newState.sublist(0, _maxSearches);
    } else {
      state = newState;
    }

    await _saveRecentSearches();
  }

  Future<void> removeSearch(String query) async {
    state = state.where((item) => item != query).toList();
    await _saveRecentSearches();
  }

  Future<void> clearSearches() async {
    state = [];
    await _saveRecentSearches();
  }
}

/// Provider for search results
final searchResultsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  // Set loading state
  ref.read(searchLoadingProvider.notifier).state = true;
  ref.read(searchErrorProvider.notifier).state = null;

  try {
    // Get the search products use case from DI
    final searchProductsUseCase = di.sl<SearchProductsUseCase>();

    // Call the use case
    final result = await searchProductsUseCase(
      SearchProductsParams(query: query, limit: 20),
    );

    return result.fold(
      (failure) {
        // Handle failure
        final errorMessage = _mapFailureToMessage(failure);
        ref.read(searchErrorProvider.notifier).state = errorMessage;
        return [];
      },
      (products) {
        // Add the query to recent searches
        ref.read(recentSearchesProvider.notifier).addSearch(query);
        return products;
      },
    );
  } catch (e) {
    // Handle exception
    ref.read(searchErrorProvider.notifier).state = e.toString();
    return [];
  } finally {
    // Clear loading state regardless of result
    ref.read(searchLoadingProvider.notifier).state = false;
  }
});

/// Maps a Failure to a user-friendly error message
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return failure.message ?? 'Server error occurred';
    case CacheFailure:
      return failure.message ?? 'Cache error occurred';
    case NetworkFailure:
      return failure.message ?? 'Network error occurred';
    default:
      return 'Unexpected error occurred';
  }
}
