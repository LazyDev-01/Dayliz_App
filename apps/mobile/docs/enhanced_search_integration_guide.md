# Enhanced Search System - Integration Guide

## 🚀 Quick Start

### 1. Basic Usage

To use the enhanced search screen in your app:

```dart
import 'package:go_router/go_router.dart';

// Navigate to enhanced search
context.push('/clean/enhanced-search');

// Or use the navigation helper
Routes.navigateToEnhancedSearch(context);
```

### 2. Using Search Providers

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/enhanced_search_providers.dart';

class MySearchWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch search state
    final searchState = ref.watch(searchStateProvider);
    
    // Get search actions
    final searchActions = ref.watch(searchActionsProvider);
    
    return Column(
      children: [
        // Search input
        TextField(
          onChanged: (query) => searchActions.updateQuery(query),
          decoration: InputDecoration(
            hintText: 'Search products...',
          ),
        ),
        
        // Search results
        if (searchState.hasResults)
          Consumer(
            builder: (context, ref, child) {
              final results = ref.watch(
                enhancedSearchResultsProvider(searchState.debouncedQuery)
              );
              
              return results.when(
                data: (products) => ProductGrid(products: products),
                loading: () => CircularProgressIndicator(),
                error: (error, stack) => Text('Error: $error'),
              );
            },
          ),
      ],
    );
  }
}
```

### 3. Search Service Direct Usage

```dart
import '../core/services/search_service.dart';
import '../di/injection_container.dart' as di;

class MyService {
  final SearchService _searchService = di.sl<SearchService>();
  
  Future<void> performSearch(String query) async {
    final result = await _searchService.searchProducts(
      query: query,
      limit: 20,
      useCache: true,
    );
    
    result.fold(
      (failure) => print('Search failed: ${failure.message}'),
      (products) => print('Found ${products.length} products'),
    );
  }
  
  void getSearchAnalytics() {
    final analytics = _searchService.getSearchAnalytics();
    final history = _searchService.getSearchHistory();
    final suggestions = _searchService.getSearchSuggestions('mil');
    
    print('Analytics: $analytics');
    print('History: $history');
    print('Suggestions: $suggestions');
  }
}
```

## 🎯 Available Screens

### 1. Enhanced Search Screen
- **Route**: `/clean/search` or `/clean/enhanced-search`
- **Features**: Advanced search with suggestions, history, analytics
- **Best for**: All search functionality (now the default)

### 3. Search Demo Screen
- **Route**: `/clean/debug/search-demo`
- **Features**: Interactive demo of all search features
- **Best for**: Testing and demonstration

## 🔧 Configuration

### Search Service Settings

```dart
// In search_service.dart
class SearchService {
  static const int _maxHistoryItems = 20;        // Max search history
  static const int _maxPopularSearches = 10;     // Max popular searches
  static const Duration _cacheExpiry = Duration(minutes: 5); // Cache expiry
}
```

### Provider Settings

```dart
// In enhanced_search_providers.dart
Timer(const Duration(milliseconds: 300), () {
  // Debounce delay - adjust as needed
});
```

## 📊 Analytics & Monitoring

### Getting Analytics Data

```dart
// Get search analytics
final analytics = ref.watch(searchAnalyticsProvider);
print('Search counts: $analytics');

// Get cache statistics
final cacheStats = ref.watch(searchCacheStatsProvider);
print('Cache info: $cacheStats');

// Get popular searches
final popularSearches = ref.watch(popularSearchesProvider);
print('Popular: $popularSearches');
```

### Tracking Custom Events

```dart
final searchService = ref.read(searchServiceProvider);

// Manual analytics tracking (if needed)
searchService.trackSearch('custom_query');

// Cache management
searchService.clearCache();
final stats = searchService.getCacheStats();
```

## 🎨 UI Components

### Search Suggestions Widget

```dart
import '../widgets/search/search_suggestions_widget.dart';

SearchSuggestionsWidget(
  query: currentQuery,
  onSuggestionTap: (suggestion) {
    // Handle suggestion tap
    performSearch(suggestion);
  },
  onSuggestionInsert: (suggestion) {
    // Insert suggestion into search field
    searchController.text = suggestion;
  },
  maxSuggestions: 8,
)
```

### Custom Search Bar

```dart
Widget buildSearchBar() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: TextField(
      controller: searchController,
      decoration: InputDecoration(
        hintText: 'Search for products...',
        prefixIcon: Icon(Icons.search),
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onChanged: (query) {
        ref.read(searchActionsProvider).updateQuery(query);
      },
    ),
  );
}
```

## 🔄 Migration from Old Search

### Step 1: Navigation (Already Updated)

```dart
// Enhanced search is now the default for all search routes
context.push('/clean/search');           // Uses enhanced search
context.push('/clean/enhanced-search');  // Also uses enhanced search
```

### Step 2: Update Providers

```dart
// Old providers
final searchResults = ref.watch(searchResultsProvider);

// New enhanced providers
final searchState = ref.watch(searchStateProvider);
final searchResults = ref.watch(
  enhancedSearchResultsProvider(searchState.debouncedQuery)
);
```

### Step 3: Update State Management

```dart
// Old way
ref.read(searchQueryProvider.notifier).state = query;

// New way
ref.read(searchActionsProvider).updateQuery(query);
```

## 🧪 Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import '../test/core/services/search_service_test.dart';

// Run search service tests
flutter test test/core/services/search_service_test.dart
```

### Integration Tests

```dart
// Test search flow
testWidgets('Enhanced search flow', (tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to search
  await tester.tap(find.byIcon(Icons.search));
  await tester.pumpAndSettle();
  
  // Enter search query
  await tester.enterText(find.byType(TextField), 'milk');
  await tester.pumpAndSettle();
  
  // Verify results
  expect(find.byType(ProductCard), findsWidgets);
});
```

## 🚨 Troubleshooting

### Common Issues

1. **Search not working**
   - Check if SearchService is registered in DI
   - Verify product dependencies are initialized
   - Check network connectivity

2. **Suggestions not appearing**
   - Ensure search history has data
   - Check if query length is sufficient (>= 1 character)
   - Verify SearchService is properly initialized

3. **Cache not working**
   - Check if SharedPreferences is available
   - Verify cache expiry settings
   - Clear cache if corrupted: `searchService.clearCache()`

### Debug Tools

```dart
// Enable debug logging
debugPrint('Search state: ${searchState.toString()}');

// Check cache statistics
final stats = searchService.getCacheStats();
debugPrint('Cache stats: $stats');

// Verify analytics
final analytics = searchService.getSearchAnalytics();
debugPrint('Analytics: $analytics');
```

## 🎉 Next Steps

After integrating the enhanced search system:

1. **Test thoroughly** with real data
2. **Monitor analytics** to understand user behavior
3. **Optimize performance** based on usage patterns
4. **Prepare for Phase 2** - Advanced Filter System

For Phase 2 features (coming soon):
- Advanced filter bottom sheet
- Price range sliders
- Category and brand filters
- Voice search capabilities
- Barcode scanning

## 📞 Support

If you encounter any issues:
1. Check this integration guide
2. Review the main documentation: `enhanced_search_system.md`
3. Test with the demo screen: `/clean/debug/search-demo`
4. Check unit tests for examples
