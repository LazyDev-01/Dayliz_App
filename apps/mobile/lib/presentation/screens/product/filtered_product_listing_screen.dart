import 'package:flutter/material.dart';

import 'clean_product_listing_screen.dart';

/// Wrapper screen that enables filtering for testing the new filter system
class FilteredProductListingScreen extends StatelessWidget {
  final String? categoryId;
  final String? subcategoryId;
  final List<String>? subcategoryIds;
  final String? searchQuery;
  final String? title;
  final bool isVirtual;

  const FilteredProductListingScreen({
    Key? key,
    this.categoryId,
    this.subcategoryId,
    this.subcategoryIds,
    this.searchQuery,
    this.title,
    this.isVirtual = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CleanProductListingScreen(
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      subcategoryIds: subcategoryIds,
      searchQuery: searchQuery,
      title: title,
      isVirtual: isVirtual,
      enableFiltering: true, // Enable the new filtering system
    );
  }
}

/// Factory methods for easy navigation
class FilteredProductRoutes {
  /// Navigate to filtered products by category
  static void navigateToCategory(
    BuildContext context, {
    required String categoryId,
    String? title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilteredProductListingScreen(
          categoryId: categoryId,
          title: title ?? 'Products',
        ),
      ),
    );
  }

  /// Navigate to filtered products by subcategory
  static void navigateToSubcategory(
    BuildContext context, {
    required String subcategoryId,
    String? categoryId,
    String? title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilteredProductListingScreen(
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          title: title ?? 'Products',
        ),
      ),
    );
  }

  /// Navigate to filtered search results
  static void navigateToSearch(
    BuildContext context, {
    required String searchQuery,
    String? title,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FilteredProductListingScreen(
          searchQuery: searchQuery,
          title: title ?? 'Search Results',
        ),
      ),
    );
  }

  /// Navigate to all products with filtering
  static void navigateToAllProducts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FilteredProductListingScreen(
          title: 'All Products',
        ),
      ),
    );
  }
}
