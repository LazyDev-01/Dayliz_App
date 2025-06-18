import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/paginated_product_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/product/clean_product_grid.dart';
import '../../../navigation/routes.dart';

/// Clean product listing screen with optimized paginated architecture
/// Features: RepaintBoundary optimization, smart state management, context-aware search
/// Supports both single subcategory and virtual categories (multiple subcategories)
class CleanProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subcategoryId;
  final List<String>? subcategoryIds; // For virtual categories
  final String? searchQuery;
  final String? title;
  final bool isVirtual; // Indicates if this is a virtual category

  const CleanProductListingScreen({
    Key? key,
    this.categoryId,
    this.subcategoryId,
    this.subcategoryIds,
    this.searchQuery,
    this.title,
    this.isVirtual = false,
  }) : super(key: key);

  @override
  ConsumerState<CleanProductListingScreen> createState() => _CleanProductListingScreenState();
}

class _CleanProductListingScreenState extends ConsumerState<CleanProductListingScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('CleanProductListingScreen: Initialized with new paginated architecture');
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
    // Watch the appropriate provider based on screen type
    final state = _getProductsState();

    return Scaffold(
      appBar: UnifiedAppBars.withSearch(
        title: _getScreenTitle(),
        onSearchPressed: _openScopedSearch,
        backButtonType: BackButtonType.previousPage,
        fallbackRoute: '/home',
      ),
      body: _buildContent(state),
    );
  }

  /// Get the appropriate products state based on screen configuration
  PaginatedProductsState _getProductsState() {
    debugPrint('📱 PRODUCT_LISTING: ========== PROVIDER SELECTION DEBUG ==========');
    debugPrint('📱 PRODUCT_LISTING: isVirtual: ${widget.isVirtual}');
    debugPrint('📱 PRODUCT_LISTING: subcategoryIds: ${widget.subcategoryIds}');
    debugPrint('📱 PRODUCT_LISTING: subcategoryId: ${widget.subcategoryId}');
    debugPrint('📱 PRODUCT_LISTING: categoryId: ${widget.categoryId}');
    debugPrint('📱 PRODUCT_LISTING: title: ${widget.title}');

    // Handle virtual categories (multiple subcategories)
    if (widget.isVirtual && widget.subcategoryIds != null && widget.subcategoryIds!.isNotEmpty) {
      debugPrint('📱 PRODUCT_LISTING: Using multiple subcategories provider');
      debugPrint('📱 PRODUCT_LISTING: Subcategory IDs: ${widget.subcategoryIds}');
      return ref.watch(paginatedProductsByMultipleSubcategoriesProvider(widget.subcategoryIds!));
    }

    // Handle single subcategory
    if (widget.subcategoryId != null) {
      debugPrint('📱 PRODUCT_LISTING: Using single subcategory provider');
      debugPrint('📱 PRODUCT_LISTING: Subcategory ID: ${widget.subcategoryId}');
      return ref.watch(paginatedProductsBySubcategoryProvider(widget.subcategoryId!));
    }

    // Handle category
    if (widget.categoryId != null) {
      debugPrint('📱 PRODUCT_LISTING: Using category provider');
      debugPrint('📱 PRODUCT_LISTING: Category ID: ${widget.categoryId}');
      return ref.watch(paginatedProductsByCategoryProvider(widget.categoryId!));
    }

    // Handle search
    if (widget.searchQuery != null) {
      debugPrint('📱 PRODUCT_LISTING: Using search provider');
      debugPrint('📱 PRODUCT_LISTING: Search query: ${widget.searchQuery}');
      return ref.watch(paginatedSearchProductsProvider(widget.searchQuery!));
    }

    // Default to all products
    debugPrint('📱 PRODUCT_LISTING: Using all products provider (default)');
    return ref.watch(paginatedAllProductsProvider);
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

  /// Load more products for infinite scroll
  void _loadMoreProducts() {
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

  Widget _buildContent(PaginatedProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return _buildProductsSkeleton();
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () {
          // Trigger refresh through the provider
          if (widget.subcategoryId != null) {
            ref.read(paginatedProductsBySubcategoryProvider(widget.subcategoryId!).notifier).refreshProducts();
          } else if (widget.categoryId != null) {
            ref.read(paginatedProductsByCategoryProvider(widget.categoryId!).notifier).refreshProducts();
          } else if (widget.searchQuery != null) {
            ref.read(paginatedSearchProductsProvider(widget.searchQuery!).notifier).refreshProducts();
          } else {
            ref.read(paginatedAllProductsProvider.notifier).refreshProducts();
          }
        },
      );
    }

    if (state.isEmpty) {
      return _buildEmptyState();
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