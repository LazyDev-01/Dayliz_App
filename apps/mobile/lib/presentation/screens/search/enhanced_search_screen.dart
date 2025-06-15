import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/enhanced_search_providers.dart';
import '../../providers/paginated_search_providers.dart';
import '../../providers/scoped_search_providers.dart';
import '../../widgets/search/infinite_scroll_product_grid.dart';
import '../../widgets/product/clean_product_card.dart';


/// Enhanced search screen with advanced search capabilities and context awareness
class EnhancedSearchScreen extends ConsumerStatefulWidget {
  final String? contextSubcategoryId;
  final String? contextCategoryId;
  final String? contextName;
  final String? initialQuery;

  const EnhancedSearchScreen({
    Key? key,
    this.contextSubcategoryId,
    this.contextCategoryId,
    this.contextName,
    this.initialQuery,
  }) : super(key: key);

  @override
  ConsumerState<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends ConsumerState<EnhancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _hasSearched = false;
  bool _showGlobalResults = false; // Toggle between scoped and global results

  @override
  void initState() {
    super.initState();

    // Set initial query if provided
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _hasSearched = true;
    }

    // Initialize debouncer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchDebouncerProvider);
      _searchFocus.requestFocus();

      // Perform initial search if query provided
      if (widget.initialQuery != null) {
        _performSearch(widget.initialQuery!);
      }
    });

    // Listen to search controller changes
    _searchController.addListener(() {
      final searchActions = ref.read(searchActionsProvider);
      searchActions.updateQuery(_searchController.text);

      // Force rebuild to show suggestions immediately
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Check if search has context (subcategory or category)
  bool get _hasContext => widget.contextSubcategoryId != null || widget.contextCategoryId != null;

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      setState(() {
        _hasSearched = true;
        _showGlobalResults = false; // Start with scoped results if context available
      });
      _searchFocus.unfocus();

      // Delay provider updates to avoid build conflicts
      Future.microtask(() {
        if (_hasContext && !_showGlobalResults) {
          // Use scoped search first if context is available
          final scopedActions = ref.read(scopedSearchActionsProvider);
          final params = ScopedSearchParams(
            query: query,
            subcategoryId: widget.contextSubcategoryId,
            categoryId: widget.contextCategoryId,
            subcategoryName: widget.contextName,
          );
          scopedActions.search(params);
        } else {
          // Use global search
          final paginatedActions = ref.read(paginatedSearchActionsProvider);
          paginatedActions.search(query);
        }

        // Also update legacy search state for suggestions
        final searchActions = ref.read(searchActionsProvider);
        searchActions.updateQuery(query);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _hasSearched = false;
    });

    // Delay provider updates to avoid build conflicts
    Future.microtask(() {
      // Clear both search systems completely
      final searchActions = ref.read(searchActionsProvider);
      searchActions.clearQuery();

      final paginatedActions = ref.read(paginatedSearchActionsProvider);
      paginatedActions.reset(); // Use reset instead of clear for complete cleanup
    });

    _searchFocus.requestFocus();
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion); // This will show products
  }

  void _expandToGlobalSearch() {
    setState(() {
      _showGlobalResults = true;
    });

    // Perform global search with current query
    Future.microtask(() {
      final paginatedActions = ref.read(paginatedSearchActionsProvider);
      paginatedActions.search(_searchController.text);
    });
  }



  @override
  Widget build(BuildContext context) {
    final currentQuery = _searchController.text; // Use immediate text for suggestions

    return Scaffold(
      appBar: _buildSearchAppBar(context),
      body: Column(
        children: [
          if (!_hasSearched)
            // Show word recommendations while typing (not products)
            Expanded(
              child: _buildSuggestionsView(currentQuery),
            )
          else
            // Show context-aware search results
            Expanded(
              child: _buildSearchResults(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight), // Normal AppBar height
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF374151),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF374151)),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
            tooltip: 'Back',
          ),
          title: Container(
            height: 44, // Match home screen dimensions
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(14), // Match home screen border radius
              border: Border.all(
                color: Colors.grey[300]!, // Light grey border
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 16, // Match home screen text size
              ),
              decoration: InputDecoration(
                hintText: _hasContext
                    ? 'Search in ${widget.contextName ?? 'category'}...'
                    : 'Search for products...',
                hintStyle: TextStyle(
                  color: const Color(0xFF374151).withValues(alpha: 0.6),
                  fontSize: 16, // Match home screen hint text size
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Match home screen padding
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF374151)),
                        onPressed: _clearSearch,
                        tooltip: 'Clear',
                      ),
                    // Always show search icon - loading state handled by FutureProvider
                    IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF374151)),
                      onPressed: () => _performSearch(_searchController.text),
                      tooltip: 'Search',
                    ),
                  ],
                ),
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsView(String query) {
    final suggestions = ref.watch(searchSuggestionsProvider(query));
    final searchState = ref.watch(searchStateProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (query.isEmpty) ...[
          // Show search history when no query
          if (searchState.hasHistory) ...[
            _buildSectionHeader('Recent Searches', Icons.history),
            const SizedBox(height: 8),
            ...searchState.history.take(5).map((search) =>
              _buildSuggestionTile(search, Icons.history, () => _onSuggestionTap(search)),
            ),
            const SizedBox(height: 24),
          ],
          // Show popular searches
          if (searchState.hasPopularSearches) ...[
            _buildSectionHeader('Popular Searches', Icons.trending_up),
            const SizedBox(height: 8),
            _buildPopularSearchesGrid(searchState.popularSearches),
          ],
        ] else ...[
          // Show suggestions while typing
          if (suggestions.isNotEmpty) ...[
            _buildSectionHeader('Suggestions', Icons.auto_awesome),
            const SizedBox(height: 8),
            ...suggestions.map((suggestion) =>
              _buildSuggestionTile(suggestion, Icons.search, () => _onSuggestionTap(suggestion)),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionTile(String suggestion, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(suggestion, style: const TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  Widget _buildPopularSearchesGrid(List<String> popularSearches) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: popularSearches.take(6).map((search) =>
        ActionChip(
          label: Text(search, style: const TextStyle(fontSize: 12)),
          onPressed: () => _onSuggestionTap(search),
          backgroundColor: Colors.grey[100],
          side: BorderSide(color: Colors.grey[300]!),
        ),
      ).toList(),
    );
  }

  Widget _buildSearchResults() {
    if (_hasContext && !_showGlobalResults) {
      // Show scoped search results
      return _buildScopedSearchResults();
    } else {
      // Show global search results
      return _buildGlobalSearchResults();
    }
  }

  Widget _buildScopedSearchResults() {
    final scopedState = ref.watch(activeScopedSearchProvider);

    if (scopedState == null) {
      return _buildGlobalSearchResults(); // Fallback to global
    }

    return Column(
      children: [
        // Context header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.filter_list, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Results in ${widget.contextName ?? 'Category'}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _expandToGlobalSearch,
                child: Text(
                  'Search All',
                  style: TextStyle(color: Colors.blue[600]),
                ),
              ),
            ],
          ),
        ),

        // Scoped results
        Expanded(
          child: _buildScopedProductGrid(scopedState),
        ),
      ],
    );
  }

  Widget _buildGlobalSearchResults() {
    return Column(
      children: [
        // Global search header (if we switched from scoped)
        if (_hasContext && _showGlobalResults)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'All Products',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Global results with infinite scroll
        Expanded(
          child: InfiniteScrollProductGrid(query: _searchController.text),
        ),
      ],
    );
  }

  Widget _buildScopedProductGrid(ScopedSearchState state) {
    if (state.isLoading && state.products.isEmpty) {
      return _buildScopedLoadingGrid();
    }

    if (state.hasError && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search failed',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              state.error ?? 'Unknown error',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _expandToGlobalSearch,
              child: const Text('Search All Products'),
            ),
          ],
        ),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No products found in ${widget.contextName ?? 'this category'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or search all products',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _expandToGlobalSearch,
              child: const Text('Search All Products'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: state.products.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.products.length) {
          // Load more indicator
          if (state.isLoadingMore) {
            return const Center(child: CircularProgressIndicator());
          } else {
            // Trigger load more
            Future.microtask(() {
              final scopedActions = ref.read(scopedSearchActionsProvider);
              scopedActions.loadMore();
            });
            return const SizedBox.shrink();
          }
        }

        final product = state.products[index];
        return CleanProductCard(
          product: product,
          onTap: () => context.push('/clean/product/${product.id}'),
        );
      },
    );
  }

  /// Enhanced loading grid for scoped search (same as product listing)
  Widget _buildScopedLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: 6, // Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return _buildShimmerPlaceholder();
      },
    );
  }

  /// Builds animated shimmer placeholder (same as CleanProductGrid)
  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder with shimmer
          AspectRatio(
            aspectRatio: 1,
            child: _ShimmerBox(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),

          // Content placeholders
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weight placeholder
                const _ShimmerBox(
                  width: 40,
                  height: 10,
                ),

                const SizedBox(height: 8),

                // Name placeholder
                const _ShimmerBox(
                  width: double.infinity,
                  height: 12,
                ),

                const SizedBox(height: 4),

                const _ShimmerBox(
                  width: 100,
                  height: 12,
                ),

                const SizedBox(height: 12),

                // Price and button placeholder
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShimmerBox(
                      width: 60,
                      height: 16,
                    ),

                    _ShimmerBox(
                      width: 60,
                      height: 32,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated shimmer box for search loading states
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const _ShimmerBox({
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
              colors: [
                Colors.grey[200]!,
                Colors.grey[100]!,
                Colors.grey[200]!,
              ],
            ),
          ),
        );
      },
    );
  }
}
