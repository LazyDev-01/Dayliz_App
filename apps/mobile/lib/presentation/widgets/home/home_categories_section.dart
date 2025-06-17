import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/home_categories_config.dart';

/// Home screen categories section with horizontal scrolling
/// Implements hybrid approach with virtual and direct categories
/// Updated with better alignment and spacing
class HomeCategoriesSection extends StatelessWidget {
  const HomeCategoriesSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Horizontal scrolling categories
        SizedBox(
          height: 140, // Increased height for better text alignment
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: HomeCategoriesConfig.homeCategories.length,
            itemBuilder: (context, index) {
              final category = HomeCategoriesConfig.homeCategories[index];
              return _HomeCategoryCard(
                category: category,
                onTap: () => _navigateToProducts(context, category),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Navigate to product listing with appropriate parameters
  void _navigateToProducts(BuildContext context, HomeCategory category) {
    final queryParams = category.queryParams;
    
    // Build query string
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    // Navigate to product listing with query parameters
    final fullUrl = '/products?$queryString';
    context.push(fullUrl);
    
    debugPrint('🏠 CATEGORY: ========== NAVIGATION DEBUG ==========');
    debugPrint('🏠 CATEGORY: Navigating to ${category.name}');
    debugPrint('🏠 CATEGORY: Category ID: ${category.id}');
    debugPrint('🏠 CATEGORY: Is virtual: ${category.isVirtual}');
    debugPrint('🏠 CATEGORY: Subcategory IDs: ${category.subcategoryIds}');
    debugPrint('🏠 CATEGORY: Subcategory names: ${category.subcategoryNames}');
    debugPrint('🏠 CATEGORY: Query params: $queryParams');
    debugPrint('🏠 CATEGORY: Full URL: $fullUrl');
    debugPrint('🏠 CATEGORY: ==========================================');
  }
}

/// Individual home category card widget with improved alignment
class _HomeCategoryCard extends StatelessWidget {
  final HomeCategory category;
  final VoidCallback onTap;

  const _HomeCategoryCard({
    Key? key,
    required this.category,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 95, // Slightly increased width for better text fit
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Category icon with background
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    size: 28,
                    color: category.color,
                  ),
                ),
                
                const SizedBox(height: 12), // Increased spacing
                
                // Category name with better text handling
                Expanded(
                  child: Container(
                    alignment: Alignment.topCenter,
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 3, // Allow up to 3 lines
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11, // Slightly smaller font
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        height: 1.1, // Tighter line height
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
