import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/product.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/cart_providers.dart';
import '../auth/auth_guard.dart';

/// Standard Product Card with clean design and animated add button functionality
/// This is the unified card component used throughout the app for consistency
///
/// Features:
/// - Clean design with image-only borders (no shadows)
/// - Configurable width (default 120px)
/// - Animated + button that expands to quantity controls
/// - Efficient space usage with flexible image ratios
/// - Consistent with clean product card design language
/// - Cached network images for better performance
/// - Error handling for cart operations
/// - Weight/unit display support
/// - Production-ready with optimizations
class StandardProductCard extends ConsumerStatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final double? width;

  const StandardProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.width,
  });

  @override
  ConsumerState<StandardProductCard> createState() => _StandardProductCardState();
}

class _StandardProductCardState extends ConsumerState<StandardProductCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _widthAnimation = Tween<double>(
      begin: 36.0, // Increased + button width to match ADD button height
      end: 90.0,   // Increased quantity controls width proportionally
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 120.0; // Default compact width

    return GestureDetector(
      onTap: widget.onTap ?? () {
        // Default navigation to product details
        context.push('/clean/product/${widget.product.id}');
      },
      child: Container(
        width: cardWidth,
        decoration: const BoxDecoration(
          color: Colors.white,
          // Clean design - no borders or shadows on main container
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with animated add button
            Expanded(
              flex: 3, // Efficient 3:2 ratio for image:content
              child: _buildImageSection(),
            ),

            // Product details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Price display
                    _buildPriceDisplay(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the image section with clean border and animated add button
  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12), // Rounded corners on all sides
      ),
      child: Stack(
        children: [
          // Product image with caching for better performance
          ClipRRect(
            borderRadius: BorderRadius.circular(12), // Rounded corners on all sides
            child: CachedNetworkImage(
              imageUrl: widget.product.mainImageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              memCacheWidth: 300, // Optimize memory usage
              memCacheHeight: 300,
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 100),
              placeholder: (context, url) => Container(
                color: Colors.grey[100],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
            ),
          ),

          // Discount badge (top left)
          if (widget.product.discountPercentage != null && widget.product.discountPercentage! > 0)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-${widget.product.discountPercentage!.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Animated add button (bottom right)
          Positioned(
            bottom: 8,
            right: 8,
            child: Consumer(
              builder: (context, ref, child) {
                final cartItems = ref.watch(cartItemsProvider);
                final isInCart = cartItems.any((item) => item.product.id == widget.product.id);
                final cartItem = isInCart
                    ? cartItems.firstWhere((item) => item.product.id == widget.product.id)
                    : null;

                // Trigger animation based on cart state
                if (isInCart && _animationController.status == AnimationStatus.dismissed) {
                  _animationController.forward();
                } else if (!isInCart && _animationController.status == AnimationStatus.completed) {
                  _animationController.reverse();
                }

                return _buildAnimatedQuantityControls(isInCart, cartItem);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the price display with weight information
  Widget _buildPriceDisplay() {
    final hasDiscount = widget.product.discountPercentage != null &&
                       widget.product.discountPercentage! > 0;
    final weightText = _getWeightDisplay();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Price section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current price
              Text(
                '₹${widget.product.discountedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: hasDiscount ? AppColors.error : Colors.grey[800],
                ),
              ),

              // Original price (if discounted)
              if (hasDiscount)
                Text(
                  '₹${widget.product.originalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
        ),

        // Weight/unit information (right side)
        if (weightText.isNotEmpty)
          Text(
            weightText,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  /// Get weight/unit display text from product
  String _getWeightDisplay() {
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

    // Return empty string if no weight info available
    return '';
  }

  /// Builds the animated quantity controls that expand from + button
  Widget _buildAnimatedQuantityControls(bool isInCart, CartItem? cartItem) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: 36, // Increased height to match ADD button size
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isInCart && cartItem != null
              ? _buildExpandedQuantityControls(cartItem)
              : _buildCollapsedAddButton(),
        );
      },
    );
  }

  /// Builds the expanded quantity controls (-, quantity, +)
  Widget _buildExpandedQuantityControls(CartItem cartItem) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: GestureDetector(
        // Prevent tap events from propagating to the parent card
        onTap: () {
          // Stop propagation by handling the tap here
        },
        // This ensures the gesture detector doesn't interfere with other gestures
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => _updateQuantity(cartItem, cartItem.quantity - 1),
              child: const Icon(
                Icons.remove,
                size: 18, // Increased icon size for better visibility
                color: Colors.white,
              ),
            ),
            GestureDetector(
              // Make the quantity number area also prevent propagation
              onTap: () {
                // Stop propagation - clicking on quantity number should not open product details
              },
              child: Text(
                '${cartItem.quantity}',
                style: const TextStyle(
                  fontSize: 14, // Increased font size for better readability
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _updateQuantity(cartItem, cartItem.quantity + 1),
              child: const Icon(
                Icons.add,
                size: 18, // Increased icon size for better visibility
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the collapsed + button
  Widget _buildCollapsedAddButton() {
    return GestureDetector(
      onTap: _addToCart,
      child: const Center(
        child: Icon(
          Icons.add,
          size: 20, // Increased icon size for collapsed button
          color: Colors.white,
        ),
      ),
    );
  }

  /// Adds product to cart
  void _addToCart() {
    HapticFeedback.lightImpact();

    final isAuthenticated = AuthGuardService.checkAuthAndPrompt(
      context: context,
      ref: ref,
      action: 'add_to_cart',
    );

    if (isAuthenticated) {
      _performAddToCart();
    }
  }

  /// Performs the actual add to cart operation with error handling
  Future<void> _performAddToCart() async {
    try {
      final cartNotifier = ref.read(cartNotifierProvider.notifier);
      await cartNotifier.addToCart(
        product: widget.product,
        quantity: 1,
      );
    } catch (e) {
      // Silent error handling for production - could add user feedback here
      debugPrint('Error adding product to cart: $e');
    }
  }

  /// Updates quantity of existing cart item with error handling
  void _updateQuantity(CartItem cartItem, int newQuantity) {
    HapticFeedback.selectionClick();

    try {
      final cartNotifier = ref.read(cartNotifierProvider.notifier);

      if (newQuantity <= 0) {
        cartNotifier.removeFromCart(cartItemId: cartItem.id);
      } else {
        cartNotifier.updateQuantity(
          cartItemId: cartItem.id,
          quantity: newQuantity,
        );
      }
    } catch (e) {
      // Silent error handling for production - could add user feedback here
      debugPrint('Error updating cart quantity: $e');
    }
  }
}
