import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/models/category_models.dart';
import 'package:dayliz_app/providers/home_providers.dart';
import 'dart:async';
import 'package:dayliz_app/services/product_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Debounced search query to reduce API calls
final debouncedSearchQueryProvider = StateProvider<String>((ref) => '');

// Create a provider to handle the debounce logic
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

// Search loading indicator
final searchLoadingProvider = StateProvider<bool>((ref) => false);

// Cache for search results
final searchResultsCacheProvider = StateProvider<Map<String, List<Product>>>((ref) => {});

// Store recent searches (max 5)
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>(
  (ref) => RecentSearchesNotifier(),
);

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  static const String _prefsKey = 'recent_searches';
  static const int _maxSearches = 5;
  
  RecentSearchesNotifier() : super([]) {
    _loadRecentSearches();
  }
  
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList(_prefsKey) ?? [];
      state = searches;
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }
  
  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, state);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }
  
  void addSearch(String query) {
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
    
    _saveRecentSearches();
  }
  
  void removeSearch(String query) {
    state = state.where((item) => item != query).toList();
    _saveRecentSearches();
  }
  
  void clearSearches() {
    state = [];
    _saveRecentSearches();
  }
}

// Search results provider for subcategories
final subcategorySearchResultsProvider = FutureProvider<List<SubCategory>>((ref) async {
  final query = ref.watch(debouncedSearchQueryProvider);
  
  if (query.isEmpty) {
    return [];
  }
  
  // In a real app, this would search against API
  // For now, mock the data
  await Future.delayed(const Duration(milliseconds: 500));
  
  return [];
});

// Search results
final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  
  if (query.trim().isEmpty) {
    return [];
  }
  
  // Set loading state
  ref.read(searchLoadingProvider.notifier).state = true;
  
  try {
    // Add the query to recent searches
    ref.read(recentSearchesProvider.notifier).addSearch(query);
    
    final productService = ref.read(productServiceProvider);
    final results = await productService.searchProducts(query);
    
    return results;
  } finally {
    // Clear loading state regardless of result
    ref.read(searchLoadingProvider.notifier).state = false;
  }
}); 