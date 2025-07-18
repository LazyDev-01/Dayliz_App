import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../domain/entities/category.dart';

import '../../providers/category_providers.dart';
import '../../widgets/common/navigation_handler.dart';
import '../../widgets/common/skeleton_loaders.dart';
import '../../widgets/common/inline_error_widget.dart';
import '../product/clean_product_listing_screen.dart';

/// Optimized Categories Screen with high-performance grid implementation
class OptimizedCategoriesScreen extends ConsumerWidget {
  const OptimizedCategoriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.white,
        scrolledUnderElevation: 4,
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildOptimizedCategoriesList(context, categories),
        loading: () => const CategoriesScreenSkeleton(),
        error: (error, stackTrace) => NetworkErrorWidgets.connectionProblem(
          onRetry: () => ref.refresh(categoriesProvider),
        ),
      ),
      bottomNavigationBar: NavigationHandler.createBottomNavBar(
        context: context,
        ref: ref,
        currentIndex: 1,
      ),
    );
  }

  /// Optimized categories list with proper section layout
  Widget _buildOptimizedCategoriesList(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 16)),
        ...categories.map((category) => _buildCategorySection(context, category)),
      ],
    );
  }

  /// Build optimized category section with proper layout
  Widget _buildCategorySection(BuildContext context, Category category) {
    return SliverMainAxisGroup(
      slivers: [
        // Category header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Subcategories grid
        if (category.subCategories != null && category.subCategories!.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.65,
                crossAxisSpacing: 4,
                mainAxisSpacing: 3,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final subcategory = category.subCategories![index];
                  return RepaintBoundary(
                    child: _buildOptimizedSubcategoryCard(
                      context,
                      subcategory,
                      category.themeColor,
                    ),
                  );
                },
                childCount: category.subCategories!.length,
              ),
            ),
          )
        else
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'No subcategories available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

        // Spacing between sections
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  /// Optimized subcategory card with efficient bounce animations
  Widget _buildOptimizedSubcategoryCard(
    BuildContext context,
    SubCategory subcategory,
    Color themeColor
  ) {
    return _OptimizedBounceCard(
      onTap: () => _navigateToProducts(context, subcategory),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Optimized image container
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(4, 8, 4, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Add breathing space
                child: _buildOptimizedImage(subcategory, themeColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Optimized text
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

  /// Optimized image loading with memory management
  Widget _buildOptimizedImage(SubCategory subcategory, Color themeColor) {
    if (subcategory.imageUrl == null) {
      return _buildPlaceholderIcon(themeColor);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8), // Reduced to match padding
      child: CachedNetworkImage(
        imageUrl: subcategory.imageUrl!,
        fit: BoxFit.cover,
        memCacheWidth: 200, // Limit memory cache size
        memCacheHeight: 200,
        placeholder: (context, url) => _buildPlaceholderIcon(themeColor),
        errorWidget: (context, url, error) => _buildPlaceholderIcon(themeColor),
      ),
    );
  }

  /// Efficient placeholder icon
  Widget _buildPlaceholderIcon(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8), // Reduced to match padding
      ),
      child: Icon(
        Icons.category,
        color: themeColor.withValues(alpha: 0.6),
        size: 32,
      ),
    );
  }

  /// Navigate to products
  void _navigateToProducts(BuildContext context, SubCategory subcategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CleanProductListingScreen(
          subcategoryId: subcategory.id,
        ),
        settings: RouteSettings(
          arguments: {'subcategoryName': subcategory.name},
        ),
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No categories available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Performance-optimized bounce card with instant visual feedback
class _OptimizedBounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _OptimizedBounceCard({
    required this.child,
    required this.onTap,
  });

  @override
  State<_OptimizedBounceCard> createState() => _OptimizedBounceCardState();
}

class _OptimizedBounceCardState extends State<_OptimizedBounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Ultra-fast animation for instant visual feedback
    _controller = AnimationController(
      duration: const Duration(milliseconds: 50), // Ultra fast
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.88, // Very pronounced scale for clear visibility
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut, // Immediate response
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    // Instant scale down
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    // Quick bounce back
    _controller.reverse();
  }

  void _handleTapCancel() {
    // Reset on cancel
    _controller.reverse();
  }

  void _handleTap() {
    // Trigger the actual tap action
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
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