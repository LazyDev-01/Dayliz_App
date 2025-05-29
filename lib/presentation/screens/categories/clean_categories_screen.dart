import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/category.dart';
import '../../providers/cart_providers.dart';
import '../../providers/category_providers_simple.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/common/common_bottom_nav_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../product/clean_product_listing_screen.dart';

class CleanCategoriesScreen extends ConsumerWidget {
  const CleanCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart item count for badge
    final cartItemCount = ref.watch(cartItemCountProvider);

    // Watch categories async provider
    final categoriesAsync = ref.watch(categoriesSimpleProvider);

    // Set the current index for the bottom navigation bar
    ref.read(bottomNavIndexProvider.notifier).state = 1; // 1 is for Categories

    return Scaffold(
      appBar: CommonAppBars.simple(
        title: 'Categories',
        centerTitle: true,
        showShadow: false,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesList(context, ref, categories),
        loading: () => const LoadingIndicator(message: 'Loading categories...'),
        error: (error, stackTrace) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(categoriesSimpleProvider),
        ),
      ),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: 1, // Categories tab
        cartItemCount: cartItemCount,
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, WidgetRef ref, List<Category> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState(ref);
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(categoriesSimpleProvider);
        await ref.read(categoriesSimpleProvider.future);
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategorySection(context, category);
        },
      ),
    );
  }

  Widget _buildEmptyState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No categories available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.refresh(categoriesSimpleProvider),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }



  Widget _buildCategorySection(BuildContext context, Category category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Icon(
                category.icon,
                color: category.themeColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Subcategories grid
        if (category.subCategories != null && category.subCategories!.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 12,
            ),
            itemCount: category.subCategories!.length,
            itemBuilder: (context, index) {
              final subcategory = category.subCategories![index];
              return _buildSubcategoryCard(context, subcategory, category.themeColor);
            },
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No subcategories available',
              style: TextStyle(color: Colors.grey),
            ),
          ),

        // Add some spacing between sections
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubcategoryCard(BuildContext context, SubCategory subcategory, Color themeColor) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product listing with subcategory filter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CleanProductListingScreen(
                subcategoryId: subcategory.id,
              ),
              // Pass the subcategory name as route arguments
              settings: RouteSettings(
                arguments: {
                  'subcategoryName': subcategory.name,
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subcategory image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: themeColor.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: subcategory.imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          subcategory.imageUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.category,
                              color: themeColor.withAlpha(150),
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.category,
                        color: themeColor.withAlpha(150),
                        size: 30,
                      ),
              ),
              const SizedBox(height: 8),
              // Subcategory name
              Text(
                subcategory.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

}