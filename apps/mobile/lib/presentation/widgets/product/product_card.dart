import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/product.dart';
import '../../providers/cart_providers.dart';
import '../common/loading_indicator.dart';

/// A product card widget for the clean architecture implementation
/// This is a simplified version of CleanProductCard
class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calculate sizes based on screen width if not explicitly provided
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = width ?? (screenWidth / 2) - 16;
    final cardHeight = height ?? cardWidth * 1.8; // 1:1.8 aspect ratio
    final imageSize = cardWidth;

    // Check if product is in cart
    final cartItems = ref.watch(cartItemsProvider);
    final isInCart = cartItems.any((item) => item.product.id == product.id);
    final cartItem = isInCart
        ? cartItems.firstWhere((item) => item.product.id == product.id)
        : null;
    final quantity = cartItem?.quantity ?? 0;

    return Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section (square)
              _buildImageSection(imageSize),

              // Info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildInfoSection(context, isInCart, quantity, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(double size) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Product image with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: size,
              height: size,
              child: CachedNetworkImage(
                imageUrl: product.mainImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
            ),
          ),

          // Discount tag if applicable
          if (product.discountPercentage != null && product.discountPercentage! > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${product.discountPercentage!.round()}% OFF',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, bool isInCart, int quantity, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Product name
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        // Product weight/quantity (using attributes if available)
        Text(
          product.attributes?['unit'] ?? '',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),

        const Spacer(),

        // Price and add to cart
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Price section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Original price if discounted
                if (product.discountPercentage != null && product.discountPercentage! > 0)
                  Text(
                    '₹${product.originalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                    ),
                  ),

                // Current price (retail sale price)
                Text(
                  '₹${product.discountedPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            // Add to cart button or quantity selector
            isInCart
                ? _buildQuantitySelector(context, quantity, ref)
                : _buildAddButton(context, ref),
          ],
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => _addToCart(context, ref),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(80, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      child: const Text(
        'ADD',
        style: TextStyle(
          fontSize: 13, // Increased font size
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildQuantitySelector(BuildContext context, int quantity, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).primaryColor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          InkWell(
            onTap: () => _updateQuantity(context, quantity - 1, ref),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.remove,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Quantity
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Increase button
          InkWell(
            onTap: () => _updateQuantity(context, quantity + 1, ref),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.add,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(BuildContext context, WidgetRef ref) async {
    try {
      final notifier = ref.read(cartNotifierProvider.notifier);
      await notifier.addToCart(product: product, quantity: 1);

      if (context.mounted) {
        debugPrint('${product.name} added to cart');
        // Success feedback disabled for early launch
      }
    } catch (e) {
      if (context.mounted) {
        debugPrint('Failed to add to cart: $e');
        // Error feedback disabled for early launch
      }
    }
  }

  void _updateQuantity(BuildContext context, int newQuantity, WidgetRef ref) async {
    try {
      final cartItems = ref.read(cartItemsProvider);
      final cartItem = cartItems.firstWhere((item) => item.product.id == product.id);

      if (newQuantity <= 0) {
        // Remove from cart
        await ref.read(cartNotifierProvider.notifier).removeFromCart(
          cartItemId: cartItem.id,
        );
      } else {
        // Update quantity
        await ref.read(cartNotifierProvider.notifier).updateQuantity(
          cartItemId: cartItem.id,
          quantity: newQuantity,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update quantity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
