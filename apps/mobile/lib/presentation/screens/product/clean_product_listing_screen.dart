import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/paginated_product_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/product/clean_product_grid.dart';

class CleanProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subcategoryId;
  final String? searchQuery;
  final String? title;

  const CleanProductListingScreen({
    Key? key,
    this.categoryId,
    this.subcategoryId,
    this.searchQuery,
    this.title,
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
          debugPrint('Search icon tapped - functionality to be implemented');
        },
        backButtonType: BackButtonType.previousPage,
        fallbackRoute: '/home',
      ),
      body: _buildContent(state),
    );
  }

  String _getScreenTitle() {
    if (widget.title != null) return widget.title!;
    if (widget.searchQuery != null) return 'Search Results';
    if (widget.subcategoryId != null) return 'Products';
    if (widget.categoryId != null) return 'Category Products';
    return 'All Products';
  }

  Widget _buildContent(PaginatedProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return const LoadingIndicator(message: 'Loading products...');
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

    return CleanProductGrid(
      products: state.products.toList(),
      padding: const EdgeInsets.all(16),
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


}