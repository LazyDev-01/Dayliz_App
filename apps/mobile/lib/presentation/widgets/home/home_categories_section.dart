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
                'What are you looking for?',
                style: TextStyle(
                  fontSize: 16,
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
        
        // Horizontal scrolling categories with partial 5th icon visibility
        SizedBox(
          height: 120, // Reduced height for compact design with 4 icons + partial 5th
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // Calculated padding to show exactly 4 full icons + partial 5th icon
            padding: EdgeInsets.only(
              left: 16,
              right: MediaQuery.of(context).size.width * 0.15, // Show ~15% of 5th icon
            ),
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
      width: 75, // Further reduced width for tighter layout
      margin: const EdgeInsets.symmetric(horizontal: 2), // Reduced gap between cards
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
                  width: 58, // Increased size for better visibility while keeping card size same
                  height: 58,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category.color.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    category.icon,
                    size: 26, // Increased icon size to match container
                    color: category.color,
                  ),
                ),
                
                const SizedBox(height: 8), // Reduced spacing for compact design

                // Category name with better text handling
                Expanded(
                  child: Container(
                    alignment: Alignment.topCenter,
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 2, // Reduced to 2 lines for compact design
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10, // Smaller font for compact design
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
