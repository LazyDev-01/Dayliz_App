import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/widgets/product_card.dart';

// Wishlist provider to manage wishlist state
final wishlistProvider = StateProvider<List<WishlistItem>>((ref) {
  // Mock data - in a real app this would come from an API or local storage
  return [
    WishlistItem(
      id: '1',
      productId: '101',
      name: 'Classic Leather Jacket',
      price: 129.99,
      imageUrl: 'assets/images/products/jacket.jpg',
      dateAdded: DateTime.now().subtract(const Duration(days: 2)),
    ),
    WishlistItem(
      id: '2',
      productId: '102',
      name: 'Premium Denim Jeans',
      price: 79.99,
      imageUrl: 'assets/images/products/jeans.jpg',
      dateAdded: DateTime.now().subtract(const Duration(days: 5)),
    ),
    WishlistItem(
      id: '3',
      productId: '103',
      name: 'Cotton Casual T-Shirt',
      price: 24.99,
      imageUrl: 'assets/images/products/tshirt.jpg',
      dateAdded: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
});

// Wishlist item model
class WishlistItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String imageUrl;
  final DateTime dateAdded;
  final double? discountPercentage;

  WishlistItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.dateAdded,
    this.discountPercentage,
  });
}

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        actions: [
          if (wishlist.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearWishlistDialog(context, ref),
              tooltip: 'Clear Wishlist',
            ),
        ],
      ),
      body: wishlist.isEmpty
          ? _buildEmptyWishlist(context)
          : _buildWishlistContent(context, ref, wishlist),
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your wishlist to save them for later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to shop page
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistContent(
      BuildContext context, WidgetRef ref, List<WishlistItem> wishlist) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${wishlist.length} item${wishlist.length > 1 ? 's' : ''} in your wishlist',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: wishlist.length,
            itemBuilder: (context, index) {
              final item = wishlist[index];
              return _buildWishlistItemCard(context, ref, item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistItemCard(
      BuildContext context, WidgetRef ref, WishlistItem item) {
    return Stack(
      children: [
        ProductCard(
          imageUrl: item.imageUrl,
          name: item.name,
          price: item.price,
          discountPercentage: item.discountPercentage,
          onTap: () {
            // Navigate to product detail page
            // Navigator.pushNamed(context, '/product/${item.productId}');
          },
        ),
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
              onPressed: () => _removeFromWishlist(ref, item),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
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
              onPressed: () => _addToCart(context, ref, item),
            ),
          ),
        ),
      ],
    );
  }

  void _removeFromWishlist(WidgetRef ref, WishlistItem item) {
    ref.read(wishlistProvider.notifier).update(
          (state) => state.where((i) => i.id != item.id).toList(),
        );
  }

  void _showClearWishlistDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Wishlist'),
        content: const Text(
            'Are you sure you want to remove all items from your wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              ref.read(wishlistProvider.notifier).state = [];
              Navigator.pop(context);
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref, WishlistItem item) {
    // In a real app, you would add this item to the cart provider
    // Here we just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            // Navigate to cart
            // Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }
} 