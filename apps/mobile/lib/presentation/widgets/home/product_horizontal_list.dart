import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/product.dart';
import '../../../core/constants/app_colors.dart';

class ProductHorizontalList extends StatelessWidget {
  final List<Product> products;
  final double height;
  final double itemWidth;
  final EdgeInsets padding;
  final VoidCallback? onSeeAllPressed;
  final String heroTagPrefix;

  const ProductHorizontalList({
    Key? key,
    required this.products,
    this.height = 230,
    this.itemWidth = 160,
    this.padding = const EdgeInsets.only(bottom: 8, right: 4),
    this.onSeeAllPressed,
    this.heroTagPrefix = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: height,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: products.length,
          padding: padding,
          itemBuilder: (context, index) => _buildProductItem(context, index),
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, int index) {
    final product = products[index];
    final heroTag = heroTagPrefix.isEmpty
      ? 'product_${product.id}'
      : '${heroTagPrefix}_${product.id}';

    return Container(
      width: itemWidth,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => context.go('/clean/product/${product.id}', extra: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            _buildProductImage(product, heroTag),
            const SizedBox(height: 8),
            // Product Name
            _buildProductName(product),
            // Price and Rating
            _buildPriceAndRating(context, product),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product, String heroTag) {
    return Stack(
      children: [
        Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: product.mainImageUrl,
              width: itemWidth,
              height: itemWidth,
              fit: BoxFit.cover,
              memCacheWidth: 300,
              memCacheHeight: 300,
              placeholder: (context, url) => Container(
                width: itemWidth,
                height: itemWidth,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: itemWidth,
                height: itemWidth,
                color: Colors.grey[200],
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.grey,
                ),
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${product.discountPercentage?.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductName(Product product) {
    return Text(
      product.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPriceAndRating(BuildContext context, Product product) {
    return Row(
      children: [
        // Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.discountPercentage != null && product.discountPercentage! > 0)
              Text(
                '₹${product.originalPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey[600],
                ),
              ),
            Text(
              '₹${product.discountedPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Rating
        if (product.rating != null)
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                product.rating?.toStringAsFixed(1) ?? '0.0',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
}