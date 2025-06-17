import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../errors/failures.dart';

/// Unified search service that handles all search-related operations
/// Provides caching, analytics, suggestions, and advanced search capabilities
class SearchService {
  final ProductRepository _productRepository;
  static const String _searchHistoryKey = 'search_history';
  static const String _searchAnalyticsKey = 'search_analytics';
  static const int _maxHistoryItems = 20;
  static const int _maxPopularSearches = 10;

  // Cache for search results - now page-aware
  final Map<String, List<Product>> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Search analytics data
  final Map<String, int> _searchCounts = {};
  final List<String> _searchHistory = [];

  SearchService(this._productRepository) {
    _loadSearchData();
  }

  /// Load search history and analytics from local storage
  Future<void> _loadSearchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load search history
      final historyJson = prefs.getString(_searchHistoryKey);
      if (historyJson != null) {
        final List<dynamic> historyList = json.decode(historyJson);
        _searchHistory.clear();
        _searchHistory.addAll(historyList.cast<String>());
      }

      // Load search analytics
      final analyticsJson = prefs.getString(_searchAnalyticsKey);
      if (analyticsJson != null) {
        final Map<String, dynamic> analyticsMap = json.decode(analyticsJson);
        _searchCounts.clear();
        analyticsMap.forEach((key, value) {
          _searchCounts[key] = value as int;
        });
      }

      debugPrint('🔍 SearchService: Loaded ${_searchHistory.length} history items and ${_searchCounts.length} analytics entries');
    } catch (e) {
      debugPrint('❌ SearchService: Error loading search data: $e');
    }
  }

  /// Save search history and analytics to local storage
  Future<void> _saveSearchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save search history
      await prefs.setString(_searchHistoryKey, json.encode(_searchHistory));
      
      // Save search analytics
      await prefs.setString(_searchAnalyticsKey, json.encode(_searchCounts));
      
      debugPrint('🔍 SearchService: Saved search data');
    } catch (e) {
      debugPrint('❌ SearchService: Error saving search data: $e');
    }
  }

  /// Perform a comprehensive product search with page-aware caching
  Future<Either<Failure, List<Product>>> searchProducts({
    required String query,
    int? page,
    int? limit,
    bool useCache = true,
  }) async {
    if (query.trim().isEmpty) {
      return const Right([]);
    }

    final normalizedQuery = query.trim().toLowerCase();
    final currentPage = page ?? 1;
    final pageLimit = limit ?? 20;

    // Create page-aware cache key
    final cacheKey = _buildCacheKey(normalizedQuery, currentPage, pageLimit);

    // Check cache first if enabled (only for page 1 to avoid infinite scroll issues)
    if (useCache && currentPage == 1 && _isResultCached(cacheKey)) {
      debugPrint('🔍 SearchService: Returning cached results for "$normalizedQuery" (page $currentPage)');
      return Right(_searchCache[cacheKey]!);
    }

    try {
      debugPrint('🔍 SearchService: Searching for "$normalizedQuery" (page $currentPage, limit $pageLimit)');

      // Perform the search
      final result = await _productRepository.searchProducts(
        query: query,
        page: currentPage,
        limit: pageLimit,
      );

      return result.fold(
        (failure) {
          debugPrint('❌ SearchService: Search failed: ${failure.message}');
          return Left(failure);
        },
        (products) {
          // Only cache first page results to avoid memory issues
          if (useCache && currentPage == 1) {
            _cacheSearchResults(cacheKey, products);
          }

          // Track search analytics (only for first page)
          if (currentPage == 1) {
            _trackSearch(normalizedQuery);
            _addToHistory(query);
          }

          debugPrint('✅ SearchService: Found ${products.length} products for "$normalizedQuery" (page $currentPage)');
          return Right(products);
        },
      );
    } catch (e) {
      debugPrint('❌ SearchService: Unexpected error during search: $e');
      return Left(ServerFailure(message: 'Search failed: ${e.toString()}'));
    }
  }

  /// Build cache key that includes page and limit for proper pagination
  String _buildCacheKey(String query, int page, int limit) {
    return '${query}_p${page}_l$limit';
  }

  /// Build scope key for scoped search caching
  String _buildScopeKey(String? subcategoryId, String? categoryId) {
    if (subcategoryId != null) return 'sub_$subcategoryId';
    if (categoryId != null) return 'cat_$categoryId';
    return 'global';
  }

  /// Build scoped cache key that includes scope, page and limit
  String _buildScopedCacheKey(String query, String scope, int page, int limit) {
    return '${query}_${scope}_p${page}_l$limit';
  }

  /// Paginated search specifically for lazy loading
  Future<Either<Failure, List<Product>>> searchProductsPaginated({
    required String query,
    required int page,
    required int limit,
    bool useCache = true,
  }) async {
    return searchProducts(
      query: query,
      page: page,
      limit: limit,
      useCache: useCache,
    );
  }

  /// Scoped search within specific subcategory or category
  Future<Either<Failure, List<Product>>> searchProductsScoped({
    required String query,
    String? subcategoryId,
    String? categoryId,
    int? page,
    int? limit,
    bool useCache = true,
  }) async {
    if (query.trim().isEmpty) {
      return const Right([]);
    }

    final normalizedQuery = query.trim().toLowerCase();
    final currentPage = page ?? 1;
    final pageLimit = limit ?? 20;

    // Create scope-aware cache key
    final scopeKey = _buildScopeKey(subcategoryId, categoryId);
    final cacheKey = _buildScopedCacheKey(normalizedQuery, scopeKey, currentPage, pageLimit);

    // Check cache first if enabled (only for page 1)
    if (useCache && currentPage == 1 && _isResultCached(cacheKey)) {
      debugPrint('🔍 SearchService: Returning cached scoped results for "$normalizedQuery" in scope "$scopeKey"');
      return Right(_searchCache[cacheKey]!);
    }

    try {
      debugPrint('🔍 SearchService: Scoped search for "$normalizedQuery" (scope: $scopeKey, page: $currentPage)');

      // Use repository's scoped search capability
      final result = await _productRepository.searchProductsScoped(
        query: query,
        subcategoryId: subcategoryId,
        categoryId: categoryId,
        page: currentPage,
        limit: pageLimit,
      );

      return result.fold(
        (failure) {
          debugPrint('❌ SearchService: Scoped search failed: ${failure.message}');
          return Left(failure);
        },
        (products) {
          // Only cache first page results
          if (useCache && currentPage == 1) {
            _cacheSearchResults(cacheKey, products);
          }

          // Track search analytics (only for first page)
          if (currentPage == 1) {
            _trackScopedSearch(normalizedQuery, scopeKey);
            _addToHistory(query);
          }

          debugPrint('✅ SearchService: Found ${products.length} scoped products for "$normalizedQuery" in scope "$scopeKey"');
          return Right(products);
        },
      );
    } catch (e) {
      debugPrint('❌ SearchService: Unexpected error during scoped search: $e');
      return Left(ServerFailure(message: 'Scoped search failed: ${e.toString()}'));
    }
  }

  /// Public method to add search to history
  Future<void> addToHistory(String query) async {
    _addToHistory(query);
  }

  /// Check if search results are cached and not expired
  bool _isResultCached(String cacheKey) {
    if (!_searchCache.containsKey(cacheKey)) return false;

    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  /// Cache search results with timestamp
  void _cacheSearchResults(String cacheKey, List<Product> products) {
    _searchCache[cacheKey] = products;
    _cacheTimestamps[cacheKey] = DateTime.now();

    // Clean up old cache entries
    _cleanupCache();

    debugPrint('🔍 SearchService: Cached ${products.length} products with key: $cacheKey');
  }

  /// Remove expired cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) >= _cacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('🔍 SearchService: Cleaned up ${expiredKeys.length} expired cache entries');
    }
  }

  /// Track search for analytics
  void _trackSearch(String query) {
    _searchCounts[query] = (_searchCounts[query] ?? 0) + 1;
    _saveSearchData(); // Save analytics immediately
  }

  /// Track scoped search analytics
  void _trackScopedSearch(String query, String scope) {
    final scopedKey = '${query}_in_$scope';
    _searchCounts[scopedKey] = (_searchCounts[scopedKey] ?? 0) + 1;
    _saveSearchData(); // Save analytics immediately
    debugPrint('🔍 SearchService: Saved scoped search data for "$query" in scope "$scope"');
  }

  /// Add search to history
  void _addToHistory(String query) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;

    // Remove if already exists to avoid duplicates
    _searchHistory.remove(normalizedQuery);

    // Add to beginning
    _searchHistory.insert(0, normalizedQuery);

    // Limit history size
    if (_searchHistory.length > _maxHistoryItems) {
      _searchHistory.removeRange(_maxHistoryItems, _searchHistory.length);
    }

    _saveSearchData();
  }

  /// Get search history
  List<String> getSearchHistory() {
    return List.unmodifiable(_searchHistory);
  }

  /// Remove item from search history
  Future<void> removeFromHistory(String query) async {
    _searchHistory.remove(query);
    await _saveSearchData();
  }

  /// Clear all search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveSearchData();
  }

  /// Get popular searches based on analytics
  List<String> getPopularSearches() {
    final sortedEntries = _searchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(_maxPopularSearches)
        .map((entry) => entry.key)
        .toList();
  }

  /// Generate search suggestions based on query
  List<String> getSearchSuggestions(String query) {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = query.trim().toLowerCase();
    final suggestions = <String>[];

    // Add matching items from search history
    for (final historyItem in _searchHistory) {
      if (historyItem.toLowerCase().contains(normalizedQuery) &&
          historyItem.toLowerCase() != normalizedQuery) {
        suggestions.add(historyItem);
      }
    }

    // Add matching popular searches
    for (final popularSearch in getPopularSearches()) {
      if (popularSearch.toLowerCase().contains(normalizedQuery) &&
          popularSearch.toLowerCase() != normalizedQuery &&
          !suggestions.contains(popularSearch)) {
        suggestions.add(popularSearch);
      }
    }

    // Add common product name suggestions
    final productSuggestions = _getProductNameSuggestions(normalizedQuery);
    for (final suggestion in productSuggestions) {
      if (!suggestions.contains(suggestion)) {
        suggestions.add(suggestion);
      }
    }

    return suggestions.take(8).toList();
  }

  /// Get product name suggestions for better word recommendations
  List<String> _getProductNameSuggestions(String query) {
    final commonProducts = [
      'milk', 'bread', 'eggs', 'butter', 'cheese', 'rice', 'chicken', 'fish',
      'apple', 'banana', 'orange', 'tomato', 'onion', 'potato', 'oil', 'sugar',
      'tea', 'coffee', 'biscuits', 'chocolate', 'soap', 'shampoo', 'pasta',
      'yogurt', 'honey', 'salt', 'flour', 'garlic', 'ginger', 'spinach',
      'carrots', 'broccoli', 'lettuce', 'cucumber', 'bell pepper', 'mushrooms',
      'strawberries', 'grapes', 'watermelon', 'pineapple', 'mango', 'avocado',
      'salmon', 'tuna', 'prawns', 'beef', 'pork', 'turkey', 'lamb',
      'almonds', 'walnuts', 'cashews', 'peanuts', 'raisins', 'dates',
      'olive oil', 'coconut oil', 'sunflower oil', 'sesame oil',
      'green tea', 'black tea', 'herbal tea', 'instant coffee', 'ground coffee',
      'whole wheat bread', 'white bread', 'brown bread', 'multigrain bread',
      'basmati rice', 'brown rice', 'jasmine rice', 'wild rice',
      'cheddar cheese', 'mozzarella cheese', 'parmesan cheese', 'cream cheese',
      'greek yogurt', 'plain yogurt', 'flavored yogurt', 'low fat yogurt',
    ];

    final suggestions = <String>[];

    for (final product in commonProducts) {
      // Show suggestions that start with or contain the query
      if (product.toLowerCase().contains(query.toLowerCase())) {
        // Always show suggestions, even for complete matches
        suggestions.add(product);
      }
    }

    // Sort by relevance (starts with query first, then contains)
    suggestions.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      final queryLower = query.toLowerCase();

      // Exact match goes first
      if (aLower == queryLower) return -1;
      if (bLower == queryLower) return 1;

      // Starts with query
      if (aLower.startsWith(queryLower) && !bLower.startsWith(queryLower)) return -1;
      if (bLower.startsWith(queryLower) && !aLower.startsWith(queryLower)) return 1;

      // Length (shorter first for better relevance)
      return a.length.compareTo(b.length);
    });

    return suggestions.take(8).toList(); // Show more suggestions
  }

  /// Get search analytics data
  Map<String, int> getSearchAnalytics() {
    return Map.unmodifiable(_searchCounts);
  }

  /// Clear search cache
  void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🔍 SearchService: Cache cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_queries': _searchCache.length,
      'cache_size_mb': _calculateCacheSize(),
      'oldest_cache_entry': _getOldestCacheEntry(),
    };
  }

  /// Calculate approximate cache size in MB
  double _calculateCacheSize() {
    int totalSize = 0;
    _searchCache.forEach((key, products) {
      totalSize += key.length * 2; // Approximate string size
      totalSize += products.length * 500; // Approximate product object size
    });
    return totalSize / (1024 * 1024); // Convert to MB
  }

  /// Get the oldest cache entry timestamp
  DateTime? _getOldestCacheEntry() {
    if (_cacheTimestamps.isEmpty) return null;

    DateTime? oldest;
    for (final timestamp in _cacheTimestamps.values) {
      if (oldest == null || timestamp.isBefore(oldest)) {
        oldest = timestamp;
      }
    }

    return oldest;
  }

  /// Dispose resources
  void dispose() {
    _searchCache.clear();
    _cacheTimestamps.clear();
    debugPrint('🔍 SearchService: Disposed');
  }
}
