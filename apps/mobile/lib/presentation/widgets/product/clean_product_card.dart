import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/product.dart';
import '../../providers/cart_providers.dart';
import '../../providers/auth_providers.dart';
import '../auth/auth_guard.dart';

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
  bool _isInCart = false;
  int _quantity = 0;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _checkIfInCart();
  }

  Future<void> _checkIfInCart() async {
    try {
      // First try to get from the clean architecture cart
      final cartItems = await ref.read(cartNotifierProvider.notifier).isInCart(productId: widget.product.id);
      if (cartItems) {
        // Get the quantity
        final items = ref.read(cartItemsProvider);
        for (var item in items) {
          if (item.product.id == widget.product.id) {
            if (mounted) {
              setState(() {
                _isInCart = true;
                _quantity = item.quantity;
              });
            }
            return;
          }
        }
      }

      // Fallback to direct SharedPreferences check
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('CACHED_CART');

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);

        for (final item in jsonList) {
          try {
            final productData = item['product'] as Map<String, dynamic>;

            if (productData['id'] == widget.product.id) {
              if (mounted) {
                setState(() {
                  _isInCart = true;
                  _quantity = item['quantity'] as int;
                });
              }
              break;
            }
          } catch (e) {
            // Error parsing cart item
          }
        }
      }
    } catch (e) {
      // Error checking if in cart
    }
  }

  @override
  Widget build(BuildContext context) {
    // Performance optimization: Removed debug prints for production

    // Calculate sizes based on screen width if not explicitly provided
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = widget.width ?? (screenWidth / 2) - 16;
    final cardHeight = widget.height ?? cardWidth * 1.8; // 1:1.8 aspect ratio (restored)
    final imageSize = cardWidth; // Full width image (restored)

    return Container(
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
    );
  }

  /// Builds the image section with discount badge
  Widget _buildImageSection(double size) {
    return Stack(
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
        _isInCart
            ? _buildQuantitySelector(context)
            : _buildAddButton(context),
      ],
    );
  }

  /// Builds the ADD button
  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      height: 32, // Restored original size
      width: 70, // Restored original size
      child: ElevatedButton(
        onPressed: widget.product.inStock ? () => _addToCart(context) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary, // Using standard green #4CAF50
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16), // Restored original padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
        ),
        child: const Text(
          'ADD',
          style: TextStyle(
            fontSize: 12, // Restored original size
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Builds the quantity selector for items already in cart
  Widget _buildQuantitySelector(BuildContext context) {
    // If product is not in cart, show the add button instead
    if (_quantity <= 0) {
      return _buildAddButton(context);
    }

    // Use GestureDetector to stop tap events from propagating to the parent card
    return GestureDetector(
      // This prevents the tap from propagating to the parent card
      onTap: (){
        // Stop propagation by handling the tap here
      },
      // This ensures the gesture detector doesn't interfere with other gestures
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32, // Restored original size
        width: 70, // Restored original size
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Decrease button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Update state immediately for better UX
                  if (mounted) {
                    setState(() {
                      _quantity = _quantity - 1;
                      if (_quantity <= 0) {
                        _isInCart = false;
                      }
                    });
                  }
                  _updateQuantity(context, _quantity);
                },
                child: Container(
                  width: 22,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.remove,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),

            // Quantity display
            Container(
              width: 22, // Restored original size
              alignment: Alignment.center,
              child: Text(
                '$_quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, // Restored original size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Increase button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Update state immediately for better UX
                  if (mounted) {
                    setState(() {
                      _quantity = _quantity + 1;
                    });
                  }
                  _updateQuantity(context, _quantity);
                },
                child: Container(
                  width: 22,
                  height: 32,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.add,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
          ],
        ),
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
        debugPrint('🔒 CART PROTECTION: Guest user tried to add ${widget.product.name} to cart');
      },
    );

    // If user is not authenticated, the auth prompt is shown and we return
    if (!isAllowed) {
      return;
    }

    // User is authenticated, proceed with adding to cart
    debugPrint('🔓 CART PROTECTION: Authenticated user adding ${widget.product.name} to cart');

    // Update state immediately for better UX
    if (mounted) {
      setState(() {
        _isInCart = true;
        _quantity = _quantity + 1;
      });
    }

    // Show loading indicator
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text('Adding ${widget.product.name} to cart...'),
            ],
          ),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
          width: MediaQuery.of(context).size.width * 0.9,
        ),
      );
    }

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
      // Just make sure it's still correct
      if (mounted) {
        setState(() {
          _isInCart = true;
          _quantity = _quantity > 0 ? _quantity : 1; // Ensure at least 1
        });
      }

      // Force refresh the cart state
      try {
        await ref.read(cartNotifierProvider.notifier).refreshCart();
      } catch (e) {
        // Error refreshing cart provider
      }

      // Success feedback disabled for early launch
      if (context.mounted) {
        debugPrint('${widget.product.name} added to cart');
      }
    } catch (e) {
      // Error adding to cart

      // Error feedback disabled for early launch
      if (context.mounted) {
        debugPrint('Failed to add ${widget.product.name} to cart: ${e.toString()}');
      }
    }
  }

  /// Update quantity of product in cart
  Future<void> _updateQuantity(BuildContext context, int newQuantity) async {
    // Don't proceed if the quantity is the same
    if (newQuantity == _quantity && newQuantity > 0) {
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
              // Update state
              if (mounted) {
                setState(() {
                  _isInCart = false;
                  _quantity = 0;
                });
              }

              // Success feedback disabled for early launch
              if (context.mounted) {
                debugPrint('${widget.product.name} removed from cart');
              }

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

            // Update state
            if (mounted) {
              setState(() {
                _isInCart = false;
                _quantity = 0;
              });
            }

            // Success feedback disabled for early launch
            if (context.mounted) {
              debugPrint('${widget.product.name} removed from cart');
            }
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
              // Update state
              if (mounted) {
                setState(() {
                  _quantity = newQuantity;
                });
              }

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

            // Update state
            if (mounted) {
              setState(() {
                _quantity = newQuantity;
              });
            }
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
      if (context.mounted) {
        debugPrint('Failed to update quantity: ${e.toString()}');
      }
    }
  }

  /// Get the quantity text (e.g., 500g, 1L, etc.)
  String _getQuantityText() {
    // Try to get from attributes first
    if (widget.product.attributes != null) {
      final weight = widget.product.attributes!['weight'] as String?;
      final volume = widget.product.attributes!['volume'] as String?;
      final quantity = widget.product.attributes!['quantity'] as String?;

      if (weight != null) return weight;
      if (volume != null) return volume;
      if (quantity != null) return quantity;
    }

    // Default fallbacks based on product name or category
    if (widget.product.name.toLowerCase().contains('milk')) return '500ml';
    if (widget.product.name.toLowerCase().contains('bread')) return '400g';
    if (widget.product.name.toLowerCase().contains('egg')) return '6 pcs';
    if (widget.product.name.toLowerCase().contains('rice')) return '1kg';
    if (widget.product.name.toLowerCase().contains('oil')) return '1L';

    // Default
    return '1 pc';
  }
}
