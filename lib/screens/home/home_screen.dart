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
import 'package:dayliz_app/widgets/home/banner_carousel.dart';
import 'package:dayliz_app/widgets/home/category_grid.dart';
import 'package:dayliz_app/widgets/home/section_title.dart';
import 'package:dayliz_app/widgets/home/product_horizontal_list.dart';
import 'package:dayliz_app/widgets/home/product_grid.dart';
import 'package:dayliz_app/widgets/home/search_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  final List<String> _searchSuggestions = const [
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
              _buildAppBar(),
              
              // Main Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Banners Carousel
                    _isLoading
                      ? _buildBannerSkeleton()
                      : _buildBannerCarousel(),
                    const SizedBox(height: 24),
                
                    // Featured Products Section
                    SectionTitle(
                      title: 'Featured Products',
                      onSeeAllPressed: () {
                        // TODO: Navigate to all featured products
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                      ? _buildProductListSkeleton()
                      : _buildFeaturedProducts(),
                    const SizedBox(height: 24),
              
                    // Categories Section
                    SectionTitle(
                      title: 'Shop by Category',
                      onSeeAllPressed: () {
                        // Navigate to categories tab
                        ref.read(currentIndexProvider.notifier).state = 1;
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                      ? _buildCategorySkeleton()
                      : _buildCategories(),
                    const SizedBox(height: 24),
              
                    // Limited Time Sale Section
                    SectionTitle(
                      title: 'Limited Time Sale',
                      onSeeAllPressed: () {
                        // TODO: Navigate to sale products
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                      ? _buildProductListSkeleton()
                      : _buildLimitedTimeSale(),
                    const SizedBox(height: 24),
                
                    // All Products Grid
                    SectionTitle(
                      title: 'All Products',
                      onSeeAllPressed: () {
                        // TODO: Navigate to all products
                      },
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                      ? _buildProductGridSkeleton()
                      : ProductGrid(products: mock.mockProducts.take(6).toList()),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
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
          child: SearchBarWidget(
            controller: _searchController,
            suggestions: _searchSuggestions,
            onSearch: (query) {
              // TODO: Implement search
              print('Searching for: $query');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final banners = [
      {
        'title': 'Fresh Harvest',
        'subtitle': 'Get 20% off on all fresh produce'
      },
      {
        'title': 'Organic Selection',
        'subtitle': 'Healthy choices for your family'
      },
      {
        'title': 'Free Delivery',
        'subtitle': 'On orders above ₹500'
      },
    ];

    return BannerCarousel(banners: banners);
  }

  Widget _buildCategories() {
    // Get unique categories from mock products with icons
    final List<CategoryGridItem> categories = mock.productCategories.map((category) {
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
      return CategoryGridItem(name: category, icon: icon);
    }).toList();

    // Take the first 8 categories for the 2x4 grid
    final displayCategories = categories.take(8).toList();

    return CategoryGrid(categories: displayCategories);
  }

  Widget _buildFeaturedProducts() {
    // Get featured products from mock data
    final products = mock.featuredProducts.take(10).toList();
    return ProductHorizontalList(
      products: products,
      heroTagPrefix: 'featured',
    );
  }

  Widget _buildLimitedTimeSale() {
    // Get products on sale from mock data
    final products = mock.mockProducts
        .where((p) => p.hasDiscount && p.discountPercentage! > 15)
        .take(10)
        .toList();
    
    return ProductHorizontalList(
      products: products,
      heroTagPrefix: 'sale',
    );
  }

  // Skeleton loaders
  Widget _buildBannerSkeleton() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 120,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 16,
                  width: 80,
                  color: Colors.grey[300],
                ),
              ],
            ),
          );
        },
      ),
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
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 60,
              color: Colors.grey[300],
            ),
          ],
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
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Provider for bottom navigation current index
final currentIndexProvider = StateProvider<int>((ref) => 0); 