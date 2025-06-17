import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import 'clean_product_card.dart';

/// A grid of product cards that dynamically adapts to screen size
/// Optimized with RepaintBoundary and infinite scroll support
class CleanProductGrid extends StatefulWidget {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const CleanProductGrid({
    Key? key,
    required this.products,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
    this.onRetry,
    this.onLoadMore,
    this.padding = const EdgeInsets.all(12),
    this.physics,
    this.shrinkWrap = false,
  }) : super(key: key);

  @override
  State<CleanProductGrid> createState() => _CleanProductGridState();
}

class _CleanProductGridState extends State<CleanProductGrid> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore != null &&
        widget.hasMore &&
        !widget.isLoadingMore &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      // Load more when user is 300px from bottom (earlier trigger for smoother UX)
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildCurrentState(context),
    );
  }

  Widget _buildCurrentState(BuildContext context) {
    if (widget.isLoading && widget.products.isEmpty) {
      return _buildLoadingGrid();
    }

    if (widget.errorMessage != null && widget.products.isEmpty) {
      return _buildErrorState(context);
    }

    if (widget.products.isEmpty) {
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

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                padding: widget.padding,
                physics: widget.physics,
                shrinkWrap: widget.shrinkWrap,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.55, // Our 1:1.8 aspect ratio
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                itemCount: widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return RepaintBoundary(
                    key: ValueKey(product.id),
                    child: Semantics(
                      label: 'Product: ${product.name}, Price: ₹${product.discountedPrice.toStringAsFixed(2)}',
                      hint: 'Double tap to view product details',
                      button: true,
                      child: CleanProductCard(
                        product: product,
                        onTap: () => _navigateToProductDetails(context, product),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Progressive loading indicator at bottom
            if (widget.isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Loading more products...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// Builds a loading state with shimmer placeholders
  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: widget.padding,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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

  /// Builds a shimmer placeholder for loading state with animation
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
            child: const _ShimmerBox(
              borderRadius: BorderRadius.vertical(
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

  /// Builds an error state with retry button
  Widget _buildErrorState(BuildContext context) {
    return Semantics(
      label: 'Error loading products: ${widget.errorMessage ?? 'An error occurred'}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                label: 'Error icon',
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.errorMessage ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.onRetry != null)
                Semantics(
                  label: 'Retry loading products',
                  hint: 'Double tap to retry loading products',
                  button: true,
                  child: ElevatedButton(
                    onPressed: widget.onRetry,
                    child: const Text('Retry'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an empty state when no products are available
  Widget _buildEmptyState() {
    return Semantics(
      label: 'No products found',
      hint: 'There are currently no products available in this category',
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                color: Colors.grey,
                size: 48,
                semanticLabel: 'Empty basket icon',
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

/// Animated shimmer box for loading states
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
