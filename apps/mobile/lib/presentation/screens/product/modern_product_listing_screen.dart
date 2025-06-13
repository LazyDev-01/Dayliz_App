import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../core/models/pagination_models.dart';
import '../../../domain/entities/product.dart';
import '../../providers/paginated_product_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/product/clean_product_card.dart';

/// Modern product listing screen with infinite scroll pagination
class ModernProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subcategoryId;
  final String? searchQuery;
  final String? title;

  const ModernProductListingScreen({
    super.key,
    this.categoryId,
    this.subcategoryId,
    this.searchQuery,
    this.title,
  });

  @override
  ConsumerState<ModernProductListingScreen> createState() => _ModernProductListingScreenState();
}

class _ModernProductListingScreenState extends ConsumerState<ModernProductListingScreen> {
  final ScrollController _scrollController = ScrollController();
  late final PaginatedProductsNotifier _notifier;
  String _sortBy = 'created_at';
  bool _ascending = false;

  @override
  void initState() {
    super.initState();
    _setupScrollListener();
    _initializeNotifier();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      // Load more when user scrolls to 80% of the list
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
        _loadMoreProducts();
      }
    });
  }

  void _initializeNotifier() {
    // Get the appropriate notifier based on the screen type
    if (widget.subcategoryId != null) {
      _notifier = ref.read(paginatedProductsBySubcategoryProvider(widget.subcategoryId!).notifier);
    } else if (widget.categoryId != null) {
      _notifier = ref.read(paginatedProductsByCategoryProvider(widget.categoryId!).notifier);
    } else if (widget.searchQuery != null) {
      _notifier = ref.read(paginatedSearchProductsProvider(widget.searchQuery!).notifier);
    } else {
      _notifier = ref.read(paginatedAllProductsProvider.notifier);
    }
  }

  void _loadMoreProducts() {
    _notifier.loadMoreProducts();
  }

  Future<void> _refreshProducts() async {
    await _notifier.refreshProducts();
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SortOptionsBottomSheet(
        currentSortBy: _sortBy,
        currentAscending: _ascending,
        onSortChanged: (sortBy, ascending) {
          setState(() {
            _sortBy = sortBy;
            _ascending = ascending;
          });
          _notifier.updateSort(sortBy: sortBy, ascending: ascending);
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on screen type
    final state = widget.subcategoryId != null
        ? ref.watch(paginatedProductsBySubcategoryProvider(widget.subcategoryId!))
        : widget.categoryId != null
            ? ref.watch(paginatedProductsByCategoryProvider(widget.categoryId!))
            : widget.searchQuery != null
                ? ref.watch(paginatedSearchProductsProvider(widget.searchQuery!))
                : ref.watch(paginatedAllProductsProvider);

    return Scaffold(
      appBar: UnifiedAppBars.withSearch(
        title: _getScreenTitle(),
        onSearchPressed: () {
          // TODO: Implement search functionality
          debugPrint('Search pressed');
        },
        backButtonType: BackButtonType.previousPage,
        fallbackRoute: '/home',
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            tooltip: 'Sort products',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        child: _buildBody(state),
      ),
    );
  }

  String _getScreenTitle() {
    if (widget.title != null) return widget.title!;
    if (widget.searchQuery != null) return 'Search Results';
    if (widget.subcategoryId != null) return 'Products';
    if (widget.categoryId != null) return 'Category Products';
    return 'All Products';
  }

  Widget _buildBody(PaginatedProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const LoadingIndicator(message: 'Loading products...');
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: _refreshProducts,
      );
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductGrid(state);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.searchQuery != null ? Icons.search_off : Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            widget.searchQuery != null
                ? 'No products found for "${widget.searchQuery}"'
                : 'No products available',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          if (widget.searchQuery != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid(PaginatedProductsState state) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Product count and sort info
        SliverToBoxAdapter(
          child: _buildProductInfo(state),
        ),
        
        // Product grid
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < state.products.length) {
                  return CleanProductCard(product: state.products[index]);
                }
                return null;
              },
              childCount: state.products.length,
            ),
          ),
        ),
        
        // Loading more indicator
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        
        // End of list indicator
        if (state.hasReachedEnd && state.products.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'You\'ve reached the end!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductInfo(PaginatedProductsState state) {
    final meta = state.meta;
    if (meta == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${state.products.length} of ${meta.totalItems} products',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Page ${meta.currentPage} of ${meta.totalPages}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for sort options
class _SortOptionsBottomSheet extends StatelessWidget {
  final String currentSortBy;
  final bool currentAscending;
  final Function(String sortBy, bool ascending) onSortChanged;

  const _SortOptionsBottomSheet({
    required this.currentSortBy,
    required this.currentAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      {'key': 'created_at', 'label': 'Newest First', 'ascending': false},
      {'key': 'created_at', 'label': 'Oldest First', 'ascending': true},
      {'key': 'name', 'label': 'Name A-Z', 'ascending': true},
      {'key': 'name', 'label': 'Name Z-A', 'ascending': false},
      {'key': 'price', 'label': 'Price Low to High', 'ascending': true},
      {'key': 'price', 'label': 'Price High to Low', 'ascending': false},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort Products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...sortOptions.map((option) {
            final isSelected = currentSortBy == option['key'] && 
                              currentAscending == option['ascending'];
            
            return ListTile(
              title: Text(option['label'] as String),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                onSortChanged(option['key'] as String, option['ascending'] as bool);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ],
      ),
    );
  }
}
