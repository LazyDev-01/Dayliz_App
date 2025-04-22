import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/product.dart';
import '../../providers/wishlist_providers.dart';
import '../../providers/cart_providers.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/loading_indicator.dart';

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
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if (wishlistProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearWishlistDialog(context),
              tooltip: 'Clear wishlist',
            ),
        ],
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
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _WishlistProductCard(product: product);
      },
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

/// Wishlist product card
class _WishlistProductCard extends ConsumerWidget {
  final Product product;

  const _WishlistProductCard({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '\$');

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Product Card Content
          InkWell(
            onTap: () => context.push('/products/${product.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      image: product.mainImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(product.mainImageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.mainImageUrl.isEmpty
                        ? const Center(child: Icon(Icons.image, size: 48))
                        : null,
                  ),
                ),
                // Product Details
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (product.discountPercentage != null &&
                            product.discountPercentage! > 0) ...[
                          Row(
                            children: [
                              Text(
                                currency.format(product.discountedPrice),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                currency.format(product.price),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.discountPercentage!.toInt()}% OFF',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            currency.format(product.price),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Remove from Wishlist Button
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close),
                color: Colors.grey.shade800,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
                onPressed: () => _removeFromWishlist(context, ref),
              ),
            ),
          ),
          // Add to Cart Button
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                color: Colors.white,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: () => _addToCart(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _removeFromWishlist(BuildContext context, WidgetRef ref) {
    ref.read(wishlistNotifierProvider.notifier).removeFromWishlist(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} removed from wishlist'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(wishlistNotifierProvider.notifier).addToWishlist(product.id);
          },
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref) {
    // Add to cart
    ref.read(cartNotifierProvider.notifier).addToCart(
      product: product,
      quantity: 1,
    );
    
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push('/cart'),
        ),
      ),
    );
  }
} 