import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/product.dart';
import '../../providers/wishlist_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/product/clean_product_grid.dart';

/// Clean Wishlist Screen that displays the user's wishlist
class CleanWishlistScreen extends ConsumerStatefulWidget {
  const CleanWishlistScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanWishlistScreen> createState() => _CleanWishlistScreenState();
}

class _CleanWishlistScreenState extends ConsumerState<CleanWishlistScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule the fetch for after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlistItems();
    });
  }

  Future<void> _loadWishlistItems() async {
    await ref.read(wishlistNotifierProvider.notifier).loadWishlistProducts();
  }

  @override
  Widget build(BuildContext context) {
    final wishlistProducts = ref.watch(wishlistProductsProvider);
    final isLoading = ref.watch(wishlistLoadingProvider);
    final errorMessage = ref.watch(wishlistErrorProvider);

    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: 'My Wishlist',
        fallbackRoute: '/clean/profile',
        backButtonTooltip: 'Back to Profile',
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[800],
        actions: wishlistProducts.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: () => _showClearWishlistDialog(context),
                  tooltip: 'Clear wishlist',
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWishlistItems,
        child: _buildBody(
          isLoading: isLoading,
          errorMessage: errorMessage,
          wishlistProducts: wishlistProducts,
        ),
      ),
    );
  }

  Widget _buildBody({
    required bool isLoading,
    required String? errorMessage,
    required List<Product> wishlistProducts,
  }) {
    if (isLoading && wishlistProducts.isEmpty) {
      return const Center(
        child: LoadingIndicator(message: 'Loading wishlist...'),
      );
    }

    if (errorMessage != null && wishlistProducts.isEmpty) {
      return ErrorState(
        error: errorMessage,
        onRetry: _loadWishlistItems,
      );
    }

    if (wishlistProducts.isEmpty) {
      return EmptyState(
        icon: Icons.favorite_border,
        title: 'Your Wishlist is Empty',
        message: 'Items added to your wishlist will appear here',
        buttonText: 'Continue Shopping',
        onButtonPressed: () => context.go('/home'),
      );
    }

    return _buildWishlistGrid(wishlistProducts);
  }

  Widget _buildWishlistGrid(List<Product> products) {
    return CleanProductGrid(
      products: products,
      padding: const EdgeInsets.all(16),
    );
  }

  void _showClearWishlistDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text('Are you sure you want to clear your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wishlistNotifierProvider.notifier).clearWishlist();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}