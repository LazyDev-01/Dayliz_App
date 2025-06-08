import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';

import '../../../domain/entities/product.dart';
import '../../providers/optimized_product_providers.dart';
import '../../widgets/product/optimized_product_grid.dart';
import '../../widgets/common/common_app_bars.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../../core/performance/performance_monitor.dart';

/// High-performance product listing screen using optimized components
class OptimizedProductListingScreen extends ConsumerStatefulWidget {
  final String? subcategoryId;
  final String? searchQuery;
  final String title;

  const OptimizedProductListingScreen({
    Key? key,
    this.subcategoryId,
    this.searchQuery,
    this.title = 'Products',
  }) : super(key: key);

  @override
  ConsumerState<OptimizedProductListingScreen> createState() => 
      _OptimizedProductListingScreenState();
}

class _OptimizedProductListingScreenState 
    extends ConsumerState<OptimizedProductListingScreen> 
    with PerformanceTrackingMixin {
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    
    // Track screen initialization performance
    PerformanceMonitor.instance.startTimer(PerformanceMetrics.screenTransition);
    
    // Initialize search query if provided
    if (widget.searchQuery != null) {
      _currentSearchQuery = widget.searchQuery!;
      _searchController.text = _currentSearchQuery;
    }
    
    // Track screen load completion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PerformanceMonitor.instance.endTimer(PerformanceMetrics.screenTransition);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CommonAppBars.withBackButton(
        title: widget.title,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
            tooltip: 'Refresh Products',
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.searchQuery == null) _buildSearchBar(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  /// Build search bar for dynamic searching
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _currentSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  /// Build optimized product list
  Widget _buildProductList() {
    // Determine which provider to use based on the screen type
    late final AsyncValue<IList<Product>> productsAsync;

    if (_currentSearchQuery.isNotEmpty) {
      // Use search provider with debouncing
      productsAsync = ref.watch(optimizedSearchProductsProvider(_currentSearchQuery));
    } else if (widget.subcategoryId != null) {
      // Use subcategory provider
      productsAsync = ref.watch(optimizedProductsBySubcategoryProvider(widget.subcategoryId!));
    } else {
      // Use all products provider
      productsAsync = ref.watch(optimizedProductsProvider);
    }

    return RefreshIndicator(
      onRefresh: _refreshProducts,
      child: productsAsync.when(
        data: (products) => _buildProductGrid(products),
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
      ),
    );
  }

  /// Build optimized product grid
  Widget _buildProductGrid(IList<Product> products) {
    if (products.isEmpty) {
      return _buildEmptyState();
    }

    // Track product list rendering performance
    return trackOperation(PerformanceMetrics.widgetBuild, () {
      return OptimizedProductGrid(
        products: products,
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      );
    });
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: LoadingIndicator(
        message: 'Loading products...',
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(String error) {
    return ErrorState(
      message: error,
      onRetry: _refreshProducts,
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentSearchQuery.isNotEmpty 
                ? Icons.search_off 
                : Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _currentSearchQuery.isNotEmpty
                ? 'No products found for "${_currentSearchQuery}"'
                : 'No products available',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (_currentSearchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _clearSearch,
              child: const Text('Clear Search'),
            ),
          ],
        ],
      ),
    );
  }

  /// Handle search input changes with debouncing
  void _onSearchChanged(String query) {
    // Track search queries
    if (query.isNotEmpty) {
      PerformanceMonitor.instance.incrementCounter(PerformanceMetrics.searchQueries);
    }

    setState(() {
      _currentSearchQuery = query;
    });
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearchQuery = '';
    });
  }

  /// Refresh products
  Future<void> _refreshProducts() async {
    return trackAsyncOperation(PerformanceMetrics.productListLoad, () async {
      // Invalidate the appropriate provider
      if (_currentSearchQuery.isNotEmpty) {
        ref.invalidate(optimizedSearchProductsProvider(_currentSearchQuery));
      } else if (widget.subcategoryId != null) {
        ref.invalidate(optimizedProductsBySubcategoryProvider(widget.subcategoryId!));
      } else {
        ref.invalidate(optimizedProductsProvider);
      }

      // Wait for the new data to load
      await Future.delayed(const Duration(milliseconds: 100));
    });
  }

  /// Get cross axis count based on screen width
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 3; // Tablet
    } else if (screenWidth > 400) {
      return 2; // Large phone
    } else {
      return 2; // Small phone
    }
  }
}
