import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/data/mock_products.dart' as mock;
import 'package:dayliz_app/widgets/product_card.dart';

// Provider for the selected subcategory
final selectedSubcategoryProvider = StateProvider<String?>((ref) => null);

// Provider for the sort option
final sortOptionProvider = StateProvider<String>((ref) => 'popularity');

// Provider for the view type (grid or list)
final viewTypeProvider = StateProvider<bool>((ref) => true); // true for grid, false for list

class ProductListingScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String categoryName;
  
  const ProductListingScreen({
    Key? key,
    required this.categoryId,
    required this.categoryName,
  }) : super(key: key);
  
  @override
  ProductListingScreenState createState() => ProductListingScreenState();
}

class ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Product> _products = [];
  List<String> _subcategories = [];
  bool _isLoading = true;
  bool _hasMoreProducts = true;
  int _currentPage = 1;
  final int _productsPerPage = 10;
  
  @override
  void initState() {
    super.initState();
    
    // Load subcategories and initial products
    _loadSubcategories();
    _loadProducts();
    
    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Load subcategories for this category
  void _loadSubcategories() {
    // This would be an API call in a real app
    // For now, we'll generate mock subcategories
    setState(() {
      _subcategories = _getMockSubcategories();
    });
  }
  
  // Load products based on current filters and sorting
  void _loadProducts() {
    // This would be an API call in a real app with proper pagination
    // For now, we'll use mock data
    setState(() {
      _isLoading = true;
    });
    
    // Simulate a network delay
    Future.delayed(const Duration(milliseconds: 800), () {
      final selectedSubcategory = ref.read(selectedSubcategoryProvider);
      final sortOption = ref.read(sortOptionProvider);
      
      // Get products from mock data
      List<Product> newProducts = _getFilteredProducts(
        selectedSubcategory,
        sortOption,
        _currentPage,
        _productsPerPage
      );
      
      setState(() {
        if (_currentPage == 1) {
          _products = newProducts;
        } else {
          _products.addAll(newProducts);
        }
        
        _isLoading = false;
        // Check if there might be more products to load
        _hasMoreProducts = newProducts.length >= _productsPerPage;
      });
    });
  }
  
  // Load more products when scrolling to the bottom
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreProducts) {
      _currentPage++;
      _loadProducts();
    }
  }
  
  // Reset filters and reload products
  void _resetFilters() {
    ref.read(selectedSubcategoryProvider.notifier).state = null;
    ref.read(sortOptionProvider.notifier).state = 'popularity';
    _currentPage = 1;
    _loadProducts();
  }
  
  // Get products with filters applied
  List<Product> _getFilteredProducts(String? subcategory, String sortOption, int page, int perPage) {
    // Start with all products
    List<Product> filteredProducts = mock.mockProducts.where(
      (product) => product.categories?.contains(widget.categoryId) ?? false
    ).toList();
    
    // Apply subcategory filter if selected
    if (subcategory != null && subcategory.isNotEmpty) {
      filteredProducts = filteredProducts.where(
        (product) => product.categories?.contains(subcategory) ?? false
      ).toList();
    }
    
    // Apply sorting
    switch (sortOption) {
      case 'price_low':
        filteredProducts.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filteredProducts.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'newest':
        filteredProducts.sort((a, b) => (b.dateAdded ?? DateTime.now())
            .compareTo(a.dateAdded ?? DateTime.now()));
        break;
      case 'popularity':
      default:
        filteredProducts.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }
    
    // Apply pagination
    int startIndex = (page - 1) * perPage;
    int endIndex = startIndex + perPage;
    if (endIndex > filteredProducts.length) {
      endIndex = filteredProducts.length;
    }
    if (startIndex >= filteredProducts.length) {
      return [];
    }
    
    return filteredProducts.sublist(startIndex, endIndex);
  }
  
  // Generate mock subcategories for the selected category
  List<String> _getMockSubcategories() {
    // In a real app, these would come from an API
    if (widget.categoryId == 'groceries') {
      return ['Fruits', 'Vegetables', 'Dairy', 'Bakery', 'Snacks', 'Beverages'];
    } else if (widget.categoryId == 'electronics') {
      return ['Phones', 'Laptops', 'Tablets', 'Accessories', 'Audio', 'TV'];
    } else if (widget.categoryId == 'fashion') {
      return ['Men', 'Women', 'Kids', 'Footwear', 'Accessories', 'Jewelry'];
    } else {
      return ['Featured', 'New Arrivals', 'Best Sellers', 'Discounted'];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);
    final isGridView = ref.watch(viewTypeProvider);
    
    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // 1. Sticky App Bar
            SliverAppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_products.length} products',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              floating: true,
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // TODO: Implement search within category
                  },
                ),
              ],
            ),
            
            // 2. Subcategory Horizontal Scroll
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 60,
                maxHeight: 60,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _subcategories.length + 1, // +1 for "All" option
                      itemBuilder: (context, index) {
                        // First item is "All"
                        if (index == 0) {
                          return _buildSubcategoryChip(context, null, 'All');
                        }
                        
                        final subcategory = _subcategories[index - 1];
                        return _buildSubcategoryChip(context, subcategory, subcategory);
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // 3. Filter/Sort/View Type Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 50,
                maxHeight: 50,
                child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        // Filter button
                        OutlinedButton.icon(
                          onPressed: () {
                            _showFilterBottomSheet(context);
                          },
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Filter'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Sort dropdown
                        Expanded(
                          child: _buildSortDropdown(),
                        ),
                        
                        // View type toggle
                        IconButton(
                          icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
                          onPressed: () {
                            ref.read(viewTypeProvider.notifier).state = !isGridView;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: _buildProductGrid(isGridView),
        ),
      ),
    );
  }
  
  // Build a subcategory chip button
  Widget _buildSubcategoryChip(BuildContext context, String? subcategoryId, String label) {
    final selectedSubcategory = ref.watch(selectedSubcategoryProvider);
    final isSelected = subcategoryId == selectedSubcategory || 
                       (subcategoryId == null && selectedSubcategory == null);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            ref.read(selectedSubcategoryProvider.notifier).state = subcategoryId;
            _currentPage = 1;
            _loadProducts();
          }
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
  
  // Build the sort dropdown
  Widget _buildSortDropdown() {
    final sortOption = ref.watch(sortOptionProvider);
    
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: sortOption,
        icon: const Icon(Icons.arrow_drop_down),
        isExpanded: true,
        onChanged: (String? newValue) {
          if (newValue != null) {
            ref.read(sortOptionProvider.notifier).state = newValue;
            _currentPage = 1;
            _loadProducts();
          }
        },
        items: <String>[
          'popularity',
          'price_low',
          'price_high',
          'newest',
        ].map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value == 'popularity' ? 'Popularity' : 
              value == 'price_low' ? 'Price: Low to High' : 
              value == 'price_high' ? 'Price: High to Low' : 
              'Newest',
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  // Build the product grid
  Widget _buildProductGrid(bool isGridView) {
    if (_isLoading && _products.isEmpty) {
      return _buildLoadingIndicator();
    }
    
    if (_products.isEmpty) {
      return _buildEmptyState();
    }
    
    return isGridView ? _buildGridView() : _buildListView();
  }
  
  // Build grid view of products
  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _products.length + (_isLoading && _hasMoreProducts ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return _buildLoadingCard();
        }
        
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }
  
  // Build list view of products
  Widget _buildListView() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _products.length + (_isLoading && _hasMoreProducts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _products.length) {
          return _buildLoadingCard();
        }
        
        final product = _products[index];
        return _buildProductListTile(product);
      },
    );
  }
  
  // Build a product card for grid view
  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () {
        // Navigate to product details screen
        Navigator.pushNamed(
          context,
          '/product',
          arguments: {'productId': product.id},
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: AspectRatio(
                aspectRatio: 1, // Square image
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    );
                  },
                ),
              ),
            ),
            
            // Product Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Price
                  Row(
                    children: [
                      if (product.discountedPrice != null) ...[
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '\$${(product.discountedPrice ?? product.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating?.toStringAsFixed(1) ?? "0.0"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Add to Cart button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Add to cart functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a product list tile for list view
  Widget _buildProductListTile(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 40),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Price
                  Row(
                    children: [
                      if (product.discountedPrice != null) ...[
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        '\$${(product.discountedPrice ?? product.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Rating
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating?.toStringAsFixed(1) ?? "0.0"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Add to Cart button
            ElevatedButton(
              onPressed: () {
                // TODO: Add to cart functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added to cart'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a loading indicator card
  Widget _buildLoadingCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
  
  // Build a loading indicator
  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  // Build an empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try changing your filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetFilters,
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
  
  // Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _FilterBottomSheet(
          onApply: () {
            _currentPage = 1;
            _loadProducts();
            Navigator.pop(context);
          },
        );
      },
    );
  }
}

// Filter bottom sheet
class _FilterBottomSheet extends StatelessWidget {
  final VoidCallback onApply;
  
  const _FilterBottomSheet({
    Key? key,
    required this.onApply,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Reset all filters
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          
          // This is a placeholder for filter options
          // In a real app, you would add more filter options here:
          // - Price range slider
          // - Brand selection
          // - Rating filter
          // - In-stock toggle
          // - etc.
          const Text(
            'Price Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Brand',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onApply,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

// Sliver app bar delegate for persistent headers
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;
  
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });
  
  @override
  double get minExtent => minHeight;
  
  @override
  double get maxExtent => maxHeight;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }
  
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
           minHeight != oldDelegate.minHeight ||
           child != oldDelegate.child;
  }
} 