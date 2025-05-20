import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../providers/search_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/product/product_card.dart';

/// Clean architecture implementation of the search screen
class CleanSearchScreen extends ConsumerStatefulWidget {
  const CleanSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanSearchScreen> createState() => _CleanSearchScreenState();
}

class _CleanSearchScreenState extends ConsumerState<CleanSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Set focus on the search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = query;
      setState(() {
        _hasSearched = true;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    setState(() {
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Initialize the debouncer
    ref.watch(searchDebouncerProvider);
    
    // Get search state from providers
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);
    final isLoading = ref.watch(searchLoadingProvider);
    final errorMessage = ref.watch(searchErrorProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          decoration: InputDecoration(
            hintText: 'Search for products...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          onSubmitted: _performSearch,
          onChanged: (value) {
            setState(() {});
            if (value.trim().isNotEmpty) {
              ref.read(searchQueryProvider.notifier).state = value;
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_hasSearched && _searchController.text.isEmpty)
            // Show search suggestions if user hasn't searched yet
            _buildSearchSuggestions()
          else if (isLoading)
            // Show loading indicator
            const Expanded(
              child: Center(
                child: LoadingIndicator(message: 'Searching...'),
              ),
            )
          else if (errorMessage != null)
            // Show error state
            Expanded(
              child: ErrorState(
                message: errorMessage,
                onRetry: () => _performSearch(_searchController.text),
              ),
            )
          else
            // Show search results
            Expanded(
              child: searchResults.when(
                data: (products) {
                  if (products.isEmpty && _hasSearched) {
                    return _buildNoResults(searchQuery);
                  }
                  return _buildSearchResults(products);
                },
                loading: () => const Center(
                  child: LoadingIndicator(message: 'Searching...'),
                ),
                error: (error, stack) => ErrorState(
                  message: error.toString(),
                  onRetry: () => _performSearch(_searchController.text),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    final recentSearches = ref.watch(recentSearchesProvider);

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (recentSearches.isNotEmpty)
                TextButton(
                  onPressed: () {
                    ref.read(recentSearchesProvider.notifier).clearSearches();
                  },
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentSearches.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Center(
                child: Text(
                  'No recent searches',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentSearches.map((search) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(search),
                  onTap: () {
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.north_west),
                        onPressed: () {
                          _searchController.text = search;
                          _performSearch(search);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          ref.read(recentSearchesProvider.notifier).removeSearch(search);
                        },
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "$query"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try using different keywords or check for typos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 20,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => context.push('/clean/product/${product.id}'),
        );
      },
    );
  }
}
