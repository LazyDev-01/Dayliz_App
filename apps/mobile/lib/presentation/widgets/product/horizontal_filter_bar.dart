import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/product_filter.dart';
import '../../providers/product_filter_provider.dart';
import 'unified_filter_bottom_sheet.dart';

/// Horizontal scrollable filter bar with multiple filter options
class HorizontalFilterBar extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const HorizontalFilterBar({
    Key? key,
    this.padding,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);

    return Container(
      height: 50,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Filter button (only one with icon)
          _FilterChip(
            label: 'Filter',
            icon: Icons.filter_list,
            hasActiveFilters: filter.filters.isNotEmpty,
            activeCount: filter.filters.length,
            onTap: () => _showUnifiedFilterSheet(context, 'Filter'),
          ),

          const SizedBox(width: 8),

          // Sort button (includes price sorting now)
          _FilterChip(
            label: 'Sort',
            hasActiveFilters: filter.sortOption != SortOption.relevance,
            onTap: () => _showUnifiedFilterSheet(context, 'Sort'),
          ),

          const SizedBox(width: 8),

          // Brand button
          _FilterChip(
            label: 'Brand',
            hasActiveFilters: _hasBrandFilter(filter),
            onTap: () => _showUnifiedFilterSheet(context, 'Brand'),
          ),

          const SizedBox(width: 8),

          // Type button (renamed from "Category")
          _FilterChip(
            label: 'Type',
            hasActiveFilters: _hasTypeFilter(filter),
            onTap: () => _showUnifiedFilterSheet(context, 'Type'),
          ),

          const SizedBox(width: 8),

          // Quantity button
          _FilterChip(
            label: 'Quantity',
            hasActiveFilters: _hasQuantityFilter(filter),
            onTap: () => _showUnifiedFilterSheet(context, 'Quantity'),
          ),

          const SizedBox(width: 16), // Extra padding at the end
        ],
      ),
    );
  }

  void _showUnifiedFilterSheet(BuildContext context, String selectedCategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UnifiedFilterBottomSheet(
        selectedCategory: selectedCategory,
      ),
    );
  }

  String _getSortLabel(SortOption sortOption) {
    switch (sortOption) {
      case SortOption.relevance:
        return 'Relevance';
      case SortOption.priceLowToHigh:
        return 'Price ↑';
      case SortOption.priceHighToLow:
        return 'Price ↓';
      case SortOption.discounts:
        return 'Discounts';
    }
  }

  bool _hasBrandFilter(ProductFilter filter) {
    return filter.filters.any((f) => f.type == 'brand');
  }

  bool _hasTypeFilter(ProductFilter filter) {
    return filter.filters.any((f) => f.type == 'type');
  }

  bool _hasQuantityFilter(ProductFilter filter) {
    return filter.filters.any((f) => f.type == 'quantity');
  }
}

/// Individual filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon; // Made optional
  final bool hasActiveFilters;
  final int? activeCount;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    this.icon, // Made optional
    required this.hasActiveFilters,
    this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasActiveFilters 
            ? theme.primaryColor.withOpacity(0.1) 
            : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActiveFilters 
              ? theme.primaryColor.withOpacity(0.3) 
              : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon!,
                size: 16,
                color: hasActiveFilters
                  ? theme.primaryColor
                  : Colors.grey[600],
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: hasActiveFilters
                  ? theme.primaryColor
                  : Colors.grey[700],
              ),
            ),
            if (hasActiveFilters && activeCount != null && activeCount! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Show unified filter bottom sheet
void showUnifiedFilterBottomSheet(BuildContext context, {String? selectedCategory}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => UnifiedFilterBottomSheet(
      selectedCategory: selectedCategory,
    ),
  );
}
