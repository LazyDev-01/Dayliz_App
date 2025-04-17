import 'package:flutter/material.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/widgets/product_card.dart';
import 'package:go_router/go_router.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final String heroTagPrefix;
  
  const ProductGrid({
    Key? key,
    required this.products,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.65,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    this.heroTagPrefix = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductCard(context, index),
      ),
    );
  }
  
  Widget _buildProductCard(BuildContext context, int index) {
    final product = products[index];
    return ProductCard(
      product: product,
      onTap: () => context.go('/product/${product.id}', extra: product),
      onAddToCart: () {
        // TODO: Implement add to cart
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
} 