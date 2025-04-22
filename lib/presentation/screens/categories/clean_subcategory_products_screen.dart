import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/product.dart';
import '../../providers/product_providers.dart';
import '../product/clean_product_details_screen.dart';

class CleanSubcategoryProductsScreen extends ConsumerStatefulWidget {
  final String subcategoryId;
  final String subcategoryName;
  
  const CleanSubcategoryProductsScreen({
    Key? key,
    required this.subcategoryId,
    required this.subcategoryName,
  }) : super(key: key);

  @override
  ConsumerState<CleanSubcategoryProductsScreen> createState() => _CleanSubcategoryProductsScreenState();
}

class _CleanSubcategoryProductsScreenState extends ConsumerState<CleanSubcategoryProductsScreen> {
  // Params for product filtering
  late Map<String, dynamic> _params;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _params = {
      'subcategoryId': widget.subcategoryId,
      'page': 1,
      'limit': 20,
      'sortBy': 'popularity',
      'ascending': false,
    };
    
    // Load products when the screen initializes
    Future.microtask(() {
      if (!_isDisposed) {
        ref.read(productsBySubcategoryProvider(_params).notifier)
          .getProductsBySubcategory(
            subcategoryId: widget.subcategoryId,
            page: _params['page'] as int?,
            limit: _params['limit'] as int?,
            sortBy: _params['sortBy'] as String?,
            ascending: _params['ascending'] as bool?,
          );
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the products for this subcategory
    final productsState = ref.watch(productsBySubcategoryProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subcategoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: _buildBody(context, productsState),
    );
  }

  Widget _buildBody(BuildContext context, ProductsState state) {
    // Show loading state
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.errorMessage}', 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed) {
                  ref.read(productsBySubcategoryProvider(_params).notifier)
                    .getProductsBySubcategory(
                      subcategoryId: widget.subcategoryId,
                      page: _params['page'] as int?,
                      limit: _params['limit'] as int?,
                      sortBy: _params['sortBy'] as String?,
                      ascending: _params['ascending'] as bool?,
                    );
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No products found in this subcategory',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (!_isDisposed) {
                  ref.read(productsBySubcategoryProvider(_params).notifier)
                    .getProductsBySubcategory(
                      subcategoryId: widget.subcategoryId,
                      page: _params['page'] as int?,
                      limit: _params['limit'] as int?,
                      sortBy: _params['sortBy'] as String?,
                      ascending: _params['ascending'] as bool?,
                    );
                }
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Show data state
    return RefreshIndicator(
      onRefresh: () async {
        if (!_isDisposed) {
          ref.read(productsBySubcategoryProvider(_params).notifier)
            .getProductsBySubcategory(
              subcategoryId: widget.subcategoryId,
              page: _params['page'] as int?,
              limit: _params['limit'] as int?,
              sortBy: _params['sortBy'] as String?,
              ascending: _params['ascending'] as bool?,
            );
        }
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: state.products.length,
        itemBuilder: (context, index) {
          final product = state.products[index];
          return _buildProductCard(context, product);
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to product details screen
          if (!_isDisposed) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CleanProductDetailsScreen(productId: product.id),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(product.mainImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: product.discountPercentage != null && product.discountPercentage! > 0
                    ? Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(10),
                            ),
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
                      )
                    : null,
              ),
            ),
            // Product info
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
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
                    // Product price
                    Row(
                      children: [
                        Text(
                          '₹${product.discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        if (product.discountPercentage != null && product.discountPercentage! > 0)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '₹${product.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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

  void _showFilterDialog(BuildContext context) {
    // Create a copy of current params for modification
    final params = Map<String, dynamic>.from(_params);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sort by dropdown
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sort By',
                ),
                value: params['sortBy'] as String,
                items: const [
                  DropdownMenuItem(value: 'popularity', child: Text('Popularity')),
                  DropdownMenuItem(value: 'price', child: Text('Price')),
                  DropdownMenuItem(value: 'newest', child: Text('Newest')),
                  DropdownMenuItem(value: 'rating', child: Text('Rating')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    params['sortBy'] = value;
                  }
                },
              ),
              
              // Sort order
              CheckboxListTile(
                title: const Text('Ascending Order'),
                value: params['ascending'] as bool,
                onChanged: (value) {
                  if (value != null) {
                    params['ascending'] = value;
                  }
                },
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
              // Apply filters and refresh products
              Navigator.pop(context);
              
              if (!_isDisposed) {
                setState(() {
                  _params = params;
                });
                
                // Reuse the provider with the new parameters
                ref.read(productsBySubcategoryProvider(_params).notifier)
                  .getProductsBySubcategory(
                    subcategoryId: widget.subcategoryId,
                    sortBy: _params['sortBy'] as String?,
                    ascending: _params['ascending'] as bool?,
                    limit: _params['limit'] as int?,
                  );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
} 