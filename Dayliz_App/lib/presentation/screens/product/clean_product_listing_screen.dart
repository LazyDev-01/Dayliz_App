import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/product.dart';
import '../../../data/test/test_subcategories.dart';
import '../../providers/product_providers.dart';
import '../../widgets/common/common_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/product/clean_product_grid.dart';
import '../../widgets/product/category_filter_sidebar.dart';

class CleanProductListingScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? subcategoryId;
  final String? searchQuery;

  const CleanProductListingScreen({
    Key? key,
    this.categoryId,
    this.subcategoryId,
    this.searchQuery,
  }) : super(key: key);

  @override
  ConsumerState<CleanProductListingScreen> createState() => _CleanProductListingScreenState();
}

class _CleanProductListingScreenState extends ConsumerState<CleanProductListingScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedSubcategory;
  List<String> _subcategories = [];
  String _categoryTitle = 'Products';

  @override
  void initState() {
    super.initState();
    // Initialize filters in initState instead of build
    Future.microtask(() {
      if (mounted) {
        _initFilters();
        _fetchProducts();
      }
    });
  }

  @override
  void didUpdateWidget(CleanProductListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initialize filters if the widget parameters change
    if (oldWidget.categoryId != widget.categoryId ||
        oldWidget.subcategoryId != widget.subcategoryId ||
        oldWidget.searchQuery != widget.searchQuery) {
      // Use a microtask to ensure the context is available
      Future.microtask(() {
        if (mounted) {
          _initFilters();
          _fetchProducts();
        }
      });
    }
  }

  Future<void> _fetchProducts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Build query with proper filtering
      var query = Supabase.instance.client
          .from('products')
          .select('*, categories(*), subcategories(*)');

      // Apply subcategory filter if provided
      if (widget.subcategoryId != null) {
        debugPrint('CleanProductListingScreen: Filtering by subcategory ID: ${widget.subcategoryId}');
        query = query.eq('subcategory_id', widget.subcategoryId!);
      }

      // Apply category filter if provided (and no subcategory filter)
      else if (widget.categoryId != null) {
        debugPrint('CleanProductListingScreen: Filtering by category ID: ${widget.categoryId}');
        query = query.eq('category_id', widget.categoryId!);
      }

      // Apply search filter if provided
      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        debugPrint('CleanProductListingScreen: Filtering by search query: ${widget.searchQuery}');
        query = query.ilike('name', '%${widget.searchQuery}%');
      }

      // Execute the query with limit
      final response = await query.limit(20);

      debugPrint('CleanProductListingScreen: Query returned ${response.length} products');

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

      // Set the selected subcategory if we're filtering by subcategory
      if (widget.subcategoryId != null && products.isNotEmpty && mounted) {
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        final subcategoryName = (routeArgs as Map<String, dynamic>?)?['subcategoryName'] as String?;
        _selectedSubcategory = subcategoryName ?? products.first.subcategoryName;
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

        setState(() {
          // For debugging purposes, we'll show the actual error in the UI
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
      }
    }

    // Handle tags safely
    List<String> tags = [];
    if (data['tags'] != null) {
      try {
        tags = List<String>.from(data['tags']);
      } catch (e) {
        // Silently handle the error and continue with empty list
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
    // Determine the title based on parameters
    String title = _categoryTitle;

    if (widget.subcategoryId != null && widget.searchQuery == null) {
      // If we have a subcategory ID but no search query, use the subcategory name if available
      if (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty) {
        title = _selectedSubcategory!;
      }
    } else if (widget.searchQuery != null) {
      // If we have a search query, show "Search Results"
      title = 'Search Results';
    }

    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: title,
        centerTitle: true,
        showShadow: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  void _initFilters() {
    // Only set filters if they're not already set or if they've changed
    final currentFilters = ref.read(productFiltersProvider);

    if (widget.categoryId != null && currentFilters['categoryId'] != widget.categoryId) {
      ref.read(productFiltersProvider.notifier).update((state) => {
        ...state,
        'categoryId': widget.categoryId,
      });
    }

    if (widget.subcategoryId != null && currentFilters['subcategoryId'] != widget.subcategoryId) {
      // Get the subcategory name from the constructor parameter or route arguments
      final routeArgs = ModalRoute.of(context)?.settings.arguments;
      final subcategoryName = (routeArgs as Map<String, dynamic>?)?['subcategoryName'] as String?;

      // Update the filters with the subcategory information
      ref.read(productFiltersProvider.notifier).update((state) => {
        ...state,
        'subcategoryId': widget.subcategoryId,
        'subcategoryName': subcategoryName ?? state['subcategoryName'] ?? 'Products',
      });
    }

    if (widget.searchQuery != null && currentFilters['searchQuery'] != widget.searchQuery) {
      ref.read(productFiltersProvider.notifier).update((state) => {
        ...state,
        'searchQuery': widget.searchQuery,
      });
    }
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

    // Products are already filtered at the database level, no need for client-side filtering
    return CleanProductGrid(
      products: _products,
      padding: const EdgeInsets.all(16),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    // Get current filters
    final currentFilters = ref.read(productFiltersProvider);
    String? selectedSortBy = currentFilters['sortBy'];
    bool? isAscending = currentFilters['ascending'];
    double? minPrice = currentFilters['minPrice'];
    double? maxPrice = currentFilters['maxPrice'];

    // Show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sort by options
              const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSortOption(context, 'Price', 'price', selectedSortBy, (value) => selectedSortBy = value),
              _buildSortOption(context, 'Popularity', 'popularity', selectedSortBy, (value) => selectedSortBy = value),
              _buildSortOption(context, 'Rating', 'rating', selectedSortBy, (value) => selectedSortBy = value),
              _buildSortOption(context, 'Newest', 'createdAt', selectedSortBy, (value) => selectedSortBy = value),

              const SizedBox(height: 16),

              // Ascending/descending options
              Row(
                children: [
                  const Text('Order:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text('Ascending'),
                    selected: isAscending == true,
                    onSelected: (selected) => isAscending = selected ? true : false,
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Descending'),
                    selected: isAscending == false,
                    onSelected: (selected) => isAscending = selected ? false : true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Price range
              const Text('Price range:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => minPrice = double.tryParse(value),
                      controller: TextEditingController(text: minPrice?.toString() ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => maxPrice = double.tryParse(value),
                      controller: TextEditingController(text: maxPrice?.toString() ?? ''),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Apply the filters
              ref.read(productFiltersProvider.notifier).update((state) => {
                ...state,
                'sortBy': selectedSortBy,
                'ascending': isAscending,
                'minPrice': minPrice,
                'maxPrice': maxPrice,
                // Reset page to 1 when applying new filters
                'page': 1,
              });

              // Close the dialog
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String label,
    String value,
    String? selectedValue,
    Function(String) onChanged,
  ) {
    return RadioListTile<String>(
      title: Text(label),
      value: value,
      groupValue: selectedValue,
      onChanged: (newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      dense: true,
    );
  }
}