import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/widgets/product_card.dart';
import 'package:dayliz_app/widgets/animated_product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dayliz_app/services/product_service.dart';
import 'package:dayliz_app/screens/search/search_screen.dart';
import 'package:dayliz_app/providers/cart_provider.dart';
import 'package:dayliz_app/screens/cart_screen.dart';
import 'dart:isolate';

// State providers for the product listing screen
final selectedSubCategoryProvider = StateProvider<String?>((ref) => null);
final sortOptionProvider = StateProvider<String>((ref) => 'popularity');
final filterOptionsProvider = StateProvider<Map<String, dynamic>>((ref) => {
      'inStock': true,
      'minPrice': 0.0,
      'maxPrice': 1000.0,
      'minRating': 0.0,
      'hasDiscount': false,
      'brands': <String>[],
    });

// Product service provider
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
    });

// A class to hold filter and sort parameters
class FilterSortParams {
  final String? subCategory;
  final String sortOption;
  final Map<String, dynamic> filterOptions;
  final String categoryId;

  FilterSortParams({
    required this.subCategory,
    required this.sortOption,
    required this.filterOptions,
    required this.categoryId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterSortParams &&
        other.subCategory == subCategory &&
        other.sortOption == sortOption &&
        mapEquals(other.filterOptions, filterOptions) &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => 
      subCategory.hashCode ^ 
      sortOption.hashCode ^ 
      filterOptions.hashCode ^
      categoryId.hashCode;
}

// Function to perform filtering and sorting in a separate isolate
List<Product> _filterAndSortProducts(Map<String, dynamic> params) {
  final List<Product> products = params['products'];
  final String? subCategory = params['subCategory'];
  final String sortOption = params['sortOption'];
  final Map<String, dynamic> filterOptions = params['filterOptions'];
  
  // First apply filters
  List<Product> filtered = List.from(products);
  
  // Filter by subcategory if one is selected (other than 'All')
  if (subCategory != null && subCategory != 'All') {
    filtered = filtered.where((product) {
      // Check if the product's categories contain the subcategory
      return product.categories.any((cat) => 
        cat.toLowerCase() == subCategory.toLowerCase());
    }).toList();
  }
  
  // Apply other filters
  filtered = filtered.where((product) {
    // In stock filter
    if (filterOptions['inStock'] && !product.isInStock) {
      return false;
    }
    
    // Price range filter
    final double minPrice = filterOptions['minPrice'];
    final double maxPrice = filterOptions['maxPrice'];
    final double effectivePrice = product.discountPrice ?? product.price;
    if (effectivePrice < minPrice || effectivePrice > maxPrice) {
      return false;
    }
    
    // Rating filter
    final double minRating = filterOptions['minRating'];
    if (product.rating < minRating) {
      return false;
    }
    
    // Discount filter
    final bool hasDiscount = filterOptions['hasDiscount'];
    if (hasDiscount && product.discountPrice == null) {
      return false;
    }
    
    // Brand filter (if any brands are selected)
    final List<String> brands = filterOptions['brands'] ?? [];
    if (brands.isNotEmpty && !brands.contains(product.brand)) {
      return false;
    }
    
    return true;
  }).toList();
  
  // Then sort the results
  switch (sortOption) {
    case 'price_low_high':
      filtered.sort((a, b) {
        final priceA = a.discountPrice ?? a.price;
        final priceB = b.discountPrice ?? b.price;
        return priceA.compareTo(priceB);
      });
      break;
      
    case 'price_high_low':
      filtered.sort((a, b) {
        final priceA = a.discountPrice ?? a.price;
        final priceB = b.discountPrice ?? b.price;
        return priceB.compareTo(priceA);
      });
      break;
      
    case 'newest':
      filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      break;
      
    case 'rating':
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
      break;
      
    case 'popularity':
    default:
      // Default sort by a combination of rating and review count
      filtered.sort((a, b) {
        // Calculate a "popularity score" (rating × review count)
        final scoreA = a.rating * a.reviewCount;
        final scoreB = b.rating * b.reviewCount;
        return scoreB.compareTo(scoreA);
      });
      break;
  }
  
  return filtered;
}

// A simple cache for filtered results
class _FilterCache {
  static final Map<FilterSortParams, List<Product>> _cache = {};
  
  static List<Product>? get(FilterSortParams params) {
    return _cache[params];
  }
  
  static void set(FilterSortParams params, List<Product> products) {
    _cache[params] = products;
  }
  
  static void clear() {
    _cache.clear();
  }
}

class ProductListingScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final Map<String, dynamic>? extraData;

  const ProductListingScreen({
    super.key,
    required this.categoryId,
    this.extraData,
  });

  @override
  ConsumerState<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  List<Product> _allProducts = [];
  List<String> _subCategories = [];
  String _categoryName = '';
  final ScrollController _scrollController = ScrollController();
  bool _showBackToTopButton = false;
  
  // Paging controller for infinite scroll
  static const _pageSize = 10;
  final PagingController<int, Product> _pagingController = 
      PagingController(firstPageKey: 0);

  // Sort options
  final List<String> _sortOptions = [
    'popularity',
    'price_low_high',
    'price_high_low',
    'newest',
    'rating'
  ];

  @override
  void initState() {
    super.initState();
    
    // Extract category name from extraData
    if (widget.extraData != null && widget.extraData!.containsKey('name')) {
      _categoryName = widget.extraData!['name'] as String;
    } else {
      _categoryName = widget.categoryId.replaceAll('_', ' ').toCapitalized();
    }
    
    // Setup scroll controller for back-to-top button
    _scrollController.addListener(_scrollListener);
    
    // Add page request listener to handle pagination
    _pagingController.addPageRequestListener(_fetchPage);
    
    // Load data after widget is built
    Future.microtask(() {
      _loadProducts();
      _loadSubCategories();
    });
  }

  @override
  void didUpdateWidget(ProductListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If category changed, reload data
    if (oldWidget.categoryId != widget.categoryId) {
      _loadProducts();
      _loadSubCategories();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Listen for changes in filters and refresh when they change
    final subCategory = ref.watch(selectedSubCategoryProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final filterOptions = ref.watch(filterOptionsProvider);
    
    // Only refresh if we have products loaded
    if (_allProducts.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
      _pagingController.refresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // Show back to top button when user scrolls down 500 pixels
    if (_scrollController.offset >= 500 && !_showBackToTopButton) {
      setState(() {
        _showBackToTopButton = true;
      });
    } else if (_scrollController.offset < 500 && _showBackToTopButton) {
      setState(() {
        _showBackToTopButton = false;
      });
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadProducts() async {
    try {
      final productService = ref.read(productServiceProvider);
      
      // Check if we're showing products for a specific subcategory
      if (widget.extraData != null && widget.extraData!.containsKey('parentCategory')) {
        // This is a subcategory view, so fetch by subcategory ID
        final products = await productService.getProductsBySubcategory(widget.categoryId);
        
        if (!mounted) return;
        _allProducts = products;
      } else {
        // This is a main category view, fetch by category ID
        final products = await productService.getProductsByCategory(widget.categoryId);
        
        if (!mounted) return;
        
        // If no products found, try to fetch all products as fallback
      if (products.isEmpty) {
          final allProducts = await productService.getAllProducts();
          
          if (!mounted) return;
          _allProducts = allProducts;
      } else {
        _allProducts = products;
        }
      }
      
      // Refresh paging controller to trigger first page load
      _pagingController.refresh();
    } catch (e) {
      print('❌ Error loading products: $e');
      // Only set error if widget is still mounted
      if (mounted) {
      _pagingController.error = e;
      }
    }
  }

  Future<void> _loadSubCategories() async {
    try {
      // Fetch subcategories from Supabase
      List<String> subcategories = ['All'];
      
      if (widget.extraData != null && widget.extraData!.containsKey('parentCategory')) {
        // For a subcategory view, we use predefined subcategories
        setState(() {
          _subCategories = ['All', _categoryName];
        });
        return;
      }
      
      // For a main category, fetch subcategories from database
      final response = await Supabase.instance.client
          .from('subcategories')
          .select('name')
          .eq('category_id', widget.categoryId)
          .order('display_order');
      
      if (response.isNotEmpty) {
        final names = response.map<String>((item) => item['name'] as String).toList();
        subcategories.addAll(names);
      } else {
        // Fallback to hardcoded subcategories if none found
    final Map<String, List<String>> categoryToSubCategories = {
      'fruits': ['All', 'Fresh Fruits', 'Exotic Fruits', 'Organic Fruits'],
      'vegetables': ['All', 'Fresh Vegetables', 'Exotic Vegetables', 'Organic Vegetables'],
      'dairy_bread_eggs': ['All', 'Dairy', 'Bread', 'Eggs', 'Alternatives'],
      'meat': ['All', 'Chicken', 'Mutton', 'Fish', 'Processed'],
      'bakery': ['All', 'Bread', 'Cakes', 'Cookies', 'Pastries'],
      'grocery_kitchen': ['All', 'Staples', 'Spices', 'Oil & Ghee', 'Sauces'],
      'snacks_beverages': ['All', 'Chips', 'Chocolates', 'Soft Drinks', 'Juices'],
      'beauty_hygiene': ['All', 'Skin Care', 'Hair Care', 'Bath Products'],
      'household_essentials': ['All', 'Cleaning', 'Laundry', 'Kitchen Tools'],
      'frozen_food': ['All', 'Ready to Eat', 'Frozen Vegetables', 'Ice Cream'],
    };
    
    // Find the key that most closely matches the categoryId
    String matchedKey = 'fruits'; // Default fallback
    for (final key in categoryToSubCategories.keys) {
      if (widget.categoryId.toLowerCase().contains(key.toLowerCase()) ||
          key.toLowerCase().contains(widget.categoryId.toLowerCase())) {
        matchedKey = key;
        break;
      }
    }
    
        subcategories = categoryToSubCategories[matchedKey] ?? ['All'];
      }
      
      if (!mounted) return;
    setState(() {
        _subCategories = subcategories;
      });
    } catch (e) {
      print('❌ Error fetching subcategories: $e');
      // Fallback to default subcategories
      if (!mounted) return;
      setState(() {
        _subCategories = ['All'];
      });
    }
  }
  
  // Function to fetch a page of filtered products
  Future<void> _fetchPage(int pageKey) async {
    if (!mounted) return;
    
    try {
      final subCategory = ref.read(selectedSubCategoryProvider);
      final sortOption = ref.read(sortOptionProvider);
      final filterOptions = ref.read(filterOptionsProvider);
      
      // Create parameters object for caching
      final params = FilterSortParams(
        subCategory: subCategory,
        sortOption: sortOption,
        filterOptions: Map.from(filterOptions),
        categoryId: widget.categoryId,
      );
      
      // Check if we have a cached result
      List<Product>? cachedProducts = _FilterCache.get(params);
      
      // Ensure we have non-nullable filtered products
      List<Product> filteredProducts;
      
      // If not cached, compute filtered products in isolate
      if (cachedProducts == null) {
        filteredProducts = await compute(
          _filterAndSortProducts,
          {
            'products': _allProducts,
            'subCategory': subCategory,
            'sortOption': sortOption,
            'filterOptions': filterOptions,
          },
        );
        
        // Cache the results
        _FilterCache.set(params, filteredProducts);
      } else {
        filteredProducts = cachedProducts;
      }
      
      // Check if the widget is still mounted before updating UI
      if (!mounted) return;
      
      // Calculate items for this page
      final startIndex = pageKey * _pageSize;
      final endIndex = min(startIndex + _pageSize, filteredProducts.length);
      
      // Check if we've reached the last page
      final isLastPage = endIndex >= filteredProducts.length;
      
      // Get items for the current page
      final items = filteredProducts.sublist(
        startIndex, 
        endIndex,
      );
      
      if (isLastPage) {
        _pagingController.appendLastPage(items);
      } else {
        _pagingController.appendPage(items, pageKey + 1);
      }
    } catch (e) {
      print('❌ Error fetching page: $e');
      if (mounted) {
      _pagingController.error = e;
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    // Get current filter state for display
    final subCategory = ref.watch(selectedSubCategoryProvider);
    final sortOption = ref.watch(sortOptionProvider);
    
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return false;
        } else {
          // If we can't pop, go to home
          context.go('/home');
          return false;
        }
      },
      child: Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar with category title and total count
            SliverAppBar(
              floating: true,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  try {
                      if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                      } else {
                        // If we can't pop (we're at the root), navigate to home
                        context.go('/home');
                      }
                  } catch (e) {
                      // If any error occurs during navigation, go to home as fallback
                    context.go('/home');
                  }
                },
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_categoryName),
                  Consumer(
                    builder: (context, ref, child) {
                      // Only update the count text when it changes
                      return Text(
                        '${_pagingController.itemList?.length ?? 0} products',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      );
                    }
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    // Open SearchScreen with MaterialPageRoute
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final cartItems = ref.watch(cartProvider);
                    return IconButton(
                      icon: Badge(
                        isLabelVisible: cartItems.isNotEmpty,
                        label: Text(
                          cartItems.length.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                      onPressed: () {
                        // Navigate to cart using GoRouter for consistency
                        context.go('/cart');
                      },
                    );
                  }
                ),
              ],
            ),
            
            // Subcategory horizontal scroll
            SliverPersistentHeader(
              pinned: true,
              delegate: _SubcategoryHeaderDelegate(
                subCategories: _subCategories,
                onSubCategorySelected: (subcategory) {
                  ref.read(selectedSubCategoryProvider.notifier).state = subcategory;
                },
                selectedSubCategory: subCategory,
              ),
            ),
            
            // Filter/Sort/Brand section
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterSortHeaderDelegate(
                sortOptions: _sortOptions,
                selectedSortOption: sortOption,
                onSortOptionSelected: (option) {
                  ref.read(sortOptionProvider.notifier).state = option;
                },
                onFilterPressed: () {
                  _showFilterBottomSheet(context);
                },
              ),
            ),
          ];
        },
        body: PagedGridView<int, Product>(
          pagingController: _pagingController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
          ),
          builderDelegate: PagedChildBuilderDelegate<Product>(
            itemBuilder: (context, product, index) {
              return AnimatedProductCard(
                product: product,
                onTap: () {
                  // Navigate to product detail with the product as argument
                  context.go('/product/${product.id}', extra: product);
                },
              );
            },
            firstPageProgressIndicatorBuilder: (_) => _buildLoadingSkeleton(),
            newPageProgressIndicatorBuilder: (_) => _buildPageLoaderIndicator(),
            noItemsFoundIndicatorBuilder: (_) => _buildEmptyState(),
          ),
        ),
      ),
      floatingActionButton: _showBackToTopButton
          ? FloatingActionButton(
              mini: true,
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
            )
          : null,
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 4, // Show fewer items for skeleton
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPageLoaderIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
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
            'Try adjusting your filters or try another category',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Reset all filters
              ref.read(selectedSubCategoryProvider.notifier).state = 'All';
              ref.read(sortOptionProvider.notifier).state = 'popularity';
              ref.read(filterOptionsProvider.notifier).state = {
                'inStock': true,
                'minPrice': 0.0,
                'maxPrice': 1000.0,
                'minRating': 0.0,
                'hasDiscount': false,
                'brands': <String>[],
              };
            },
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final currentFilters = ref.read(filterOptionsProvider);
    
    // Create temporary filter values
    double minPrice = currentFilters['minPrice'];
    double maxPrice = currentFilters['maxPrice'];
    double minRating = currentFilters['minRating'];
    bool inStockOnly = currentFilters['inStock'];
    bool discountedOnly = currentFilters['hasDiscount'];
    List<String> selectedBrands = List<String>.from(currentFilters['brands']);
    
    // Get all unique brands from products
    final allBrands = _allProducts
        .where((product) => product.brand != null)
        .map((product) => product.brand!)
        .toSet()
        .toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Filter Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Reset all filters to default
                              setState(() {
                                minPrice = 0.0;
                                maxPrice = 1000.0;
                                minRating = 0.0;
                                inStockOnly = true;
                                discountedOnly = false;
                                selectedBrands = [];
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const Text(
                              'Price Range',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            RangeSlider(
                              values: RangeValues(minPrice, maxPrice),
                              min: 0,
                              max: 1000,
                              divisions: 100,
                              labels: RangeLabels(
                                '₹${minPrice.toStringAsFixed(2)}',
                                '₹${maxPrice.toStringAsFixed(2)}',
                              ),
                              onChanged: (values) {
                                setState(() {
                                  minPrice = values.start;
                                  maxPrice = values.end;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            const Text(
                              'Minimum Rating',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Slider(
                                    value: minRating,
                                    min: 0,
                                    max: 5,
                                    divisions: 10,
                                    label: minRating.toStringAsFixed(1),
                                    onChanged: (value) {
                                      setState(() {
                                        minRating = value;
                                      });
                                    },
                                  ),
                                ),
                                Text(
                                  minRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('In Stock Only'),
                                    value: inStockOnly,
                                    onChanged: (value) {
                                      setState(() {
                                        inStockOnly = value ?? false;
                                      });
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                Expanded(
                                  child: CheckboxListTile(
                                    title: const Text('Discounted Only'),
                                    value: discountedOnly,
                                    onChanged: (value) {
                                      setState(() {
                                        discountedOnly = value ?? false;
                                      });
                                    },
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                            
                            if (allBrands.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Brands',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...allBrands.map((brand) {
                                return CheckboxListTile(
                                  title: Text(brand),
                                  value: selectedBrands.contains(brand),
                                  onChanged: (value) {
                                    setState(() {
                                      if (value ?? false) {
                                        selectedBrands.add(brand);
                                      } else {
                                        selectedBrands.remove(brand);
                                      }
                                    });
                                  },
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Apply filters and update provider state
                                final updatedFilters = {
                                  'inStock': inStockOnly,
                                  'minPrice': minPrice,
                                  'maxPrice': maxPrice,
                                  'minRating': minRating,
                                  'hasDiscount': discountedOnly,
                                  'brands': selectedBrands,
                                };
                                
                                // Update filters in provider and close sheet
                                ref.read(filterOptionsProvider.notifier).state = updatedFilters;
                                Navigator.pop(context);
                                
                                // The paging controller will refresh due to didChangeDependencies
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Persistent header for subcategories
class _SubcategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> subCategories;
  final Function(String) onSubCategorySelected;
  final String? selectedSubCategory;

  _SubcategoryHeaderDelegate({
    required this.subCategories,
    required this.onSubCategorySelected,
    this.selectedSubCategory,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: subCategories.map((subCategory) {
              final isSelected = selectedSubCategory == subCategory;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton(
                  onPressed: () {
                    onSubCategorySelected(subCategory);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected 
                        ? Colors.green 
                        : Colors.grey[200],
                    foregroundColor: isSelected 
                        ? Colors.white 
                        : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: isSelected ? 2 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    subCategory,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// Persistent header for filter/sort options
class _FilterSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> sortOptions;
  final String selectedSortOption;
  final Function(String) onSortOptionSelected;
  final VoidCallback onFilterPressed;

  _FilterSortHeaderDelegate({
    required this.sortOptions,
    required this.selectedSortOption,
    required this.onSortOptionSelected,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onFilterPressed,
              icon: const Icon(Icons.filter_list),
              label: const Text('Filter'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Sort Dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSortOption,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: sortOptions
                      .map<DropdownMenuItem<String>>((option) => DropdownMenuItem(
                            value: option,
                            child: Text(_getSortOptionName(option)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onSortOptionSelected(value);
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortOptionName(String option) {
    switch (option) {
      case 'popularity':
        return 'Popularity';
      case 'price_low_high':
        return 'Price: Low to High';
      case 'price_high_low':
        return 'Price: High to Low';
      case 'newest':
        return 'Newest First';
      case 'rating':
        return 'Rating';
      default:
        return option.replaceAll('_', ' ').toCapitalized();
    }
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 64;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

// Extension method to capitalize first letter of each word
extension StringExtension on String {
  String toCapitalized() => this.isNotEmpty 
      ? '${this[0].toUpperCase()}${this.substring(1)}'
      : '';
  
  String toTitleCase() => this
      .split('_')
      .map((word) => word.toCapitalized())
      .join(' ');
} 