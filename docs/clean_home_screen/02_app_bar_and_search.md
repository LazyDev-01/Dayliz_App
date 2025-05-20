# Clean Home Screen: App Bar & Search Implementation

## 1. App Bar Design

The app bar is a critical component of the home screen, providing branding and quick access to key functions. It should be visually appealing while remaining functional.

### 1.1 Visual Design

- **Height**: Slightly taller than standard (approximately 60-64dp)
- **Elevation**: Subtle shadow for depth (2-4dp)
- **Color**: Primary brand color or white with accent elements
- **Logo/Title**: Prominently displayed on the left
- **Action Icons**: Right-aligned with proper spacing

### 1.2 Functional Elements

- **Logo/Title**: Brand identity and possible navigation to home
- **Search Icon**: Opens search functionality
- **Notification Icon**: Badge indicator for unread notifications
- **Wishlist Icon**: Badge indicator for wishlist items
- **Optional Cart Icon**: Quick access to cart with item count badge

## 2. App Bar Implementation

```dart
PreferredSize _buildAppBar() {
  final cartItemCount = ref.watch(cartItemCountProvider);
  final wishlistItemCount = ref.watch(wishlistItemCountProvider);
  final notificationCount = ref.watch(unreadNotificationsCountProvider);
  
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: AppBar(
      elevation: 2,
      title: const Text(
        'Dayliz',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        // Search icon
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search',
          onPressed: () => _showSearch(context),
        ),
        
        // Notifications icon with badge
        Badge(
          isLabelVisible: notificationCount > 0,
          label: Text(
            notificationCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ),
        
        // Wishlist icon with badge
        Badge(
          isLabelVisible: wishlistItemCount > 0,
          label: Text(
            wishlistItemCount.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Wishlist',
            onPressed: () => context.push('/wishlist'),
          ),
        ),
      ],
    ),
  );
}
```

## 3. Search Bar Design

The search bar should be prominent and easily accessible, providing a seamless search experience.

### 3.1 Visual Design

- **Width**: Full width with horizontal padding (16dp on each side)
- **Height**: Comfortable touch target (48-56dp)
- **Border Radius**: Rounded corners (16-24dp)
- **Background**: Light gray or subtle contrast to background
- **Placeholder Text**: Clear instruction ("Search for products...")
- **Search Icon**: Left-aligned within the search bar

### 3.2 Interaction States

- **Resting State**: Search icon and placeholder text
- **Focus State**: Cursor visible, keyboard shown
- **Input State**: Text visible, clear button appears
- **Results State**: Suggestions or results appear below

## 4. Search Bar Implementation

### 4.1 Search Bar Widget

```dart
Widget _buildSearchBar() {
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: () => _showSearch(context),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                'Search for products...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
```

### 4.2 Search Screen Navigation

```dart
void _showSearch(BuildContext context) {
  // Navigate to dedicated search screen
  context.push('/search');
  
  // Alternatively, show search delegate
  // showSearch(
  //   context: context,
  //   delegate: ProductSearchDelegate(ref),
  // );
}
```

### 4.3 Search Delegate (Alternative Approach)

```dart
class ProductSearchDelegate extends SearchDelegate<String> {
  final WidgetRef ref;
  
  ProductSearchDelegate(this.ref);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    if (query.length < 3) {
      return Center(
        child: Text('Please enter at least 3 characters to search'),
      );
    }
    
    // Use search provider to get results
    final searchResultsAsync = ref.watch(searchProductsProvider(query));
    
    return searchResultsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text('No products found'),
          );
        }
        
        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: product.imageUrl != null
                  ? Image.network(
                      product.imageUrl!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.image_not_supported),
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              onTap: () {
                close(context, product.id);
                context.push('/product/${product.id}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    // Show recent searches or popular searches
    final recentSearches = ref.watch(recentSearchesProvider);
    
    if (query.isEmpty) {
      return ListView.builder(
        itemCount: recentSearches.length,
        itemBuilder: (context, index) {
          final search = recentSearches[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(search),
            onTap: () {
              query = search;
              showResults(context);
            },
            trailing: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                ref.read(recentSearchesProvider.notifier).removeSearch(search);
              },
            ),
          );
        },
      );
    }
    
    // Show search suggestions based on current query
    final suggestionsAsync = ref.watch(searchSuggestionsProvider(query));
    
    return suggestionsAsync.when(
      data: (suggestions) {
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              leading: const Icon(Icons.search),
              title: Text(suggestion),
              onTap: () {
                query = suggestion;
                showResults(context);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

## 5. State Management for Search

### 5.1 Search Providers

```dart
// Recent searches provider
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]) {
    _loadRecentSearches();
  }
  
  Future<void> _loadRecentSearches() async {
    // Load from local storage
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    state = searches;
  }
  
  Future<void> addSearch(String query) async {
    if (query.isEmpty) return;
    
    // Remove if already exists
    state = state.where((s) => s != query).toList();
    
    // Add to the beginning
    state = [query, ...state];
    
    // Limit to 10 recent searches
    if (state.length > 10) {
      state = state.sublist(0, 10);
    }
    
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', state);
  }
  
  Future<void> removeSearch(String query) async {
    state = state.where((s) => s != query).toList();
    
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', state);
  }
  
  Future<void> clearSearches() async {
    state = [];
    
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', []);
  }
}

// Search suggestions provider
final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];
  
  // Get suggestions from repository
  final searchRepository = ref.watch(searchRepositoryProvider);
  return searchRepository.getSuggestions(query);
});

// Search products provider
final searchProductsProvider = FutureProvider.family<List<Product>, String>((ref, query) async {
  if (query.isEmpty) return [];
  
  // Get search results from repository
  final searchRepository = ref.watch(searchRepositoryProvider);
  final results = await searchRepository.searchProducts(query);
  
  // Add to recent searches
  ref.read(recentSearchesProvider.notifier).addSearch(query);
  
  return results;
});
```

## 6. Accessibility Considerations

- **Search Bar**: Ensure proper contrast between placeholder text and background
- **Icons**: Add meaningful tooltips for all action icons
- **Badge Counts**: Ensure badges are readable with sufficient contrast
- **Touch Targets**: All interactive elements should be at least 48x48dp
- **Screen Reader Support**: Add semantic labels to all interactive elements

## 7. Testing Strategy

### 7.1 Unit Tests

- Test search providers and notifiers
- Test search repository methods

### 7.2 Widget Tests

- Test app bar rendering and actions
- Test search bar interactions
- Test search delegate functionality

### 7.3 Integration Tests

- Test navigation from app bar to other screens
- Test search flow from input to results
- Test recent searches functionality
