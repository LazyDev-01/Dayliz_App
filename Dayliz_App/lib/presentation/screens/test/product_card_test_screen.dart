import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/product.dart';
import '../../../data/test/test_subcategories.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/product/clean_product_grid.dart';
import '../../widgets/product/category_filter_sidebar.dart';

/// A test screen to showcase the new product card design with real data from Supabase
class ProductCardTestScreen extends ConsumerStatefulWidget {
  const ProductCardTestScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductCardTestScreen> createState() => _ProductCardTestScreenState();
}

class _ProductCardTestScreenState extends ConsumerState<ProductCardTestScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedSubcategory;
  List<String> _subcategories = [];
  String _categoryTitle = 'Products';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch products from Supabase
      final response = await Supabase.instance.client
          .from('products')
          .select('*, categories(*), subcategories(*)')
          .limit(10);

      // Debug the response
      if (response.isEmpty) {
        throw Exception('No products returned from Supabase');
      }

      // Convert to Product entities
      final products = response.map((data) {
        try {
          return _mapToProduct(data);
        } catch (e) {
          // Log the error with the specific product data that caused it
          final productId = data['id'] ?? 'unknown';
          final productName = data['name'] ?? 'unknown';
          throw Exception('Error mapping product $productName ($productId): $e');
        }
      }).toList();

      // Extract unique subcategories and main category title
      final subcategories = <String>{};
      String categoryTitle = 'Products';

      for (final product in products) {
        if (product.subcategoryName != null && product.subcategoryName!.isNotEmpty) {
          subcategories.add(product.subcategoryName!);
        }

        // Use the first product's category name as the title
        if (product.categoryName != null && product.categoryName!.isNotEmpty && categoryTitle == 'Products') {
          categoryTitle = product.categoryName!;
        }
      }

      if (mounted) {
        setState(() {
          _products = List<Product>.from(products);

          // Use subcategories from API if available, otherwise use test data
          if (subcategories.isNotEmpty) {
            _subcategories = subcategories.toList()..sort();
          } else {
            // Use test data based on category name
            _subcategories = TestSubcategories.getSubcategoriesByCategory(categoryTitle);
          }

          _categoryTitle = categoryTitle;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Create a user-friendly error message
        String userMessage = 'Failed to load products';

        // In a production app, you would use a proper logging framework here
        // instead of print statements or showing technical errors to users

        setState(() {
          // For debugging purposes, we'll show the actual error in the UI
          // In production, you would only show userMessage
          _errorMessage = '$userMessage: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // Map Supabase data to Product entity
  Product _mapToProduct(Map<String, dynamic> data) {
    // Extract category and subcategory names if available
    final categoryName = data['categories'] != null ? data['categories']['name'] : '';
    final subcategoryName = data['subcategories'] != null ? data['subcategories']['name'] : '';

    // Safely convert numeric values to double
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Calculate discount percentage if not provided
    double? discountPercentage;
    if (data['discount_percentage'] != null) {
      discountPercentage = safeToDouble(data['discount_percentage']);
    } else if (data['price'] != null && data['discounted_price'] != null) {
      final price = safeToDouble(data['price']);
      final discountedPrice = safeToDouble(data['discounted_price']);
      if (price > 0) {
        discountPercentage = ((price - discountedPrice) / price) * 100;
      }
    }

    // Handle additional images safely
    List<String> additionalImages = [];
    if (data['additional_images'] != null) {
      try {
        additionalImages = List<String>.from(data['additional_images']);
      } catch (e) {
        // Silently handle the error and continue with empty list
        // In a production app, you would use a proper logging framework here
      }
    }

    // Handle tags safely
    List<String> tags = [];
    if (data['tags'] != null) {
      try {
        tags = List<String>.from(data['tags']);
      } catch (e) {
        // Silently handle the error and continue with empty list
        // In a production app, you would use a proper logging framework here
      }
    }

    return Product(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: safeToDouble(data['price']),
      discountPercentage: discountPercentage,
      rating: safeToDouble(data['ratings_avg']),
      reviewCount: data['ratings_count'] ?? 0,
      mainImageUrl: data['main_image_url'] ?? '',
      additionalImages: additionalImages,
      inStock: data['in_stock'] ?? true,
      stockQuantity: data['stock_quantity'] ?? 0,
      categoryId: data['category_id'] ?? '',
      subcategoryId: data['subcategory_id'] ?? '',
      brand: data['brand'] ?? '',
      attributes: data['attributes'] ?? {},
      tags: tags,
      createdAt: data['created_at'] != null ? DateTime.parse(data['created_at'].toString()) : DateTime.now(),
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at'].toString()) : DateTime.now(),
      onSale: data['is_on_sale'] ?? false,
      categoryName: categoryName,
      subcategoryName: subcategoryName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBars.simple(
        title: _categoryTitle,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Listing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Product listing with category filtering (sidebar temporarily disabled)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // Product grid (sidebar temporarily disabled)
          Expanded(
            child: _buildContent(),
          ),

          // Commented out sidebar implementation for future use
          /*
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category filter sidebar
                if (_subcategories.isNotEmpty)
                  CategoryFilterSidebar(
                    subcategories: _subcategories,
                    selectedSubcategory: _selectedSubcategory,
                    onSubcategorySelected: _filterBySubcategory,
                    categoryTitle: _categoryTitle,
                    showAllOption: true,
                    width: 80,
                  ),

                // Product grid
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
          */
        ],
      ),
    );
  }

  /// Filter products by subcategory
  void _filterBySubcategory(String? subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
    });
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading products...');
    }

    if (_errorMessage != null) {
      return ErrorState(
        message: _errorMessage!,
        onRetry: _fetchProducts,
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('No products found'),
      );
    }

    // Filter products by selected subcategory
    final filteredProducts = _selectedSubcategory == null
        ? _products
        : _products.where((p) => p.subcategoryName == _selectedSubcategory).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Text('No products found in $_selectedSubcategory'),
      );
    }

    return CleanProductGrid(
      products: filteredProducts,
      padding: const EdgeInsets.all(16),
    );
  }
}
