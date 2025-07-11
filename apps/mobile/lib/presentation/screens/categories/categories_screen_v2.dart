import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../domain/entities/category.dart';
import '../../providers/category_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/navigation_handler.dart';
import '../product/clean_product_listing_screen.dart';
import '../../widgets/common/skeleton_loaders.dart';

/// Category Screen v2 with horizontal sidebar navigation
/// Features:
/// - Compact horizontal scrollable sidebar for category filtering
/// - 3-column subcategory grid layout
/// - Same functionality as original category screen
/// - Accessible from debug menu
class CategoriesScreenV2 extends ConsumerStatefulWidget {
  const CategoriesScreenV2({Key? key}) : super(key: key);

  @override
  ConsumerState<CategoriesScreenV2> createState() => _CategoriesScreenV2State();
}

class _CategoriesScreenV2State extends ConsumerState<CategoriesScreenV2> {
  String? selectedCategoryId; // null means "All" is selected
  
  @override
  Widget build(BuildContext context) {
    // Watch categories async provider
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: UnifiedAppBars.simple(
        title: 'Categories v2',
      ),
      body: categoriesAsync.when(
        data: (categories) => _buildCategoriesV2Layout(context, categories),
        loading: () => const CategoriesScreenSkeleton(),
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

  Widget _buildCategoriesV2Layout(BuildContext context, List<Category> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    // Get filtered subcategories based on selected category
    final filteredSubcategories = _getFilteredSubcategories(categories);

    return Row(
      children: [
        // Vertical sidebar on the left
        _buildVerticalSidebar(categories),

        // Main content area with subcategories grid
        Expanded(
          child: _buildSubcategoriesGrid(filteredSubcategories),
        ),
      ],
    );
  }

  Widget _buildVerticalSidebar(List<Category> categories) {
    return Container(
      width: 90, // Compact sidebar width
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // "All" button
          _buildVerticalSidebarButton(
            label: 'All',
            icon: Icons.apps,
            isSelected: selectedCategoryId == null,
            onTap: () => _selectCategory(null),
          ),

          // Category buttons
          ...categories.map((category) => _buildVerticalSidebarButton(
            label: category.name,
            icon: category.icon,
            isSelected: selectedCategoryId == category.id,
            onTap: () => _selectCategory(category.id),
          )),
        ],
      ),
    );
  }

  Widget _buildVerticalSidebarButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[800] : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategoriesGrid(List<SubCategory> subcategories) {
    if (subcategories.isEmpty) {
      return _buildNoSubcategoriesState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2-column layout for better breathing space
        childAspectRatio: 0.75, // Reduced to make cards taller (vertical > horizontal)
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final subcategory = subcategories[index];
        return _buildSubcategoryCard(context, subcategory);
      },
    );
  }

  Widget _buildSubcategoryCard(BuildContext context, SubCategory subcategory) {
    return _BounceCard(
      onTap: () {
        // Navigate to product listing with subcategory filter
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CleanProductListingScreen(
              subcategoryId: subcategory.id,
            ),
            settings: RouteSettings(
              arguments: {
                'subcategoryName': subcategory.name,
              },
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            // Subcategory image with breathing space
            Container(
              width: 75,
              height: 75,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: subcategory.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        subcategory.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category,
                          color: Colors.grey[400],
                          size: 30,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: Colors.grey[400],
                      size: 30,
                    ),
            ),
            
            // Subcategory name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                subcategory.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.3, // Better line height for taller cards
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Product count (if available)
            if (subcategory.productCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Text(
                  '${subcategory.productCount} items',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SubCategory> _getFilteredSubcategories(List<Category> categories) {
    if (selectedCategoryId == null) {
      // Show all subcategories
      final allSubcategories = <SubCategory>[];
      for (final category in categories) {
        if (category.subCategories != null) {
          allSubcategories.addAll(category.subCategories!);
        }
      }
      return allSubcategories;
    } else {
      // Show subcategories for selected category
      final selectedCategory = categories.firstWhere(
        (category) => category.id == selectedCategoryId,
        orElse: () => categories.first,
      );
      return selectedCategory.subCategories ?? [];
    }
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      selectedCategoryId = categoryId;
    });
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No categories available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubcategoriesState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey,
          ),
          SizedBox(height: 12),
          Text(
            'No subcategories available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bounce animation widget for subcategory cards
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
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        _controller.reverse();
      },
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
