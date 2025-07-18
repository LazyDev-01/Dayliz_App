import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/product_filter.dart';
import '../../providers/product_filter_provider.dart';

/// Widget to display active filter chips
class ActiveFilterChips extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final double? height;

  const ActiveFilterChips({
    Key? key,
    this.padding,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final filterNotifier = ref.read(productFilterProvider.notifier);

    if (!filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      height: height ?? 50,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filter.filters.length + (filter.searchQuery != null ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                // Search query chip
                if (filter.searchQuery != null && index == 0) {
                  return _FilterChip(
                    label: 'Search: "${filter.searchQuery}"',
                    onRemove: () => filterNotifier.updateSearch(null),
                  );
                }
                
                // Filter criteria chips
                final filterIndex = filter.searchQuery != null ? index - 1 : index;
                final criteria = filter.filters[filterIndex];
                
                return _FilterChip(
                  label: criteria.label,
                  onRemove: () => filterNotifier.removeFilter(criteria.type),
                );
              },
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Clear all button
          if (filter.activeFilterCount > 1)
            _ClearAllButton(
              onTap: () => filterNotifier.clearAll(),
            ),
        ],
      ),
    );
  }
}

/// Individual filter chip
class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: theme.primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 14,
                color: theme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clear all filters button
class _ClearAllButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ClearAllButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_all,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Clear All',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for use in app bars or tight spaces
class CompactActiveFilterChips extends ConsumerWidget {
  final int maxChips;
  final EdgeInsetsGeometry? padding;

  const CompactActiveFilterChips({
    Key? key,
    this.maxChips = 2,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productFilterProvider);
    final filterNotifier = ref.read(productFilterProvider.notifier);

    if (!filter.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    final allFilters = [
      if (filter.searchQuery != null)
        FilterCriteria(type: 'search', parameters: {'query': filter.searchQuery}),
      ...filter.filters,
    ];

    final visibleFilters = allFilters.take(maxChips).toList();
    final remainingCount = allFilters.length - visibleFilters.length;

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          ...visibleFilters.map((criteria) {
            final isSearch = criteria.type == 'search';
            final label = isSearch 
              ? 'Search: "${criteria.parameters['query']}"'
              : criteria.label;
            
            return _CompactFilterChip(
              label: label,
              onRemove: () {
                if (isSearch) {
                  filterNotifier.updateSearch(null);
                } else {
                  filterNotifier.removeFilter(criteria.type);
                }
              },
            );
          }),
          
          if (remainingCount > 0)
            _CompactFilterChip(
              label: '+$remainingCount more',
              onRemove: () => filterNotifier.clearAll(),
              isMoreChip: true,
            ),
        ],
      ),
    );
  }
}

/// Compact filter chip for tight spaces
class _CompactFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  final bool isMoreChip;

  const _CompactFilterChip({
    required this.label,
    required this.onRemove,
    this.isMoreChip = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMoreChip 
          ? Colors.grey[100] 
          : theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMoreChip 
            ? Colors.grey[300]! 
            : theme.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isMoreChip 
                  ? Colors.grey[700] 
                  : theme.primaryColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(8),
            child: Icon(
              isMoreChip ? Icons.clear_all : Icons.close,
              size: 12,
              color: isMoreChip 
                ? Colors.grey[600] 
                : theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
