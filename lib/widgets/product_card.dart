import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/services/image_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/providers/wishlist_provider.dart';

/// A modular product image area that handles image loading, discount tags, and wishlist button
class ProductImageArea extends ConsumerWidget {
  final Product product;
  final VoidCallback? onWishlistToggle;
  final bool useHeroAnimation;
  
  // Track last tap time for debounce
  static DateTime? _lastWishlistTap;
  
  const ProductImageArea({
    Key? key,
    required this.product,
    this.onWishlistToggle,
    this.useHeroAnimation = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if product is in wishlist
    final isInWishlist = ref.watch(isInWishlistProvider(product.id));
    
    return Stack(
        fit: StackFit.expand,
        children: [
          // Product image with optimized loading
          imageService.getOptimizedImage(
            imageUrl: product.imageUrl,
          heroTag: useHeroAnimation ? 'product_image_${product.id}' : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            fit: BoxFit.cover,
            // Use 70% quality for thumbnails to save bandwidth
            quality: 70,
          offlineFallback: true,
          ),
          
          // Discount tag if applicable
          if (product.hasDiscount)
            _buildDiscountTag(),
          
          // Wishlist button
          _buildWishlistButton(context, ref, isInWishlist),
        ],
    );
  }
  
  Widget _buildDiscountTag() {
    return Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '-${product.discountPercentage}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  Widget _buildWishlistButton(BuildContext context, WidgetRef ref, bool isInWishlist) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Material(
          color: Colors.transparent,
        child: IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(isInWishlist),
                color: isInWishlist ? Colors.red : Colors.grey[800],
                size: 16,
              ),
            ),
            onPressed: () => _handleWishlistToggle(ref),
            tooltip: isInWishlist ? "Remove from wishlist" : "Add to wishlist",
          color: Colors.grey[800],
            iconSize: 16,
          constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
  
  void _handleWishlistToggle(WidgetRef ref) {
    // Debounce wishlist button taps
    if (_lastWishlistTap == null || 
        DateTime.now().difference(_lastWishlistTap!) > const Duration(milliseconds: 500)) {
      _lastWishlistTap = DateTime.now();
      HapticFeedback.selectionClick();
      
      // Use custom callback if provided
      if (onWishlistToggle != null) {
        onWishlistToggle!();
      } else {
        // Otherwise use the default wishlist provider
        ref.read(wishlistProvider.notifier).toggleWishlist(product);
      }
    }
  }
}

/// A modular product info area that handles product details and pricing
class ProductInfoArea extends StatelessWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final bool isInCart;
  final int quantity;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;
  
  const ProductInfoArea({
    Key? key,
    required this.product,
    this.onAddToCart,
    this.isInCart = false,
    this.quantity = 1,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10.0, 6.0, 10.0, 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Product quantity indicator (weight, volume, etc.)
          Text(
            _getQuantityText(),
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          
          const SizedBox(height: 4),
          
            // Product name
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
              fontSize: 13,
              height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          
            const SizedBox(height: 4),
            const Spacer(),
          const SizedBox(height: 2),
            
            // Price and Add to Cart
            _buildPriceAndCartRow(context),
          ],
        ),
    );
  }
  
  Widget _buildPriceAndCartRow(BuildContext context) {
    // Format price to show only whole numbers if no decimal part
    String formatPrice(double price) {
      // Round up to nearest integer
      final roundedPrice = price.ceil();
      
      // If price is a whole number, show without decimal
      if (price == price.floorToDouble()) {
        return '₹${price.toInt()}';
      }
      
      return '₹$roundedPrice';
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (product.hasDiscount) ...[
          Text(
            formatPrice(product.price),
            style: TextStyle(
              fontSize: 12,
              decoration: TextDecoration.lineThrough,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            formatPrice(product.discountedPrice),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        
        // Add to cart button or quantity control
        isInCart ? _buildQuantityControl(context) : _buildAddButton(context),
      ],
    );
  }
  
  Widget _buildAddButton(BuildContext context) {
    return Container(
      height: 26,
      width: 60,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleAddToCart,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                'Add',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuantityControl(BuildContext context) {
    return Container(
      height: 26,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDecreaseQuantity,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
              ),
              child: SizedBox(
                width: 20,
                height: 24,
                child: Icon(
                  Icons.remove,
                  size: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          
          // Quantity display
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          // Increase button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onIncreaseQuantity,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
              child: SizedBox(
                width: 20,
                height: 24,
                child: Icon(
                  Icons.add,
                  size: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleAddToCart() {
    HapticFeedback.lightImpact();  // Add tactile feedback
    if (onAddToCart != null) {
      onAddToCart!();
    }
  }
  
  String _getQuantityText() {
    // Try to get quantity info from product attributes
    final String? quantityAttr = product.attributes['quantity'] as String?;
    final String? weightAttr = product.attributes['weight'] as String?;
    final String? volumeAttr = product.attributes['volume'] as String?;
    
    if (quantityAttr != null) return quantityAttr;
    if (weightAttr != null) return weightAttr;
    if (volumeAttr != null) return volumeAttr;
    
    // Determine quantity based on product category or name
    if (product.name.toLowerCase().contains('milk')) return '500ml';
    if (product.name.toLowerCase().contains('juice')) return '1L';
    if (product.name.toLowerCase().contains('cheese')) return '200g';
    if (product.name.toLowerCase().contains('butter')) return '100g';
    if (product.name.toLowerCase().contains('yogurt')) return '400g';
    if (product.name.toLowerCase().contains('berries')) return '200g';
    if (product.name.toLowerCase().contains('apple')) return '4 pcs';
    if (product.name.toLowerCase().contains('banana')) return '6 pcs';
    if (product.name.toLowerCase().contains('bread')) return '400g';
    if (product.name.toLowerCase().contains('rice')) return '1kg';
    if (product.name.toLowerCase().contains('oil')) return '1L';
    
    // If no match found, determine by category
    for (final category in product.categories) {
      final String catLower = category.toLowerCase();
      if (catLower.contains('fruit') || catLower.contains('vegetable')) return '500g';
      if (catLower.contains('dairy')) return '500ml';
      if (catLower.contains('beverages')) return '1L';
      if (catLower.contains('snacks')) return '150g';
    }
    
    // Default fallback
    return '1 pc';
  }
}

/// The main product card component
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistToggle;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;
  final bool useAccessibility;
  final bool useHeroAnimation;
  final bool isInCart;
  final int quantity;
  
  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onWishlistToggle,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
    this.useAccessibility = true,
    this.useHeroAnimation = true,
    this.isInCart = false,
    this.quantity = 1,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final card = RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: ProductImageArea(
                    product: product,
                    onWishlistToggle: onWishlistToggle,
                    useHeroAnimation: useHeroAnimation,
                  ),
                ),
                // Add small space between image and info area
                const SizedBox(height: 6),
                Expanded(
                  flex: 3,
                  child: ProductInfoArea(
                    product: product,
                    onAddToCart: onAddToCart,
                    isInCart: isInCart,
                    quantity: quantity,
                    onIncreaseQuantity: onIncreaseQuantity,
                    onDecreaseQuantity: onDecreaseQuantity,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Wrap with semantics if accessibility is enabled
    if (useAccessibility) {
      return Semantics(
        label: _getAccessibilityLabel(),
        hint: "Double tap to view product details",
        child: ExcludeSemantics(child: card),
      );
    }
    
    return card;
  }
  
  // Helper function to format prices consistently
  String formatPrice(double price) {
    // Round up to nearest integer
    final roundedPrice = price.ceil();
    
    // If price is a whole number, show without decimal
    if (price == price.floorToDouble()) {
      return '₹${price.toInt()}';
    }
    
    return '₹$roundedPrice';
  }
  
  String _getAccessibilityLabel() {
    return "${_getQuantityText()}, ${product.name}, " +
      "${product.hasDiscount ? 'on sale for' : 'priced at'} " +
      formatPrice(product.discountedPrice) +
      "${!product.isInStock ? ', Out of stock' : ''}";
  }
  
  // Get the quantity text
  String _getQuantityText() {
    // Try to get quantity info from product attributes
    final String? quantityAttr = product.attributes['quantity'] as String?;
    final String? weightAttr = product.attributes['weight'] as String?;
    final String? volumeAttr = product.attributes['volume'] as String?;
    
    if (quantityAttr != null) return quantityAttr;
    if (weightAttr != null) return weightAttr;
    if (volumeAttr != null) return volumeAttr;
    
    // Determine quantity based on product category or name
    if (product.name.toLowerCase().contains('milk')) return '500ml';
    if (product.name.toLowerCase().contains('juice')) return '1L';
    if (product.name.toLowerCase().contains('cheese')) return '200g';
    if (product.name.toLowerCase().contains('butter')) return '100g';
    if (product.name.toLowerCase().contains('yogurt')) return '400g';
    if (product.name.toLowerCase().contains('berries')) return '200g';
    if (product.name.toLowerCase().contains('apple')) return '4 pcs';
    if (product.name.toLowerCase().contains('banana')) return '6 pcs';
    if (product.name.toLowerCase().contains('bread')) return '400g';
    if (product.name.toLowerCase().contains('rice')) return '1kg';
    if (product.name.toLowerCase().contains('oil')) return '1L';
    
    // If no match found, determine by category
    for (final category in product.categories) {
      final String catLower = category.toLowerCase();
      if (catLower.contains('fruit') || catLower.contains('vegetable')) return '500g';
      if (catLower.contains('dairy')) return '500ml';
      if (catLower.contains('beverages')) return '1L';
      if (catLower.contains('snacks')) return '150g';
    }
    
    // Default fallback
    return '1 pc';
  }
}

/// A horizontal list tile variation of the product card
class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistToggle;
  final VoidCallback? onIncreaseQuantity;
  final VoidCallback? onDecreaseQuantity;
  final bool useAccessibility;
  final bool isInCart;
  final int quantity;
  
  const ProductListTile({
    Key? key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.onWishlistToggle,
    this.onIncreaseQuantity,
    this.onDecreaseQuantity,
    this.useAccessibility = true,
    this.isInCart = false,
    this.quantity = 1,
  }) : super(key: key);
  
  // Helper function to format prices consistently
  String formatPrice(double price) {
    // Round up to nearest integer
    final roundedPrice = price.ceil();
    
    // If price is a whole number, show without decimal
    if (price == price.floorToDouble()) {
      return '₹${price.toInt()}';
    }
    
    return '₹$roundedPrice';
  }
  
  // Get the quantity text similar to ProductInfoArea
  String _getQuantityText() {
    // Try to get quantity info from product attributes
    final String? quantityAttr = product.attributes['quantity'] as String?;
    final String? weightAttr = product.attributes['weight'] as String?;
    final String? volumeAttr = product.attributes['volume'] as String?;
    
    if (quantityAttr != null) return quantityAttr;
    if (weightAttr != null) return weightAttr;
    if (volumeAttr != null) return volumeAttr;
    
    // Determine quantity based on product category or name
    if (product.name.toLowerCase().contains('milk')) return '500ml';
    if (product.name.toLowerCase().contains('juice')) return '1L';
    if (product.name.toLowerCase().contains('cheese')) return '200g';
    if (product.name.toLowerCase().contains('butter')) return '100g';
    if (product.name.toLowerCase().contains('yogurt')) return '400g';
    if (product.name.toLowerCase().contains('berries')) return '200g';
    if (product.name.toLowerCase().contains('apple')) return '4 pcs';
    if (product.name.toLowerCase().contains('banana')) return '6 pcs';
    if (product.name.toLowerCase().contains('bread')) return '400g';
    if (product.name.toLowerCase().contains('rice')) return '1kg';
    if (product.name.toLowerCase().contains('oil')) return '1L';
    
    // If no match found, determine by category
    for (final category in product.categories) {
      final String catLower = category.toLowerCase();
      if (catLower.contains('fruit') || catLower.contains('vegetable')) return '500g';
      if (catLower.contains('dairy')) return '500ml';
      if (catLower.contains('beverages')) return '1L';
      if (catLower.contains('snacks')) return '150g';
    }
    
    // Default fallback
    return '1 pc';
  }
  
  @override
  Widget build(BuildContext context) {
    final listTile = RepaintBoundary(
        child: Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        child: InkWell(
          onTap: onTap,
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
        width: 80,
        height: 80,
                  child: ProductImageArea(
                    product: product,
                    onWishlistToggle: onWishlistToggle,
                    useHeroAnimation: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      // Quantity text
          Text(
                        _getQuantityText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      
                      // Product info
                      Expanded(
                        child: ProductInfoArea(
                          product: product,
                          onAddToCart: onAddToCart,
                          isInCart: isInCart,
                          quantity: quantity,
                          onIncreaseQuantity: onIncreaseQuantity,
                          onDecreaseQuantity: onDecreaseQuantity,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    // Wrap with semantics if accessibility is enabled
    if (useAccessibility) {
      return Semantics(
        label: "${_getQuantityText()}, ${product.name}, ${product.hasDiscount ? 'on sale for' : 'priced at'} ${formatPrice(product.discountedPrice)}",
        hint: "Double tap to view product details",
        child: ExcludeSemantics(child: listTile),
      );
    }
    
    return listTile;
  }
}

/// Extension to add wishlist property to Product model
extension ProductWishlistExtension on Product {
  bool? get isInWishlist => attributes['isInWishlist'] as bool?;
} 