import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/category.dart';

import '../../providers/category_providers.dart';
import '../../widgets/common/navigation_handler.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../product/clean_product_listing_screen.dart';

class CleanCategoriesScreen extends ConsumerWidget {
  const CleanCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // Watch categories async provider
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.appBarSecondary, // Light green tint
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: AppColors.appBarSecondary,
        scrolledUnderElevation: 4,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesList(context, ref, categories),
        loading: () => const LoadingIndicator(message: 'Loading categories...'),
        error: (error, stackTrace) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(categoriesProvider),
        ),
      ),
      bottomNavigationBar: NavigationHandler.createBottomNavBar(
        context: context,
        ref: ref,
        currentIndex: 1, // Categories tab
      ),
    );
  }

  Widget _buildCategoriesList(BuildContext context, WidgetRef ref, List<Category> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState(ref);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategorySection(context, category);
      },
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
            onPressed: () => ref.refresh(categoriesProvider),
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
          child: Text(
            category.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Subcategories grid
        if (category.subCategories != null && category.subCategories!.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.65,
              crossAxisSpacing: 4,
              mainAxisSpacing: 3,
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
    return _BounceCard(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Subcategory image container
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              child: subcategory.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: subcategory.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.category,
                            color: themeColor.withValues(alpha: 0.6),
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.category,
                            color: themeColor.withValues(alpha: 0.6),
                            size: 32,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.category,
                        color: themeColor.withValues(alpha: 0.6),
                        size: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          // Subcategory name
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                subcategory.name,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom widget that provides a bounce effect when tapped
class _BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _BounceCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_BounceCard> createState() => _BounceCardState();
}

class _BounceCardState extends State<_BounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Quick bounce animation for fast taps
    await _animationController.forward();
    await _animationController.reverse();
    widget.onTap();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      onTapDown: _onTapDown,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}