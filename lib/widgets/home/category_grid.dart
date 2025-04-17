import 'package:flutter/material.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class CategoryGridItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const CategoryGridItem({
    super.key,
    required this.name,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
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
    
    return CategoryGridItem(
      name: category.name,
      icon: category.icon,
      onTap: () => _navigateToCategory(context, category.name),
      color: AppTheme.primaryColor,
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