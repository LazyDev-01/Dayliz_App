import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../providers/home_providers.dart';
import '../../providers/paginated_product_providers.dart';
import '../../providers/banner_providers.dart';
import '../../widgets/product/clean_product_card.dart';
import '../../widgets/home/home_categories_section.dart';
import '../../widgets/home/enhanced_banner_carousel.dart';
import '../../../domain/entities/product.dart';
import '../../providers/user_profile_providers.dart';

/// A clean architecture implementation of the home screen
/// Updated with compact product cards and improved category alignment
/// Converted to ConsumerWidget for better performance and caching
class CleanHomeScreen extends ConsumerWidget {
  const CleanHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize auto-load provider to ensure addresses are loaded
    ref.read(autoLoadUserProfileProvider);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context, ref),
    );
  }







  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return UnifiedAppBars.homeScreen(
      onSearchTap: () => context.push('/search'),
      onProfileTap: () => context.push('/profile'),
      searchHint: 'Search for products...',
      enableCloudAnimation: false, // Disable cloud animation
      cloudType: CloudAnimationType.peaceful, // Peaceful clouds for home screen
      cloudOpacity: 0.45, // Subtle but visible clouds
      cloudColor: Colors.white, // Pure white clouds
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    // Watch featured products
    final featuredProductsState = ref.watch(featuredProductsNotifierProvider);
    final saleProductsState = ref.watch(saleProductsNotifierProvider);

    // Check if we need to load data
    final bool needsLoading = featuredProductsState.products.isEmpty &&
                              saleProductsState.products.isEmpty &&
                              !featuredProductsState.isLoading &&
                              !saleProductsState.isLoading;

    if (needsLoading) {
      // Trigger loading only if data is empty and not already loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (featuredProductsState.products.isEmpty && !featuredProductsState.isLoading) {
          ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts(limit: 10);
        }
        if (saleProductsState.products.isEmpty && !saleProductsState.isLoading) {
          ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts(limit: 10);
        }
      });
    }

    // Show loading skeleton if both are loading or empty
    if ((featuredProductsState.isLoading && featuredProductsState.products.isEmpty) ||
        (saleProductsState.isLoading && saleProductsState.products.isEmpty)) {
      return _buildHomeScreenSkeleton();
    }

    // Show error if both have errors
    if (featuredProductsState.errorMessage != null && saleProductsState.errorMessage != null) {
      return ErrorState(
        message: 'Failed to load home data',
        onRetry: () {
          ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts(limit: 10);
          ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts(limit: 10);
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(ref),
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        slivers: [
            // Banner carousel placeholder
            _buildBannerPlaceholder(),

            // Categories section with improved alignment
            const SliverToBoxAdapter(
              child: HomeCategoriesSection(),
            ),

            // Featured products section with compact cards
            _buildFeaturedProductsSection(context, ref),

            // Sale products section with compact cards
            _buildSaleProductsSection(context, ref),

            // All products section with pagination
            _buildAllProductsSection(context, ref),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
      ),
    );
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh(WidgetRef ref) async {
    try {
      // Create a list of futures for parallel execution
      final List<Future> refreshFutures = [];

      // Refresh banners
      refreshFutures.add(
        ref.read(bannerNotifierProvider.notifier).refreshBanners()
      );

      // Refresh featured products
      refreshFutures.add(
        ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts(limit: 10)
      );

      // Refresh sale products
      refreshFutures.add(
        ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts(limit: 10)
      );

      // Refresh all products (first page)
      refreshFutures.add(
        ref.read(paginatedAllProductsProvider.notifier).refreshProducts()
      );

      // Wait for all refresh operations to complete
      await Future.wait(refreshFutures);

      // Add a small delay for better UX (prevents too quick refresh)
      await Future.delayed(const Duration(milliseconds: 300));

    } catch (e) {
      // Handle refresh errors gracefully
      debugPrint('Refresh error: $e');
    }
  }

  /// Build skeleton loading for home screen
  Widget _buildHomeScreenSkeleton() {
    return CustomScrollView(
      slivers: [
        // Banner skeleton
        SliverToBoxAdapter(
          child: Container(
            height: 180,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: const BannerSkeleton(),
          ),
        ),

        // Categories skeleton
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title skeleton
                SkeletonContainer(
                  width: 150,
                  height: 20,
                ),
                SizedBox(height: 16),
                // Categories list skeleton
                CategoryListSkeleton(count: 5),
              ],
            ),
          ),
        ),

        // Featured products skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonContainer(
                      width: 140,
                      height: 18,
                    ),
                    SkeletonContainer(
                      width: 60,
                      height: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Products list skeleton
                ProductListSkeleton(count: 4),
              ],
            ),
          ),
        ),

        // Sale products skeleton
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title skeleton
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonContainer(
                      width: 80,
                      height: 18,
                    ),
                    SkeletonContainer(
                      width: 60,
                      height: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Products list skeleton
                ProductListSkeleton(count: 4),
              ],
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildBannerPlaceholder() {
    return SliverToBoxAdapter(
      child: Container(
        // Added top margin for proper spacing from app bar
        margin: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: const EnhancedBannerCarousel(
          height: 200,
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection(BuildContext context, WidgetRef ref) {
    final featuredProductsState = ref.watch(featuredProductsNotifierProvider);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/products?featured=true'),
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 32,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Featured Products Coming Soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildFeaturedProductsList(FeaturedProductsState state) {
  //   // Removed - using placeholder for now
  // }

  Widget _buildSaleProductsSection(BuildContext context, WidgetRef ref) {
    final saleProductsState = ref.watch(saleProductsNotifierProvider);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'On Sale',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/products?sale=true'),
                  child: const Text('See All'),
                ),
              ],
            ),
          ),
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 32,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sale Products Coming Soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the all products section with grid layout and pagination
  Widget _buildAllProductsSection(BuildContext context, WidgetRef ref) {
    final allProductsState = ref.watch(paginatedAllProductsProvider);

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Products',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/clean/products'),
                  child: const Text('See All'),
                ),
              ],
            ),
          ),

          // Products grid
          _buildAllProductsContent(allProductsState),
        ],
      ),
    );
  }

  /// Builds the content based on all products state
  Widget _buildAllProductsContent(PaginatedProductsState state) {
    if (state.isLoading && state.products.isEmpty) {
      return _buildAllProductsLoading();
    }

    if (state.errorMessage != null && state.products.isEmpty) {
      return _buildAllProductsError(state.errorMessage!);
    }

    if (state.products.isEmpty) {
      return _buildAllProductsEmpty();
    }

    return _buildAllProductsGrid(state.products.toList());
  }

  /// Builds the products grid with pagination
  Widget _buildAllProductsGrid(List<Product> products) {
    // Show only first 14 products initially
    final displayProducts = products.take(14).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.56, // Fixed to match card's 1:1.8 aspect ratio
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: displayProducts.length,
        itemBuilder: (context, index) {
          final product = displayProducts[index];
          return CleanProductCard(
            product: product,
            onTap: () => context.push('/clean/product/${product.id}'),
          );
        },
      ),
    );
  }

  /// Builds loading state for all products
  Widget _buildAllProductsLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ProductGridSkeleton(
        columns: 2,
        itemCount: 14,
      ),
    );
  }

  /// Builds error state for all products
  Widget _buildAllProductsError(String message) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load products',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds empty state for all products
  Widget _buildAllProductsEmpty() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 32,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No products available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildSaleProductsList(SaleProductsState state) {
  //   // Removed - using placeholder for now
  // }

  // Product-related methods removed - using placeholders for now
  // Widget _buildProductsLoading() { ... }
  // Widget _buildProductsError(String message) { ... }
  // Widget _buildProductsEmpty(String message) { ... }


}



