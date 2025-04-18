import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/providers/wishlist_provider.dart';
import 'package:dayliz_app/widgets/product_card.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistItems = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if (wishlistItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
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
                          ref.read(wishlistProvider.notifier).clearWishlist();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: wishlistItems.isEmpty
          ? _buildEmptyWishlist(context)
          : _buildWishlistGrid(context, wishlistItems, ref),
    );
  }

  Widget _buildEmptyWishlist(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to your wishlist to save them for later',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to home screen using go_router
              context.go('/home');
            }, 
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistGrid(
      BuildContext context, List<Product> items, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65, // Same aspect ratio as product screen
        crossAxisSpacing: 10,
        mainAxisSpacing: 20, // Same spacing as product screen
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return ProductCard(
          product: product,
          onTap: () {
            // Navigate to product details
            Navigator.of(context).pushNamed(
              '/product-details',
              arguments: product,
            );
          },
          onWishlistToggle: () {
            // Remove from wishlist when clicked
            ref.read(wishlistProvider.notifier).removeFromWishlist(product.id);
          },
        );
      },
    );
  }
} 