import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/product.dart';
import '../../providers/product_providers.dart';

class CleanProductListingScreen extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Set up filters based on parameters
    _initFilters(ref);

    // Watch the products state
    final productsState = ref.watch(productsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref),
          ),
        ],
      ),
      body: _buildBody(context, ref, productsState),
    );
  }

  void _initFilters(WidgetRef ref) {
    // Only set filters if they're not already set or if they've changed
    final currentFilters = ref.read(productFiltersProvider);
    
    if (categoryId != null && currentFilters['categoryId'] != categoryId) {
      ref.read(productFiltersProvider.notifier).update((state) => {
        ...state,
        'categoryId': categoryId,
      });
    }
    
    if (subcategoryId != null && currentFilters['subcategoryId'] != subcategoryId) {
      ref.read(productFiltersProvider.notifier).update((state) => {
        ...state,
        'subcategoryId': subcategoryId,
      });
    }
    
    if (searchQuery != null && currentFilters['searchQuery'] != searchQuery) {
      ref.read(productFiltersProvider.notifier).update((state) => {
        ...state,
        'searchQuery': searchQuery,
      });
    }
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ProductsState state) {
    // Show loading indicator if products are loading
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error message if there is an error
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              state.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Retry loading products with current filters
                final filters = ref.read(productFiltersProvider);
                ref.read(productsNotifierProvider.notifier).updateFilters(filters);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show products if available
    if (state.products.isEmpty) {
      return const Center(
        child: Text('No products found'),
      );
    }

    // Display products in a grid
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: state.products.length,
      itemBuilder: (context, index) {
        final product = state.products[index];
        return _buildProductCard(context, product);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _navigateToProductDetails(context, product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(product.mainImageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (product.discountPercentage != null && product.discountPercentage! > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${product.discountPercentage!.toInt()}% OFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Prices
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Discounted price
                        Text(
                          '₹${product.discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        // Original price (if discounted)
                        if (product.discountPercentage != null && product.discountPercentage! > 0)
                          Text(
                            '₹${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetails(BuildContext context, Product product) {
    // Navigate to product details screen
    Navigator.pushNamed(
      context,
      '/product-details',
      arguments: {
        'productId': product.id,
      },
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