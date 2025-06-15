import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../providers/paginated_search_providers.dart';
import '../common/error_state.dart';
import '../product/product_card.dart';

/// Infinite scroll product grid with lazy loading
class InfiniteScrollProductGrid extends ConsumerStatefulWidget {
  final String query;

  const InfiniteScrollProductGrid({
    Key? key,
    required this.query,
  }) : super(key: key);

  @override
  ConsumerState<InfiniteScrollProductGrid> createState() => _InfiniteScrollProductGridState();
}

class _InfiniteScrollProductGridState extends ConsumerState<InfiniteScrollProductGrid> {
  final ScrollController _scrollController = ScrollController();
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _lastQuery = widget.query;

    // Start initial search
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.query.isNotEmpty) {
        _performSearch();
      }
    });
  }

  @override
  void didUpdateWidget(InfiniteScrollProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != oldWidget.query && widget.query != _lastQuery) {
      _lastQuery = widget.query;
      // Delay the search to avoid modifying provider during build
      Future.microtask(() {
        if (widget.query.isNotEmpty) {
          _performSearch();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final actions = ref.read(paginatedSearchActionsProvider);
    actions.search(widget.query);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      // User is near bottom, load more (300px threshold for smoother UX)
      _loadMore();
    }
  }

  void _loadMore() {
    final state = ref.read(activePaginatedSearchProvider);
    if (!state.isLoadingMore && state.hasMore) {
      final actions = ref.read(paginatedSearchActionsProvider);
      actions.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(activePaginatedSearchProvider);

    // Show enhanced skeleton loading for initial load (same as product listing)
    if (searchState.isLoading && searchState.products.isEmpty) {
      return _buildSearchLoadingGrid();
    }

    // Show error state if no products and has error
    if (searchState.hasError && searchState.products.isEmpty) {
      return _buildErrorState(searchState.error!);
    }

    // Show no results if search completed but no products
    if (searchState.isEmpty && !searchState.isLoading) {
      return _buildNoResults();
    }

    // Show products with infinite scroll
    return _buildProductGrid(searchState);
  }

  Widget _buildProductGrid(PaginatedSearchState state) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = state.products[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/clean/product/${product.id}'),
                );
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
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Loading more products...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // End of results indicator
        if (!state.hasMore && state.products.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You\'ve seen all results for "${widget.query}"',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Load more error
        if (state.hasError && state.products.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load more results',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final actions = ref.read(paginatedSearchActionsProvider);
                        actions.retry();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return ErrorState(
      message: error,
      onRetry: () {
        final actions = ref.read(paginatedSearchActionsProvider);
        actions.retry();
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "${widget.query}"',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try using different keywords or check for typos',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final actions = ref.read(paginatedSearchActionsProvider);
              actions.clear();
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  /// Enhanced loading grid with animated shimmer (same as product listing)
  Widget _buildSearchLoadingGrid() {
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

/// Performance metrics widget for debugging
class SearchPerformanceIndicator extends ConsumerWidget {
  const SearchPerformanceIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activePaginatedSearchProvider);
    
    if (state.products.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.green[50],
      child: Row(
        children: [
          Icon(Icons.speed, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(
            'Loaded ${state.products.length} products (Page ${state.currentPage})',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (state.hasMore)
            Text(
              'More available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
              ),
            ),
        ],
      ),
    );
  }
}
