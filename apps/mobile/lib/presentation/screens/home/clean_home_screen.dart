import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/common/inline_error_widget.dart';
import '../../providers/network_providers.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/common/skeleton_loading.dart' as skeleton_loading;
import '../../providers/home_providers.dart';
import '../../providers/paginated_product_providers.dart';
import '../../providers/banner_providers.dart';
import '../../widgets/product/standard_product_card.dart';
import '../../../core/constants/app_colors.dart';

import '../../widgets/home/home_categories_section.dart';
import '../../widgets/home/enhanced_banner_carousel.dart';
import '../../widgets/home/quick_services_section.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/address.dart';
import '../../providers/user_profile_providers.dart';

/// Production-ready home screen implementation with clean architecture
///
/// Features:
/// - Unified collapsible app bar with delivery address and search
/// - Pull-to-refresh functionality with optimistic loading
/// - Skeleton loading states for better UX
/// - Network error handling with retry mechanisms
/// - Responsive product sections with pagination
/// - Performance optimized with proper state management
class CleanHomeScreen extends ConsumerStatefulWidget {
  const CleanHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanHomeScreen> createState() => _CleanHomeScreenState();
}

class _CleanHomeScreenState extends ConsumerState<CleanHomeScreen> {
  bool _isRefreshing = false;
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

  /// Handle scroll events for infinite loading
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more products when near the bottom
      final allProductsState = ref.read(paginatedAllProductsProvider);
      if (!allProductsState.isLoadingMore && !allProductsState.hasReachedEnd) {
        ref.read(paginatedAllProductsProvider.notifier).loadMoreProducts();
      }
    }
  }

  /// Ensure data is loaded for home screen sections
  void _ensureDataLoaded(WidgetRef ref) {
    final featuredProductsState = ref.read(featuredProductsNotifierProvider);
    final saleProductsState = ref.read(saleProductsNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!featuredProductsState.hasLoaded && !featuredProductsState.isLoading) {
        ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts(limit: 10);
      }
      if (!saleProductsState.hasLoaded && !saleProductsState.isLoading) {
        ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts(limit: 10);
      }
    });
  }

  /// Check if initial loading is in progress
  bool _isInitialLoading(WidgetRef ref) {
    final featuredProductsState = ref.watch(featuredProductsNotifierProvider);
    final saleProductsState = ref.watch(saleProductsNotifierProvider);

    return (featuredProductsState.isLoading && !featuredProductsState.hasLoaded) ||
           (saleProductsState.isLoading && !saleProductsState.hasLoaded);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize auto-load provider to ensure addresses are loaded
    ref.read(autoLoadUserProfileProvider);

    return Scaffold(
      body: _buildBodyWithCollapsibleAppBar(context, ref),
    );
  }

  /// Builds the body with integrated collapsible app bar using CustomScrollView
  Widget _buildBodyWithCollapsibleAppBar(BuildContext context, WidgetRef ref) {
    // Auto-trigger initial loading for featured and sale products
    _ensureDataLoaded(ref);

    // Show loading skeleton during refresh or initial load
    if (_isRefreshing || _isInitialLoading(ref)) {
      return _buildHomeScreenSkeletonWithAppBar();
    }

    // Use the new connectivity provider to prevent flickering
    final connectivityState = ref.watch(connectivityProvider);

    // Only show network error if explicitly disconnected (not unknown state)
    if (connectivityState.isDisconnected) {
      return CustomScrollView(
        slivers: [
          // Unified app bar with delivery section and search bar
          _buildUnifiedAppBar(context),

          // Network error content
          SliverFillRemaining(
            child: NetworkErrorWidgets.connectionProblem(
              onRetry: () {
                // Refresh connectivity state and retry loading data
                ref.read(connectivityProvider.notifier).refresh();
                _performOptimisticRetry(ref);
              },
            ),
          ),
        ],
      );
    }

    // If internet is available, show content with collapsible app bar
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Unified app bar with delivery section and search bar
          _buildUnifiedAppBar(context),

          // Banner carousel
          _buildBannerPlaceholder(),

          // Quick Services section (Bakery, Laundry, etc.)
          const SliverToBoxAdapter(
            child: QuickServicesSection(),
          ),

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




  /// Builds the unified app bar with delivery section and search bar
  Widget _buildUnifiedAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      snap: false,
      expandedHeight: 112, // Delivery section height when expanded
      collapsedHeight: 56, // Just search bar height when collapsed
      elevation: 2,
      shadowColor: Colors.black26,
      backgroundColor: const Color(0xFFFFD54F), // Zest Yellow background
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,

      // Delivery section in title (fades away on scroll)
      title: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Delivery address
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final defaultAddress = ref.watch(defaultAddressProvider);

                  return GestureDetector(
                    onTap: () => context.push('/addresses'),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Row(
                                children: [
                                  Text(
                                    'Deliver to',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16, // Increased from 14
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                              Text(
                                _getAddressText(defaultAddress),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Profile icon - Better design
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () => context.push('/profile'),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
      titleSpacing: 0,

      // Search bar in bottom (stays pinned)
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          height: 56,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFD54F),
          ),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(12),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(
                      Icons.search_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search for products...',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to format address text for display
  ///
  /// Handles both [Address] entities and Map formats with proper fallbacks
  /// Returns a user-friendly formatted address string
  String _getAddressText(dynamic address) {
    if (address == null) {
      return 'Add delivery address';
    }

    try {
      // Handle Address entity (primary format)
      if (address is Address) {
        final parts = <String>[];

        if (address.addressLine1.isNotEmpty) {
          parts.add(address.addressLine1);
        }

        if (address.city.isNotEmpty) {
          parts.add(address.city);
        }

        if (address.state.isNotEmpty) {
          parts.add(address.state);
        }

        return parts.isNotEmpty ? parts.join(', ') : 'Select delivery address';
      }

      // Handle Map format (legacy support)
      if (address is Map<String, dynamic>) {
        final street = address['addressLine1'] ?? address['street'] ?? '';
        final city = address['city'] ?? '';
        final state = address['state'] ?? '';

        final parts = <String>[];
        if (street.isNotEmpty) parts.add(street);
        if (city.isNotEmpty) parts.add(city);
        if (state.isNotEmpty) parts.add(state);

        return parts.isNotEmpty ? parts.join(', ') : 'Select delivery address';
      }

      // Fallback for unexpected formats
      return address.toString().isNotEmpty ? address.toString() : 'Select delivery address';
    } catch (e) {
      // Production-safe error handling
      debugPrint('Error formatting address: $e');
      return 'Select delivery address';
    }
  }









  /// Optimistic retry: Directly load data for immediate feedback
  void _performOptimisticRetry(WidgetRef ref) {
    _ensureDataLoaded(ref);
    ref.read(bannerNotifierProvider.notifier).refreshBanners();
    ref.read(paginatedAllProductsProvider.notifier).refreshProducts();
  }

  /// Handle pull-to-refresh action
  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh all sections in parallel for better performance
      await Future.wait([
        ref.read(bannerNotifierProvider.notifier).refreshBanners(),
        ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts(limit: 10),
        ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts(limit: 10),
        ref.read(paginatedAllProductsProvider.notifier).refreshProducts(),
      ]);

      // Small delay for better UX
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      // Handle errors gracefully
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }





  /// Build skeleton loading for home screen with collapsible app bar
  Widget _buildHomeScreenSkeletonWithAppBar() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Unified app bar with delivery section and search bar
        _buildUnifiedAppBar(context),

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
                skeleton_loading.SkeletonContainer(
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
                    skeleton_loading.SkeletonContainer(
                      width: 140,
                      height: 18,
                    ),
                    skeleton_loading.SkeletonContainer(
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
                    skeleton_loading.SkeletonContainer(
                      width: 80,
                      height: 18,
                    ),
                    skeleton_loading.SkeletonContainer(
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
          height: 140, // Reduced from 200 to match modern app standards
        ),
      ),
    );
  }

  Widget _buildFeaturedProductsSection(BuildContext context, WidgetRef ref) {
    final featuredProductsState = ref.watch(featuredProductsNotifierProvider);

    // Don't show the section if there are no featured products and loading is complete
    if (featuredProductsState.products.isEmpty &&
        featuredProductsState.hasLoaded &&
        !featuredProductsState.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/products?featured=true'),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Featured products horizontal list
          if (featuredProductsState.isLoading)
            _buildFeaturedProductsSkeleton()
          else if (featuredProductsState.products.isNotEmpty)
            _buildFeaturedProductsList(featuredProductsState.products)
          else
            _buildFeaturedProductsPlaceholder(),
        ],
      ),
    );
  }



  Widget _buildSaleProductsSection(BuildContext context, WidgetRef ref) {
    final saleProductsState = ref.watch(saleProductsNotifierProvider);

    // Don't show the section if there are no sale products and loading is complete
    if (saleProductsState.products.isEmpty &&
        saleProductsState.hasLoaded &&
        !saleProductsState.isLoading) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

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

  /// Builds the products grid with infinite scroll
  Widget _buildAllProductsGrid(List<Product> products) {
    final allProductsState = ref.watch(paginatedAllProductsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65, // Adjusted for StandardProductCard's more compact design
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return StandardProductCard(
                product: product,
                onTap: () => context.push('/clean/product/${product.id}'),
              );
            },
          ),
        ),

        // Loading indicator for infinite scroll
        if (allProductsState.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // End of list indicator
        if (allProductsState.hasReachedEnd && products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'You\'ve reached the end!',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
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
              'Stocking up soon',
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

  /// Builds the featured products horizontal list
  Widget _buildFeaturedProductsList(List<Product> products) {
    return Container(
      height: 240, // Reduced height for smaller compact cards
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 140, // Width for featured products (slightly larger than default)
            margin: EdgeInsets.only(
              right: index < products.length - 1 ? 12 : 0,
            ),
            child: StandardProductCard(
              product: product,
              width: 140, // Slightly larger for featured products
              onTap: () => context.push('/clean/product/${product.id}'),
            ),
          );
        },
      ),
    );
  }

  /// Builds skeleton loading for featured products
  Widget _buildFeaturedProductsSkeleton() {
    return Container(
      height: 240, // Reduced height to match smaller cards
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Container(
            width: 140, // Reduced width to match smaller cards
            margin: EdgeInsets.only(
              right: index < 3 ? 12 : 0,
            ),
            child: const ProductCardSkeleton(width: 140), // Updated skeleton width
          );
        },
      ),
    );
  }

  /// Builds placeholder when no featured products are available
  Widget _buildFeaturedProductsPlaceholder() {
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
    );
  }




}



