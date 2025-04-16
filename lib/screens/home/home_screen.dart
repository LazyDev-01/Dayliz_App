import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/widgets/product_card.dart';
import 'package:dayliz_app/data/mock_products.dart' as mock;
import 'package:dayliz_app/models/product.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final List<String> _searchSuggestions = [
    'Organic Vegetables',
    'Fresh Fruits',
    'Dairy Products',
    'Bakery Items',
    'Meat and Seafood'
  ];
  bool _showSuggestions = false;
  int _currentBannerIndex = 0;
  
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
  
  void _onRefresh() async {
    // Simulate data refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh data here
    });
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          header: const WaterDropHeader(),
        child: CustomScrollView(
          slivers: [
            // App Bar with Search
            SliverAppBar(
              floating: true,
              pinned: true,
              title: const Text('Dayliz'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
              ],
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(59),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                      setState(() {
                                        _showSuggestions = false;
                                      });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _showSuggestions = value.isNotEmpty;
                            });
                          },
                          onTap: () {
                            setState(() {
                              _showSuggestions = _searchController.text.isNotEmpty;
                            });
                          },
                        ),
                        if (_showSuggestions)
                          Container(
                            color: Colors.white,
                            constraints: const BoxConstraints(maxHeight: 200),
                            width: double.infinity,
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _searchSuggestions.length,
                              itemBuilder: (context, index) {
                                return ListTile(
                                  title: Text(_searchSuggestions[index]),
                                  leading: const Icon(Icons.search),
                                  onTap: () {
                                    _searchController.text = _searchSuggestions[index];
                                    setState(() {
                                      _showSuggestions = false;
                                    });
                                    // TODO: Implement search
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                  ),
                ),
              ),
            ),
            // Main Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Banners Carousel
                  _isLoading
                      ? _buildBannerSkeleton()
                        : _buildEnhancedBannerCarousel(),
                    const SizedBox(height: 24),
                
                    // Featured Products Section
                    _buildSectionTitle('Featured Products'),
                    const SizedBox(height: 16),
                    _isLoading
                        ? _buildProductListSkeleton()
                        : _buildFeaturedProductsHorizontal(),
                  const SizedBox(height: 24),
              
                  // Categories Section
                  _buildSectionTitle('Shop by Category'),
                  const SizedBox(height: 16),
                  _isLoading
                      ? _buildCategorySkeleton()
                      : _buildCategoryGrid(),
                  const SizedBox(height: 24),
              
                    // Limited Time Sale Section
                    _buildSectionTitle('Limited Time Sale'),
                  const SizedBox(height: 16),
                  _isLoading
                      ? _buildProductListSkeleton()
                        : _buildLimitedTimeSale(),
                    const SizedBox(height: 24),
                
                    // Special Offers Section
                    _buildSectionTitle('Special Offers'),
                    const SizedBox(height: 16),
                    _isLoading
                        ? _buildSpecialOffersSkeleton()
                        : _buildSpecialOffers(),
                  const SizedBox(height: 24),
              
                    // All Products Grid
                    _buildSectionTitle('All Products'),
                  const SizedBox(height: 16),
                  _isLoading
                      ? _buildProductGridSkeleton()
                        : _buildProductGrid(mock.mockProducts),
                ]),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: () {
            // TODO: Navigate to all items
          },
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildEnhancedBannerCarousel() {
    // Mock banner data with better images and promotion text
    final banners = [
      {
        'imageUrl': 'https://images.pexels.com/photos/264636/pexels-photo-264636.jpeg?auto=compress&cs=tinysrgb&w=1350',
        'title': 'Fresh Harvest',
        'subtitle': 'Get 20% off on all fresh produce'
      },
      {
        'imageUrl': 'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg?auto=compress&cs=tinysrgb&w=1350',
        'title': 'Organic Selection',
        'subtitle': 'Healthy choices for your family'
      },
      {
        'imageUrl': 'https://images.pexels.com/photos/4353084/pexels-photo-4353084.jpeg?auto=compress&cs=tinysrgb&w=1350',
        'title': 'Free Delivery',
        'subtitle': 'On orders above ₹500'
      },
    ];

    return Column(
      children: [
        CarouselSlider(
      options: CarouselOptions(
            height: 180,
        aspectRatio: 16 / 9,
            viewportFraction: 1.0,
        initialPage: 0,
        enableInfiniteScroll: true,
        reverse: false,
        autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
      ),
          items: banners.map((banner) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Banner Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                          imageUrl: banner['imageUrl']!,
                  fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      // Gradient overlay for text
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                      // Banner Text
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['subtitle']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
              ),
            );
          },
        );
      }).toList(),
        ),
        const SizedBox(height: 10),
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: banners.asMap().entries.map((entry) {
            return Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.primaryColor)
                    .withOpacity(_currentBannerIndex == entry.key ? 0.9 : 0.4),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    // Get unique categories from mock products
    final categories = mock.productCategories.map((category) {
      IconData icon;
      // Assign icons based on category name
      switch (category.toLowerCase()) {
        case 'fruits':
          icon = Icons.apple;
          break;
        case 'vegetables':
          icon = Icons.eco;
          break;
        case 'dairy':
          icon = Icons.egg;
          break;
        case 'bakery':
          icon = Icons.breakfast_dining;
          break;
        case 'meat':
          icon = Icons.lunch_dining;
          break;
        case 'seafood':
          icon = Icons.set_meal;
          break;
        case 'organic':
          icon = Icons.spa;
          break;
        case 'pantry':
          icon = Icons.kitchen;
          break;
        default:
          icon = Icons.category;
      }
      return {'name': category, 'icon': icon};
    }).toList();

    // Take the first 8 categories for the 2x4 grid
    final displayCategories = categories.take(8).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: displayCategories.length,
      padding: const EdgeInsets.only(bottom: 8),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // Navigate to category products
            final categoryName = displayCategories[index]['name'] as String;
            context.go(
              '/category/$categoryName',
              extra: {
                'name': categoryName,
              },
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLightColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  displayCategories[index]['icon'] as IconData,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayCategories[index]['name'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProductsHorizontal() {
    // Get featured products from mock data
    final products = mock.featuredProducts.take(10).toList();

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // Navigate to product details
                context.go('/product/${product.id}');
              },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Stack(
                  children: [
                      Hero(
                        tag: 'featured_${product.id}',
                        child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                            imageUrl: 'https://images.pexels.com/photos/${(index + 1) * 100}/pexels-photo-${(index + 1) * 100}.jpeg?auto=compress&cs=tinysrgb&w=160',
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            width: 160,
                            height: 160,
                            color: Colors.white,
                          ),
                        ),
                            errorWidget: (context, url, error) => Container(
                              width: 160,
                              height: 160,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                              color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                              '${product.discountPercentage}% off',
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
                const SizedBox(height: 8),
                // Product Name
                Text(
                    product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Product Price
                Row(
                  children: [
                    Text(
                        product.hasDiscount 
                            ? '₹${product.discountedPrice!.toStringAsFixed(2)}'
                            : '₹${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                      if (product.hasDiscount) ...[
                    const SizedBox(width: 4),
                    Text(
                          '₹${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                      ],
                  ],
                ),
              ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialOffers() {
    // Special offers list
    final offers = [
      {
        'title': 'Summer Bundle',
        'subtitle': 'Get 30% off on summer fruits',
        'color': Colors.orange[100]!,
        'iconColor': Colors.orange,
        'icon': Icons.wb_sunny,
      },
      {
        'title': 'Organic Bundle',
        'subtitle': 'Buy 2 Get 1 Free on organic products',
        'color': Colors.green[100]!,
        'iconColor': Colors.green,
        'icon': Icons.eco,
      },
      {
        'title': 'First Order',
        'subtitle': 'Get 50% off on your first order',
        'color': Colors.blue[100]!,
        'iconColor': Colors.blue,
        'icon': Icons.local_offer,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: offer['color'] as Color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                offer['icon'] as IconData,
                color: offer['iconColor'] as Color,
              ),
            ),
            title: Text(
              offer['title'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              offer['subtitle'] as String,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            trailing: TextButton(
              onPressed: () {
                // TODO: Navigate to special offer
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('View'),
            ),
            onTap: () {
              // TODO: Navigate to special offer
            },
          ),
        );
      },
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/product/${product.id}',
              arguments: product,
            );
          },
        );
      },
    );
  }

  // Loading Skeletons
  Widget _buildBannerSkeleton() {
    return Column(
      children: [
        Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
            height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) => 
            Container(
              width: 8.0,
              height: 8.0,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 12,
                color: Colors.white,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductListSkeleton() {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 80,
                    height: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecialOffersSkeleton() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLimitedTimeSale() {
    // Get limited time sale products from mock data
    final products = mock.mockProducts
        .where((product) => product.hasDiscount)
        .take(10)
        .toList();

    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        padding: const EdgeInsets.only(bottom: 8, right: 4),
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // TODO: Navigate to product details
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Stack(
                    children: [
                      Hero(
                        tag: 'sale_${product.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: 'https://images.pexels.com/photos/${(index + 1) * 200}/pexels-photo-${(index + 1) * 200}.jpeg?auto=compress&cs=tinysrgb&w=160',
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                width: 160,
                                height: 160,
                                color: Colors.white,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 160,
                              height: 160,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Product Price
                  Row(
                    children: [
                      Text(
                        '₹${product.discountedPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 65, // Increased from 60 to 65 pixels
      child: Row(
        children: [
          // Location
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Delivery to',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      Text(
                        'Current Location',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Notifications
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: const Icon(Icons.notifications_outlined),
          ),
          // Cart
          IconButton(
            onPressed: () {
              // TODO: Navigate to cart
            },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
    );
  }
} 