import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CategorySidebar extends StatelessWidget {
  final int itemCount;
  final int selectedIndex;
  final Function(int) onCategorySelected;
  final bool isLoading;

  const CategorySidebar({
    Key? key,
    required this.itemCount,
    required this.selectedIndex,
    required this.onCategorySelected,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return CategorySidebarSkeleton(itemCount: 8);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final bool isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onCategorySelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  width: 3.0,
                ),
              ),
            ),
            child: Text(
              'Category $index',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategorySidebarSkeleton extends StatelessWidget {
  final int itemCount;

  const CategorySidebarSkeleton({
    Key? key,
    required this.itemCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Container(
              height: 16.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SubcategorySkeleton extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;

  const SubcategorySkeleton({
    Key? key,
    this.itemCount = 8,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 12.0),
                Container(
                  width: 80.0,
                  height: 16.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  width: 60.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 