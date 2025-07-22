import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart_item.dart';
import '../../providers/cart_providers.dart';
import '../auth/auth_guard.dart';
import '../cart/smooth_quantity_controls.dart';



/// A clean architecture implementation of a product card for q-commerce applications
/// following industry standards like Blinkit and Zepto.
/// Optimized with RepaintBoundary and memoization for better performance.
class CleanProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const CleanProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  ConsumerState<CleanProductCard> createState() => _CleanProductCardState();
}

class _CleanProductCardState extends ConsumerState<CleanProductCard> {
  final _uuid = const Uuid();



  @override
  Widget build(BuildContext context) {

    // Calculate sizes based on screen width if not explicitly provided
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = widget.width ?? (screenWidth / 2) - 16;
    final cardHeight = widget.height ?? cardWidth * 1.8; // 1:1.8 aspect ratio (restored)
    final imageSize = cardWidth; // Full width image (restored)

    // PERFORMANCE: RepaintBoundary prevents unnecessary repaints of product cards
    return RepaintBoundary(
      child: Container(
        width: cardWidth,
        height: cardHeight,
        margin: const EdgeInsets.only(bottom: 4),
        child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section (square)
              _buildImageSection(imageSize),

              // Info section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Restored original padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weight/Quantity
                      Text(
                        _getQuantityText(),
                        style: TextStyle(
                          fontSize: 11, // Restored original size
                          color: Colors.grey[600],
                          fontWeight: FontWeight.normal,
                        ),
                      ),

                      const SizedBox(height: 4), // Restored original spacing

                      // Product name
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13, // Restored original size
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),

                      const Spacer(),

                      // Price and Add button row
                      _buildPriceAndActionRow(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// Builds the image section with discount badge
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
                imageUrl: widget.product.mainImageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 300, // PERFORMANCE: Limit memory cache for product cards
                memCacheHeight: 300,
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Colors.grey,
                    semanticLabel: 'Product image not available',
                  ),
                ),
              ),
            ),
          ),

        // Discount badge
        if (widget.product.discountPercentage != null && widget.product.discountPercentage! > 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '-${widget.product.discountPercentage!.round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Low stock badge (only show if in stock and quantity < 5)
        if (widget.product.inStock &&
            widget.product.stockQuantity != null &&
            widget.product.stockQuantity! > 0 &&
            widget.product.stockQuantity! < 5)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Only ${widget.product.stockQuantity} left',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Out of stock overlay
          if (!widget.product.inStock)
            Positioned.fill(
              child: Container(
                color: Colors.black.withAlpha(153), // 0.6 opacity (153/255)
                child: const Center(
                  child: Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the price and action row (Add button or quantity selector)
  Widget _buildPriceAndActionRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Price section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discounted price
              Text(
                '₹${widget.product.discountedPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14, // Restored original size
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              // Original price (if discounted)
              if (widget.product.discountPercentage != null && widget.product.discountPercentage! > 0)
                Text(
                  '₹${widget.product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12, // Restored original size
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),

        // Add button or quantity selector
        Consumer(
          builder: (context, ref, child) {
            final cartItems = ref.watch(cartItemsProvider);
            final isInCart = cartItems.any((item) => item.product.id == widget.product.id);
            final cartItem = isInCart
                ? cartItems.firstWhere((item) => item.product.id == widget.product.id)
                : null;
            final quantity = cartItem?.quantity ?? 0;

            return isInCart
                ? _buildQuantitySelector(context, quantity, cartItem!)
                : _buildAddButton(context, isInCart, quantity);
          },
        ),
      ],
    );
  }

  /// Builds the ADD button matching SmoothQuantityControls dimensions exactly
  Widget _buildAddButton(BuildContext context, bool isInCart, int quantity) {
    // Calculate exact dimensions to match SmoothQuantityControls
    const buttonSize = 26.0;  // Same as SmoothQuantityControls button size
    const quantityDisplayWidth = 35.0;  // Same as SmoothQuantityControls
    const totalWidth = buttonSize * 2 + quantityDisplayWidth;  // 87px

    return Container(
      width: totalWidth,  // 87px - matches SmoothQuantityControls exactly
      decoration: BoxDecoration(
        color: widget.product.inStock ? Theme.of(context).primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.product.inStock ? Theme.of(context).primaryColor : Colors.grey[400]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.product.inStock ? () {
            // Add haptic feedback to match SmoothQuantityControls
            HapticFeedback.lightImpact();
            _addToCart(context);
          } : null,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), // Same as SmoothQuantityControls
            alignment: Alignment.center,
            child: Text(
              'ADD',
              style: TextStyle(
                color: widget.product.inStock ? Colors.white : Colors.grey[600],
                fontSize: 13.0,  // Same as SmoothQuantityControls
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the quantity selector using SmoothQuantityControls (cart screen dimensions)
  Widget _buildQuantitySelector(BuildContext context, int quantity, CartItem cartItem) {
    // If product is not in cart, show the add button instead
    if (quantity <= 0) {
      return _buildAddButton(context, false, 0);
    }

    // Use GestureDetector to stop tap events from propagating to the parent card
    return GestureDetector(
      // This prevents the tap from propagating to the parent card
      onTap: (){
        // Stop propagation by handling the tap here
      },
      // This ensures the gesture detector doesn't interfere with other gestures
      behavior: HitTestBehavior.opaque,
      child: SmoothQuantityControls(
        cartItem: cartItem,
        isUpdating: false, // Product cards don't show individual loading states
        onQuantityChanged: (cartItem, newQuantity) {
          _updateQuantity(context, cartItem.quantity, newQuantity);
        },
        // Use cart screen dimensions for consistency
        buttonSize: 26.0,  // Same as cart screen (26×26px buttons)
        fontSize: 13.0,    // Same as cart screen
        // Total container will be 87px width (26+35+26) × 40px height
      ),
    );
  }

  /// Add product to cart - PROTECTED by AuthGuard
  Future<void> _addToCart(BuildContext context) async {
    // CART PROTECTION: Check authentication before adding to cart
    final isAllowed = AuthGuardService.checkAuthAndPrompt(
      context: context,
      ref: ref,
      action: 'add_to_cart',
      onAuthRequired: () {
        // Guest user tried to add to cart - auth prompt shown
      },
    );

    // If user is not authenticated, the auth prompt is shown and we return
    if (!isAllowed) {
      return;
    }

    // User is authenticated, proceed with adding to cart

    // Provider handles optimistic updates automatically - no local state needed

    // Note: Loading indicator removed - floating cart button provides sufficient feedback

    try {
      // Try to use the clean architecture cart first
      bool success = false;
      try {
        success = await ref.read(cartNotifierProvider.notifier).addToCart(
          product: widget.product,
          quantity: 1,
        );
      } catch (e) {
        // Error adding to cart with provider
        success = false;
      }

      if (!success) {
        // Fallback to direct SharedPreferences approach
        final prefs = await SharedPreferences.getInstance();

        // Get existing cart items
        final jsonString = prefs.getString('CACHED_CART');
        List<Map<String, dynamic>> cartItems = [];

        if (jsonString != null) {
          final List<dynamic> jsonList = json.decode(jsonString);
          cartItems = jsonList.cast<Map<String, dynamic>>();
        }

        // Check if product already exists
        bool productExists = false;

        for (var i = 0; i < cartItems.length; i++) {
          final productData = cartItems[i]['product'] as Map<String, dynamic>;
          if (productData['id'] == widget.product.id) {
            // Update quantity
            cartItems[i]['quantity'] = (cartItems[i]['quantity'] as int) + 1;
            productExists = true;
            break;
          }
        }

        if (!productExists) {
          // Create a new cart item
          final newItemId = _uuid.v4();

          // Convert product to JSON
          final productJson = {
            'id': widget.product.id,
            'name': widget.product.name,
            'description': widget.product.description,
            'price': widget.product.price,
            'discount_percentage': widget.product.discountPercentage,
            'rating': widget.product.rating,
            'review_count': widget.product.reviewCount,
            'main_image_url': widget.product.mainImageUrl,
            'additional_images': widget.product.additionalImages,
            'in_stock': widget.product.inStock,
            'stock_quantity': widget.product.stockQuantity,
            'category_id': widget.product.categoryId,
            'subcategory_id': widget.product.subcategoryId,
            'brand': widget.product.brand,
            'attributes': widget.product.attributes,
            'tags': widget.product.tags,
            'created_at': widget.product.createdAt?.toIso8601String(),
            'updated_at': widget.product.updatedAt?.toIso8601String(),
          };

          // Add new item
          cartItems.add({
            'id': newItemId,
            'product': productJson,
            'quantity': 1,
            'added_at': DateTime.now().toIso8601String(),
          });
        }

        // Save updated cart items
        await prefs.setString(
          'CACHED_CART',
          json.encode(cartItems),
        );
      }

      // We already updated the state at the beginning for better UX
      // Provider handles state updates automatically

      // Force refresh the cart state
      try {
        await ref.read(cartNotifierProvider.notifier).refreshCart();
      } catch (e) {
        // Error refreshing cart provider
      }

      // Success feedback disabled for early launch
    } catch (e) {
      // Error adding to cart

      // Error feedback disabled for early launch
    }
  }

  /// Update quantity of product in cart
  Future<void> _updateQuantity(BuildContext context, int currentQuantity, int newQuantity) async {
    // Don't proceed if the quantity is the same
    if (newQuantity == currentQuantity && newQuantity > 0) {
      return;
    }

    try {
      // Try to use the clean architecture cart first
      if (newQuantity <= 0) {
        // Find the cart item ID
        final cartItems = ref.read(cartItemsProvider);
        String? cartItemId;

        for (var item in cartItems) {
          if (item.product.id == widget.product.id) {
            cartItemId = item.id;
            break;
          }
        }

        if (cartItemId != null) {
          try {
            // Remove from cart
            final success = await ref.read(cartNotifierProvider.notifier).removeFromCart(
              cartItemId: cartItemId,
            );

            if (success) {
              // Provider handles state updates automatically

              // Success feedback disabled for early launch

              return;
            }
          } catch (e) {
            // Error removing from cart - continue to fallback approach
          }
        }

        // Fallback to direct SharedPreferences approach
        final prefs = await SharedPreferences.getInstance();

        // Get existing cart items
        final jsonString = prefs.getString('CACHED_CART');
        if (jsonString != null) {
          final List<dynamic> jsonList = json.decode(jsonString);
          final cartItems = jsonList.cast<Map<String, dynamic>>();

          // Find the cart item for this product
          int cartItemIndex = -1;

          for (var i = 0; i < cartItems.length; i++) {
            final productData = cartItems[i]['product'] as Map<String, dynamic>;
            if (productData['id'] == widget.product.id) {
              cartItemIndex = i;
              break;
            }
          }

          if (cartItemIndex >= 0) {
            // Remove from cart
            cartItems.removeAt(cartItemIndex);

            // Save updated cart items
            await prefs.setString(
              'CACHED_CART',
              json.encode(cartItems),
            );

            // Provider handles state updates automatically

            // Success feedback disabled for early launch
          }
        }
      } else {
        // Try to update quantity using the clean architecture cart
        final cartItems = ref.read(cartItemsProvider);
        String? cartItemId;

        for (var item in cartItems) {
          if (item.product.id == widget.product.id) {
            cartItemId = item.id;
            break;
          }
        }

        if (cartItemId != null) {
          try {
            // Update quantity
            final success = await ref.read(cartNotifierProvider.notifier).updateQuantity(
              cartItemId: cartItemId,
              quantity: newQuantity,
            );

            if (success) {
              // Provider handles state updates automatically

              return;
            }
          } catch (e) {
            // Error updating quantity - continue to fallback approach
          }
        }

        // Fallback to direct SharedPreferences approach
        final prefs = await SharedPreferences.getInstance();

        // Get existing cart items
        final jsonString = prefs.getString('CACHED_CART');
        if (jsonString != null) {
          final List<dynamic> jsonList = json.decode(jsonString);
          final cartItems = jsonList.cast<Map<String, dynamic>>();

          // Find the cart item for this product
          int cartItemIndex = -1;

          for (var i = 0; i < cartItems.length; i++) {
            final productData = cartItems[i]['product'] as Map<String, dynamic>;
            if (productData['id'] == widget.product.id) {
              cartItemIndex = i;
              break;
            }
          }

          if (cartItemIndex >= 0) {
            // Update quantity
            cartItems[cartItemIndex]['quantity'] = newQuantity;

            // Save updated cart items
            await prefs.setString(
              'CACHED_CART',
              json.encode(cartItems),
            );

            // Provider handles state updates automatically
          }
        }
      }

      // Force refresh the cart state
      try {
        await ref.read(cartNotifierProvider.notifier).refreshCart();
      } catch (e) {
        // Error refreshing cart provider
      }
    } catch (e) {
      // Error updating quantity

      // Error feedback disabled for early launch
    }
  }

  /// Get the quantity text (e.g., 500g, 1L, etc.)
  String _getQuantityText() {
    // First check the dedicated weight field from database
    if (widget.product.weight != null && widget.product.weight!.isNotEmpty) {
      return widget.product.weight!;
    }

    // Try to get from attributes as fallback
    if (widget.product.attributes != null) {
      final weight = widget.product.attributes!['weight'] as String?;
      final unit = widget.product.attributes!['unit'] as String?;
      final volume = widget.product.attributes!['volume'] as String?;
      final quantity = widget.product.attributes!['quantity'] as String?;

      if (weight != null && weight.isNotEmpty) return weight;
      if (unit != null && unit.isNotEmpty) return unit;
      if (volume != null && volume.isNotEmpty) return volume;
      if (quantity != null && quantity.isNotEmpty) return quantity;
    }

    // Default fallback
    return '1 pc';
  }
}
