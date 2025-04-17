import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/models/category_models.dart';
import 'package:dayliz_app/providers/home_providers.dart';
import 'dart:async';

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

// Provider for search results based on the debounced query
final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  // Initialize the debouncer
  ref.watch(searchDebouncerProvider);
  
  final query = ref.watch(debouncedSearchQueryProvider);
  
  // Empty query returns empty results
  if (query.isEmpty) {
    ref.read(searchLoadingProvider.notifier).state = false;
    return [];
  }
  
  // Check cache first
  final cache = ref.watch(searchResultsCacheProvider);
  if (cache.containsKey(query)) {
    print('🔍 Using cached search results for "$query"');
    ref.read(searchLoadingProvider.notifier).state = false;
    return cache[query]!;
  }
  
  // Set loading state
  ref.read(searchLoadingProvider.notifier).state = true;
  
  try {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    print('🔍 Searching for "$query"');
    
    // In a real app, this would be an API call
    // For now, we'll filter from the all products list
    final allProducts = await ref.watch(allProductsProvider.future);
    
    // Case-insensitive search in name and description
    final results = allProducts.where((product) {
      final name = product.name.toLowerCase();
      final description = product.description.toLowerCase();
      final searchTerms = query.toLowerCase().split(' ');
      
      // Check if any search term is in the name or description
      return searchTerms.any((term) => 
        name.contains(term) || description.contains(term)
      );
    }).toList();
    
    // Cache the results
    final updatedCache = Map<String, List<Product>>.from(cache);
    updatedCache[query] = results;
    ref.read(searchResultsCacheProvider.notifier).state = updatedCache;
    
    return results;
  } catch (e) {
    print('🔍 Search error: $e');
    rethrow;
  } finally {
    // Always reset loading state
    ref.read(searchLoadingProvider.notifier).state = false;
  }
});

// Recent searches (would be persisted in a real app)
final recentSearchesProvider = StateProvider<List<String>>((ref) => [
  'Fresh fruits',
  'Vegetables',
  'Dairy products',
  'Bread',
]);

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