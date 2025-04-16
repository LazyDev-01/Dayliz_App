import 'package:flutter/material.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class CategoryGridItem {
  final String name;
  final IconData icon;
  
  const CategoryGridItem({
    required this.name,
    required this.icon,
  });
}

class CategoryGrid extends StatelessWidget {
  final List<CategoryGridItem> categories;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  
  const CategoryGrid({
    Key? key,
    required this.categories,
    this.crossAxisCount = 4,
    this.childAspectRatio = 0.75,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding = const EdgeInsets.only(bottom: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
        ),
        itemCount: categories.length,
        padding: padding,
        itemBuilder: (context, index) => _buildCategoryItem(context, index),
      ),
    );
  }
  
  Widget _buildCategoryItem(BuildContext context, int index) {
    final category = categories[index];
    
    return GestureDetector(
      onTap: () => _navigateToCategory(context, category.name),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.primaryLightColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              category.icon,
              color: AppTheme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            category.name,
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
    );
  }
  
  void _navigateToCategory(BuildContext context, String categoryName) {
    context.go(
      '/category/$categoryName',
      extra: {
        'name': categoryName,
      },
    );
  }
} 