import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
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
      return const LoadingIndicator(message: 'Loading home screen...');
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

  Widget _buildBannerPlaceholder() {
    return SliverToBoxAdapter(
      child: Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 48, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                'Banner Carousel',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
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
                    fontSize: 18,
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
                    fontSize: 18,
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
