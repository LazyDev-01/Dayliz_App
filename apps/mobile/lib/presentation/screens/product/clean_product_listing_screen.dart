import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../providers/paginated_product_providers.dart';
import '../../providers/product_filter_provider.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/inline_error_widget.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/common/floating_cart_button.dart';
import '../../widgets/product/clean_product_grid.dart';
import '../../widgets/product/horizontal_filter_bar.dart';
import '../../widgets/product/active_filter_chips.dart';
import '../../../navigation/routes.dart';

/// Clean product listing screen with optimized paginated architecture
/// Features: RepaintBoundary optimization, smart state management, context-aware search
/// Supports both single subcategory and virtual categories (multiple subcategories)
/// Now includes advanced filtering and sorting capabilities
class CleanProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subcategoryId;
  final List<String>? subcategoryIds; // For virtual categories
  final String? searchQuery;
  final String? title;
  final bool isVirtual; // Indicates if this is a virtual category
  final bool enableFiltering; // Enable advanced filtering UI

  const CleanProductListingScreen({
    Key? key,
    this.categoryId,
    this.subcategoryId,
    this.subcategoryIds,
    this.searchQuery,
    this.title,
    this.isVirtual = false,
    this.enableFiltering = false, // Default to disabled for backward compatibility
  }) : super(key: key);

  @override
  ConsumerState<CleanProductListingScreen> createState() => _CleanProductListingScreenState();
}

class _CleanProductListingScreenState extends ConsumerState<CleanProductListingScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    debugPrint('CleanProductListingScreen: Initialized with filtering=${widget.enableFiltering}');

    // Initialize filtered products if filtering is enabled
    if (widget.enableFiltering) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeFilteredProducts();
      });
    }
  }

  /// Initialize filtered products based on screen context
  void _initializeFilteredProducts() {
    final filterNotifier = ref.read(productFilterProvider.notifier);

    // Set initial context-based filters and load products
    if (widget.searchQuery != null) {
      filterNotifier.updateSearch(widget.searchQuery);
    } else {
      // For non-search screens, trigger initial load with empty filter
      filterNotifier.applyFiltersImmediately();
    }
  }

  void _openScopedSearch() {
    debugPrint('🔍 Opening context-aware search for subcategory: ${widget.subcategoryId}, category: ${widget.categoryId}');

    CleanRoutes.navigateToContextSearch(
      context,
      subcategoryId: widget.subcategoryId,
      categoryId: widget.categoryId,
      contextName: _getScreenTitle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the appropriate provider based on screen type and filtering
    final state = widget.enableFiltering ? _getFilteredProductsState() : _getProductsState();

    return Scaffold(
      appBar: UnifiedAppBars.withSearch(
        title: _getScreenTitle(),
        onSearchPressed: _openScopedSearch,
        backButtonType: BackButtonType.previousPage,
        fallbackRoute: '/home',
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter and sort bar (only if filtering is enabled)
              if (widget.enableFiltering) ...[
                const HorizontalFilterBar(),
                const ActiveFilterChips(),
              ],

              // Main content
              Expanded(
                child: _buildContent(state),
              ),
            ],
          ),
          // Floating cart button - appears when cart has items
          const FloatingCartButton(),
        ],
      ),
    );
  }

  /// Get the appropriate products state based on screen configuration
  PaginatedProductsState _getProductsState() {
    // Handle virtual categories (multiple subcategories)
    if (widget.isVirtual && widget.subcategoryIds != null && widget.subcategoryIds!.isNotEmpty) {
      return ref.watch(paginatedProductsByMultipleSubcategoriesProvider(widget.subcategoryIds!));
    }

    // Handle single subcategory
    if (widget.subcategoryId != null) {
      return ref.watch(paginatedProductsBySubcategoryProvider(widget.subcategoryId!));
    }

    // Handle category
    if (widget.categoryId != null) {
      return ref.watch(paginatedProductsByCategoryProvider(widget.categoryId!));
    }

    // Handle search
    if (widget.searchQuery != null) {
      return ref.watch(paginatedSearchProductsProvider(widget.searchQuery!));
    }

    // Default to all products
    return ref.watch(paginatedAllProductsProvider);
  }

  /// Get filtered products state (converts FilteredProductsState to PaginatedProductsState)
  PaginatedProductsState _getFilteredProductsState() {
    final filteredState = ref.watch(filteredProductsProvider);

    // Convert FilteredProductsState to PaginatedProductsState for compatibility
    return PaginatedProductsState(
      products: filteredState.products.toIList(), // Convert to IList
      isLoading: filteredState.isLoading,
      isLoadingMore: filteredState.isLoadingMore,
      hasReachedEnd: !filteredState.hasMore,
      errorMessage: filteredState.errorMessage,
      // Note: PaginatedProductsState doesn't have totalCount, it uses meta instead
    );
  }

  String _getScreenTitle() {
    if (widget.title != null) return widget.title!;
    if (widget.searchQuery != null) return 'Search Results';
    if (widget.subcategoryId != null) return 'Products';
    if (widget.categoryId != null) return 'Category Products';
    return 'All Products';
  }

  /// Refresh products with pull-to-refresh
  Future<void> _refreshProducts() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      if (widget.enableFiltering) {
        // For filtered products, re-apply current filters
        final currentFilter = ref.read(productFilterProvider);
        await ref.read(filteredProductsProvider.notifier).applyFilters(currentFilter);
      } else {
        // Use original pagination providers
        if (widget.subcategoryId != null) {
          await ref.read(paginatedProductsBySubcategoryProvider(widget.subcategoryId!).notifier).refreshProducts();
        } else if (widget.categoryId != null) {
          await ref.read(paginatedProductsByCategoryProvider(widget.categoryId!).notifier).refreshProducts();
        } else if (widget.searchQuery != null) {
          await ref.read(paginatedSearchProductsProvider(widget.searchQuery!).notifier).refreshProducts();
        } else {
          await ref.read(paginatedAllProductsProvider.notifier).refreshProducts();
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// Load more products for infinite scroll
  void _loadMoreProducts() {
    if (widget.enableFiltering) {
      // For filtered products, load more with current filters
      ref.read(filteredProductsProvider.notifier).loadMore();
    } else {
      // Use original pagination providers
      if (widget.subcategoryId != null) {
        ref.read(paginatedProductsBySubcategoryProvider(widget.subcategoryId!).notifier).loadMoreProducts();
      } else if (widget.categoryId != null) {
        ref.read(paginatedProductsByCategoryProvider(widget.categoryId!).notifier).loadMoreProducts();
      } else if (widget.searchQuery != null) {
        ref.read(paginatedSearchProductsProvider(widget.searchQuery!).notifier).loadMoreProducts();
      } else {
        ref.read(paginatedAllProductsProvider.notifier).loadMoreProducts();
      }
    }
  }

  Widget _buildContent(PaginatedProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return _buildProductsSkeleton();
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return NetworkErrorWidgets.connectionProblem(
        onRetry: () => _refreshProducts(), // Use unified refresh method
      );
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    // Show skeleton loading during refresh
    if (_isRefreshing) {
      return RefreshIndicator(
        onRefresh: _refreshProducts,
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: ProductGridSkeleton(itemCount: 6),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: CleanProductGrid(
        products: state.products.toList(),
        isLoading: state.isLoading,
        isLoadingMore: state.isLoadingMore,
        hasMore: !state.hasReachedEnd,
        errorMessage: state.errorMessage,
        onRetry: () => _refreshProducts(),
        onLoadMore: _loadMoreProducts,
        padding: const EdgeInsets.all(16),
      ),
    );
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

  /// Build skeleton loading for products grid
  Widget _buildProductsSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: ProductGridSkeleton(
        columns: 2,
        itemCount: 8, // Show 8 skeleton cards
      ),
    );
  }
}