import 'package:flutter/material.dart';
import '../utils/shimmer.dart';

/// Skeleton loader for banner carousels
class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      height: 180,
      width: MediaQuery.of(context).size.width - 32,
      borderRadius: 12,
    );
  }
}

/// Skeleton loader for product cards
class ProductCardSkeleton extends StatelessWidget {
  final double width;
  
  const ProductCardSkeleton({
    super.key,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ShimmerLoading(
            height: 120,
            width: width,
            borderRadius: 8,
          ),
          const SizedBox(height: 8),
          // Product Name
          ShimmerLoading(
            height: 14,
            width: width * 0.8,
            borderRadius: 4,
          ),
          const SizedBox(height: 4),
          // Product Price
          ShimmerLoading(
            height: 14,
            width: width * 0.5,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for category cards
class CategoryCardSkeleton extends StatelessWidget {
  final double size;
  
  const CategoryCardSkeleton({
    super.key,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Category Icon
        ShimmerLoading(
          height: size,
          width: size,
          borderRadius: size / 2,
        ),
        const SizedBox(height: 8),
        // Category Name
        ShimmerLoading(
          height: 12,
          width: size * 0.8,
          borderRadius: 4,
        ),
      ],
    );
  }
}

/// Skeleton loader for horizontal product list
class ProductListSkeleton extends StatelessWidget {
  final int count;
  
  const ProductListSkeleton({
    super.key,
    this.count = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ProductCardSkeleton(),
          );
        },
      ),
    );
  }
}

/// Skeleton loader for horizontal category list
class CategoryListSkeleton extends StatelessWidget {
  final int count;
  
  const CategoryListSkeleton({
    super.key,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CategoryCardSkeleton(),
          );
        },
      ),
    );
  }
}

/// Skeleton loader for grid of product cards
class ProductGridSkeleton extends StatelessWidget {
  final int columns;
  final int itemCount;
  
  const ProductGridSkeleton({
    super.key,
    this.columns = 2,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        return ProductCardSkeleton(
          width: double.infinity,
        );
      },
    );
  }
} 