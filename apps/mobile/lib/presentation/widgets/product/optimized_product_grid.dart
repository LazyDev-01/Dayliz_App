import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../../core/cache/advanced_cache_manager.dart';
import '../common/skeleton_loaders.dart';

/// High-performance product grid using staggered grid view and immutable collections
class OptimizedProductGrid extends StatelessWidget {
  final IList<Product> products;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const OptimizedProductGrid({
    Key? key,
    required this.products,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.padding = const EdgeInsets.all(12),
    this.physics,
    this.shrinkWrap = false,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingGrid();
    }

    if (errorMessage != null) {
      return _buildErrorState();
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return _buildProductGrid(context);
  }

  /// Build the optimized product grid
  Widget _buildProductGrid(BuildContext context) {
    return Padding(
      padding: padding,
      child: MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return RepaintBoundary(
            key: ValueKey(product.id),
            child: _OptimizedProductCard(
              product: product,
              onTap: () => _navigateToProduct(context, product),
            ),
          );
        },
      ),
    );
  }

  /// Build loading state with skeleton grid
  Widget _buildLoadingGrid() {
    return Padding(
      padding: padding,
      child: MasonryGridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6, // Show 6 skeleton items
        itemBuilder: (context, index) {
          return const ProductCardSkeleton();
        },
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Something went wrong',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey,
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
    );
  }

  /// Navigate to product details
  void _navigateToProduct(BuildContext context, Product product) {
    context.push('/product/${product.id}');
  }
}

/// Optimized product card with advanced caching
class _OptimizedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _OptimizedProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageSection(),
            _buildContentSection(),
          ],
        ),
      ),
    );
  }

  /// Build optimized image section
  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CachedNetworkImage(
          imageUrl: product.mainImageUrl,
          fit: BoxFit.cover,
          cacheManager: AdvancedCacheManager.imageCache,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[200],
            child: const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.grey,
              size: 32,
            ),
          ),
          // Performance optimizations
          memCacheWidth: 300,
          memCacheHeight: 300,
          maxWidthDiskCache: 600,
          maxHeightDiskCache: 600,
        ),
      ),
    );
  }

  /// Build content section
  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (product.description.isNotEmpty) ...[
            Text(
              product.description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '₹${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              _buildAddButton(),
            ],
          ),
        ],
      ),
    );
  }

  /// Build optimized add button
  Widget _buildAddButton() {
    return Container(
      height: 32,
      width: 32,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
