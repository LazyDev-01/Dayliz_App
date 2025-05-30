import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import 'clean_product_card.dart';

/// A grid of product cards that dynamically adapts to screen size
class CleanProductGrid extends StatelessWidget {
  final List<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const CleanProductGrid({
    Key? key,
    required this.products,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.padding = const EdgeInsets.all(12),
    this.physics,
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid();
    }

    if (errorMessage != null) {
      return _buildErrorState(context);
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductGrid(context);
  }

  /// Builds the product grid
  Widget _buildProductGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on screen width
        final crossAxisCount = _calculateColumnCount(context);

        return GridView.builder(
          padding: padding,
          physics: physics,
          shrinkWrap: shrinkWrap,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.55, // Our 1:1.8 aspect ratio
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return CleanProductCard(
              product: product,
              onTap: () => _navigateToProductDetails(context, product),
            );
          },
        );
      },
    );
  }

  /// Builds a loading state with shimmer placeholders
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
      ),
      itemCount: 6, // Show 6 shimmer placeholders
      itemBuilder: (context, index) {
        return _buildShimmerPlaceholder();
      },
    );
  }

  /// Builds a shimmer placeholder for loading state
  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
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
                Container(
                  width: 40,
                  height: 10,
                  color: Colors.grey[200],
                ),

                const SizedBox(height: 8),

                // Name placeholder
                Container(
                  width: double.infinity,
                  height: 12,
                  color: Colors.grey[200],
                ),

                const SizedBox(height: 4),

                Container(
                  width: 100,
                  height: 12,
                  color: Colors.grey[200],
                ),

                const SizedBox(height: 12),

                // Price and button placeholder
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      color: Colors.grey[200],
                    ),

                    Container(
                      width: 60,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
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

  /// Builds an error state with retry button
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds an empty state when no products are available
  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_basket_outlined,
              color: Colors.grey,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate the number of columns based on screen width
  int _calculateColumnCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 400) return 2; // Small phones
    if (screenWidth < 600) return 2; // Regular phones
    if (screenWidth < 900) return 3; // Large phones/small tablets
    if (screenWidth < 1200) return 4; // Tablets
    return 5; // Large tablets and beyond
  }

  /// Navigate to product details screen
  void _navigateToProductDetails(BuildContext context, Product product) {
    context.push('/clean/product/${product.id}');
  }
}
