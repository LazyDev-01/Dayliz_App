import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/services/image_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  
  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
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
              _buildProductImage(),
              _buildProductInfo(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductImage() {
    return Expanded(
      flex: 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Product image with optimized loading
          imageService.getOptimizedImage(
            imageUrl: product.imageUrl,
            heroTag: 'product_image_${product.id}',
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            fit: BoxFit.cover,
            // Use 70% quality for thumbnails to save bandwidth
            quality: 70,
          ),
          
          // Discount tag if applicable
          if (product.hasDiscount)
            _buildDiscountTag(),
          
          // Wishlist button
          _buildWishlistButton(),
        ],
      ),
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
  
  Widget _buildWishlistButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // TODO: Implement wishlist functionality
          },
          color: Colors.grey[800],
          iconSize: 20,
          constraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 30,
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
  
  Widget _buildProductInfo(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 4),
            
            // Rating
            if (product.rating != null)
              _buildRating(),
            
            const Spacer(),
            
            // Price and Add to Cart
            _buildPriceAndCartRow(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRating() {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        const SizedBox(width: 2),
        Text(
          product.rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceAndCartRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (product.hasDiscount) ...[
          Text(
            '\$${product.price.toStringAsFixed(2)}',
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
            '\$${(product.discountedPrice).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        
        // Add to cart button
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 18),
            onPressed: onAddToCart,
            constraints: const BoxConstraints(
              minWidth: 30,
              minHeight: 30,
            ),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class ProductListTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  
  const ProductListTile({
    Key? key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        child: Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProductImage(),
                const SizedBox(width: 12),
                
                // Product Info
                _buildProductInfo(context),
                
                // Add to Cart button
                _buildAddToCartButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Hero(
          tag: 'product_image_${product.id}',
          child: imageService.getOptimizedImage(
            imageUrl: product.imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            quality: 70,
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductInfo(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          
          // Price and Rating
          Row(
            children: [
              // Price
              if (product.hasDiscount) ...[
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                '\$${(product.discountPrice ?? product.price).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              
              // Rating
              if (product.rating != null) ...[
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text(
                  product.rating!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddToCartButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onAddToCart,
      icon: const Icon(Icons.add_shopping_cart, size: 16),
      label: const Text('Add'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(80, 36),
      ),
    );
  }
} 