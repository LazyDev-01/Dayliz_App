import 'package:flutter/material.dart';
import 'skeleton_loading.dart';

/// Skeleton loader for banner carousels
class BannerSkeleton extends StatelessWidget {
  const BannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: SkeletonContainer(
        height: 180,
        width: MediaQuery.of(context).size.width - 32,
        borderRadius: BorderRadius.circular(12),
      ),
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
    return SkeletonLoading(
      isLoading: true,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SkeletonContainer(
              height: 120,
              width: width,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            // Product Name
            SkeletonContainer(
              height: 14,
              width: width * 0.8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            // Product Price
            SkeletonContainer(
              height: 14,
              width: width * 0.5,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
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
    return SkeletonLoading(
      isLoading: true,
      child: Column(
        children: [
          // Category Icon
          SkeletonContainer(
            height: size,
            width: size,
            borderRadius: BorderRadius.circular(size / 2),
          ),
          const SizedBox(height: 8),
          // Category Name
          SkeletonContainer(
            height: 12,
            width: size * 0.8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
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

/// Skeleton loader for cart items
class CartItemSkeleton extends StatelessWidget {
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Product Image
            SkeletonContainer(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonContainer(
                    width: 100,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SkeletonContainer(
                        width: 60,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      SkeletonContainer(
                        width: 80,
                        height: 32,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for address cards
class AddressSkeleton extends StatelessWidget {
  const AddressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonContainer(
                  width: 24,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                SkeletonContainer(
                  width: 80,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const Spacer(),
                SkeletonContainer(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SkeletonContainer(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SkeletonContainer(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for order cards
class OrderSkeleton extends StatelessWidget {
  const OrderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonContainer(
                  width: 100,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                SkeletonContainer(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SkeletonContainer(
              width: 120,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SkeletonContainer(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonContainer(
                  width: 80,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                SkeletonContainer(
                  width: 60,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for payment method cards
class PaymentMethodSkeleton extends StatelessWidget {
  const PaymentMethodSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            SkeletonContainer(
              width: 40,
              height: 24,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonContainer(
                    width: double.infinity,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  SkeletonContainer(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            SkeletonContainer(
              width: 24,
              height: 24,
              borderRadius: BorderRadius.circular(12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for coupon cards
class CouponSkeleton extends StatelessWidget {
  const CouponSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoading(
      isLoading: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonContainer(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      SkeletonContainer(
                        width: 150,
                        height: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                SkeletonContainer(
                  width: 60,
                  height: 32,
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SkeletonContainer(
              width: double.infinity,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SkeletonContainer(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic list skeleton loader
class ListSkeleton extends StatelessWidget {
  final Widget itemSkeleton;
  final int itemCount;
  final EdgeInsets? padding;

  const ListSkeleton({
    super.key,
    required this.itemSkeleton,
    this.itemCount = 5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => itemSkeleton,
    );
  }
}