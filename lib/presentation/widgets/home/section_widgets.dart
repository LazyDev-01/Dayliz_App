import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/presentation/widgets/home/banner_carousel.dart';
import 'package:dayliz_app/presentation/widgets/home/category_grid.dart';
import 'package:dayliz_app/presentation/widgets/home/product_horizontal_list.dart';
import 'package:dayliz_app/presentation/widgets/home/product_grid.dart';
import 'package:dayliz_app/presentation/widgets/home/section_title.dart';
import 'package:dayliz_app/providers/home_providers.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/models/banner.dart';
import 'package:dayliz_app/presentation/widgets/common/section_title.dart' as ui;
import 'package:dayliz_app/presentation/widgets/product/product_card.dart';
import 'package:dayliz_app/providers/category_providers.dart';

/// Banner section widget for home screen
class BannerSection extends ConsumerWidget {
  const BannerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get loading state
    final isLoading = ref.watch(bannersLoadingProvider);

    // Build widget
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        if (isLoading)
          _buildBannerSkeleton()
        else
          _buildBanners(ref),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildBannerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildBanners(WidgetRef ref) {
    final AsyncValue<List<BannerModel>> bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      data: (banners) => BannerCarousel(banners: banners),
      loading: () => _buildBannerSkeleton(),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading banners: $error'),
      ),
    );
  }
}

/// Featured products section widget for home screen
class FeaturedProductsSection extends ConsumerWidget {
  const FeaturedProductsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get loading state
    final isLoading = ref.watch(featuredProductsLoadingProvider);

    // Force initial fetch
    if (!ref.watch(featuredProductsProvider).hasValue) {
      ref.read(featuredProductsProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ui.SectionTitle(
          title: 'Featured Products',
          onSeeAllPressed: () {
            // TODO: Navigate to featured products page
          },
        ),
        const SizedBox(height: 8),
        if (isLoading)
          _buildProductsSkeleton()
        else
          _buildProducts(ref),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProductsSkeleton() {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 160,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProducts(WidgetRef ref) {
    final AsyncValue<List<Product>> productsAsync = ref.watch(featuredProductsProvider);

    return productsAsync.when(
      data: (products) {
        // Check if products list is empty
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No featured products available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          );
        }

        return SizedBox(
          height: 250, // Reduced from 280
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              // Fix for missing isInWishlist property
              final safeProduct = products[index].copyWith();

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 160, // Reduced from 180
                  child: ProductCard(
                    product: safeProduct,
                    onTap: () {
                      // Navigate to product details
                      Navigator.of(context).pushNamed(
                        '/product-details',
                        arguments: safeProduct,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => _buildProductsSkeleton(),
      error: (error, stack) {
        print("Error loading featured products: $error");
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error loading products: $error'),
        );
      },
    );
  }
}

/// Categories section widget for home screen
class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get loading state
    final isLoading = ref.watch(homeScreenCategoriesLoadingProvider);

    // Force initial fetch
    if (!ref.watch(homeScreenCategoriesProvider).hasValue) {
      ref.read(homeScreenCategoriesProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ui.SectionTitle(
          title: 'Shop by Category',
          onSeeAllPressed: () {
            // TODO: Navigate to categories page
          },
        ),
        const SizedBox(height: 8),
        if (isLoading)
          _buildCategoriesSkeleton()
        else
          _buildCategories(ref),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoriesSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.9,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 8,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategories(WidgetRef ref) {
    final AsyncValue<List<String>> categoriesAsync = ref.watch(homeScreenCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            // Assign icons based on category name
            IconData icon;
            Color color;

            switch (category.toLowerCase()) {
              case 'electronics':
                icon = Icons.devices;
                color = Colors.blue;
                break;
              case 'fashion':
                icon = Icons.shopping_bag;
                color = Colors.purple;
                break;
              case 'beauty':
                icon = Icons.spa;
                color = Colors.pink;
                break;
              case 'home':
                icon = Icons.home;
                color = Colors.teal;
                break;
              case 'grocery':
                icon = Icons.shopping_basket;
                color = Colors.orange;
                break;
              case 'toys':
                icon = Icons.toys;
                color = Colors.red;
                break;
              case 'sports':
                icon = Icons.sports_soccer;
                color = Colors.green;
                break;
              case 'books':
                icon = Icons.book;
                color = Colors.brown;
                break;
              case 'health':
                icon = Icons.favorite;
                color = Colors.red;
                break;
              default:
                icon = Icons.category;
                color = Colors.blueGrey;
            }

            return CategoryGridItem(
              name: category,
              icon: icon,
              color: color,
              onTap: () {
                // TODO: Navigate to category detail
              },
            );
          },
        ),
      ),
      loading: () => _buildCategoriesSkeleton(),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error loading categories: $error'),
      ),
    );
  }
}

// Bottom navigation provider
final currentIndexProvider = StateProvider<int>((ref) => 0);