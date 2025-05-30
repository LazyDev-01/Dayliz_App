import 'package:flutter/material.dart';

/// A sidebar widget for filtering products by subcategory
class CategoryFilterSidebar extends StatelessWidget {
  /// The list of subcategory names to display
  final List<String> subcategories;

  /// The currently selected subcategory
  final String? selectedSubcategory;

  /// Callback when a subcategory is selected
  final Function(String?) onSubcategorySelected;

  /// The title of the main category
  final String categoryTitle;

  /// Whether to show the "ALL" option
  final bool showAllOption;

  /// The width of the sidebar
  final double width;

  /// The background color of the sidebar
  final Color? backgroundColor;

  /// The color of the selected item
  final Color? selectedColor;

  /// The text color of the selected item
  final Color? selectedTextColor;

  const CategoryFilterSidebar({
    Key? key,
    required this.subcategories,
    required this.selectedSubcategory,
    required this.onSubcategorySelected,
    this.categoryTitle = 'Category',
    this.showAllOption = true,
    this.width = 80,
    this.backgroundColor,
    this.selectedColor,
    this.selectedTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSelectedColor = selectedColor ?? theme.primaryColor;
    final effectiveSelectedTextColor = selectedTextColor ?? Colors.white;
    final effectiveBackgroundColor = backgroundColor ?? Colors.grey[100];

    // Create the full list of options, including "ALL" if needed
    final List<String?> options = [
      if (showAllOption) null, // null represents "ALL"
      ...subcategories,
    ];

    return Container(
      width: width,
      color: effectiveBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            color: theme.primaryColor.withOpacity(0.1),
            child: Text(
              categoryTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Subcategory list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final subcategory = options[index];
                final isSelected = selectedSubcategory == subcategory;
                final displayName = subcategory ?? 'ALL';

                return InkWell(
                  onTap: () => onSubcategorySelected(subcategory),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? effectiveSelectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      displayName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected ? effectiveSelectedTextColor : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
