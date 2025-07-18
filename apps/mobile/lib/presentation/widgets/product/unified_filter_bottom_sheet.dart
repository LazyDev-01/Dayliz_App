import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/product_filter.dart';
import '../../providers/product_filter_provider.dart';

/// Unified filter bottom sheet matching the design reference
/// Combines sorting, filtering, and other options in one clean interface
class UnifiedFilterBottomSheet extends ConsumerStatefulWidget {
  final String? selectedCategory;

  const UnifiedFilterBottomSheet({
    Key? key,
    this.selectedCategory,
  }) : super(key: key);

  @override
  ConsumerState<UnifiedFilterBottomSheet> createState() => _UnifiedFilterBottomSheetState();
}

class _UnifiedFilterBottomSheetState extends ConsumerState<UnifiedFilterBottomSheet> {
  late ProductFilter _localFilter;
  String _selectedLeftCategory = 'Sort';
  bool _hasChanges = false;

  // Available left menu categories
  final List<String> _leftCategories = [
    'Sort',
    'Brand',
    'Type',
    'Quantity',
  ];

  @override
  void initState() {
    super.initState();
    _localFilter = ref.read(productFilterProvider);
    if (widget.selectedCategory != null && _leftCategories.contains(widget.selectedCategory)) {
      _selectedLeftCategory = widget.selectedCategory!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Main content with left menu and right content
          Expanded(
            child: Row(
              children: [
                // Left menu
                Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border(
                      right: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: ListView.builder(
                    itemCount: _leftCategories.length,
                    itemBuilder: (context, index) {
                      final category = _leftCategories[index];
                      final isSelected = category == _selectedLeftCategory;
                      
                      return _LeftMenuItem(
                        title: category,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedLeftCategory = category;
                          });
                        },
                      );
                    },
                  ),
                ),
                
                // Right content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: _buildRightContent(),
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Clear filters button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAllFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Apply button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightContent() {
    switch (_selectedLeftCategory) {
      case 'Sort':
        return _buildSortContent();
      case 'Brand':
        return _buildBrandContent();
      case 'Type':
        return _buildTypeContent();
      case 'Quantity':
        return _buildQuantityContent();
      default:
        return _buildSortContent();
    }
  }

  Widget _buildSortContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8), // Remove title, add spacing

        ...SortOption.values.map((option) {
          final isSelected = _localFilter.sortOption == option;

          return _RadioOption(
            title: option.label,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _localFilter = _localFilter.updateSort(option);
                _hasChanges = true;
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildTypeContent() {
    return const Center(
      child: Text(
        'Type filters\nComing soon...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildQuantityContent() {
    return const Center(
      child: Text(
        'Quantity filters\nComing soon...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildBrandContent() {
    return const Center(
      child: Text(
        'Brand filters\nComing soon...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _localFilter = const ProductFilter.empty();
      _hasChanges = true;
    });
  }

  void _applyFilters() {
    // Apply the filter through the notifier's method
    final notifier = ref.read(productFilterProvider.notifier);
    notifier.updateSort(_localFilter.sortOption);
    // Apply other filters as needed
    Navigator.of(context).pop();
  }
}

/// Left menu item widget
class _LeftMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _LeftMenuItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: isSelected
              ? const Border(
                  left: BorderSide(color: Colors.green, width: 3),
                )
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// Radio option widget
class _RadioOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadioOption({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
