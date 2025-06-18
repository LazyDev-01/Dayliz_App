import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/common/skeleton_loading.dart';
import '../../providers/home_providers.dart';
import '../../providers/category_providers.dart';
// import '../../widgets/product/clean_product_card.dart'; // Removed for now
import '../../widgets/home/home_categories_section.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/category.dart';

/// A clean architecture implementation of the home screen
/// Updated with compact product cards and improved category alignment
class CleanHomeScreen extends ConsumerStatefulWidget {
  const CleanHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanHomeScreen> createState() => _CleanHomeScreenState();
}

class _CleanHomeScreenState extends ConsumerState<CleanHomeScreen> {
  final RefreshController _refreshController = RefreshController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Schedule the data loading for after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🏠 HOME: Starting to load initial data...');
      
      // Load featured products
      debugPrint('🏠 HOME: Loading featured products...');
      await ref.read(featuredProductsNotifierProvider.notifier).loadFeaturedProducts(limit: 10);
      
      // Load sale products
      debugPrint('🏠 HOME: Loading sale products...');
      await ref.read(saleProductsNotifierProvider.notifier).loadSaleProducts(limit: 10);

      debugPrint('🏠 HOME: Initial data loading completed successfully');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🏠 HOME: Error loading initial data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load data: ${e.toString()}';
        });
      }
    }
  }

  void _onRefresh() async {
    // Refresh all data
    await _loadInitialData();
    
    // Also refresh categories
    ref.invalidate(categoriesProvider);
    
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
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

  Widget _buildBody() {
    if (_isLoading) {
      return _buildHomeScreenSkeleton();
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _loadInitialData,
      );
    }

    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      child: CustomScrollView(
        slivers: [
          // Banner carousel placeholder
          _buildBannerPlaceholder(),

          // Categories section with improved alignment
          const SliverToBoxAdapter(
            child: HomeCategoriesSection(),
          ),

          // Featured products section with compact cards
          _buildFeaturedProductsSection(),

          // Sale products section with compact cards
          _buildSaleProductsSection(),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
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
        height: 180,
        // Added top margin for proper spacing from app bar
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: _AutoScrollingBannerCarousel(),
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
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

  Widget _buildSaleProductsSection() {
    // final saleProductsState = ref.watch(saleProductsNotifierProvider); // Removed - using placeholder

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

  // Widget _buildSaleProductsList(SaleProductsState state) {
  //   // Removed - using placeholder for now
  // }

  // Product-related methods removed - using placeholders for now
  // Widget _buildProductsLoading() { ... }
  // Widget _buildProductsError(String message) { ... }
  // Widget _buildProductsEmpty(String message) { ... }
}

/// Auto-scrolling banner carousel widget for modern commerce app experience
class _AutoScrollingBannerCarousel extends StatefulWidget {
  @override
  State<_AutoScrollingBannerCarousel> createState() => _AutoScrollingBannerCarouselState();
}

class _AutoScrollingBannerCarouselState extends State<_AutoScrollingBannerCarousel> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  // Sample banner data - in real app this would come from API
  final List<BannerData> _banners = [
    BannerData(
      title: 'Fresh Groceries Delivered',
      subtitle: 'Get 20% off on your first order',
      gradient: const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF81C784)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.local_grocery_store,
    ),
    BannerData(
      title: 'Daily Essentials',
      subtitle: 'Free delivery on orders above ₹500',
      gradient: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.shopping_basket,
    ),
    BannerData(
      title: 'Fresh Fruits & Vegetables',
      subtitle: 'Farm fresh produce at your doorstep',
      gradient: const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      icon: Icons.eco,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Banner PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerItem(_banners[index]);
            },
          ),

          // Page Indicators
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _banners.asMap().entries.map((entry) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == entry.key
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(BannerData banner) {
    return Container(
      decoration: BoxDecoration(
        gradient: banner.gradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Text Content
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Icon
            Expanded(
              flex: 1,
              child: Icon(
                banner.icon,
                size: 80,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class for banner information
class BannerData {
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;

  BannerData({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });
}
