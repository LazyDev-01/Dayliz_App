import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/widgets/product_card.dart';
import 'package:dayliz_app/data/mock_products.dart' as mock;
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/models/banner.dart';
import 'package:dayliz_app/models/category_models.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:go_router/go_router.dart';
import 'package:dayliz_app/widgets/home/banner_carousel.dart';
import 'package:dayliz_app/widgets/home/category_grid.dart';
import 'package:dayliz_app/widgets/ui/section_title.dart';
import 'package:dayliz_app/widgets/home/product_horizontal_list.dart';
import 'package:dayliz_app/widgets/home/product_grid.dart';
import 'package:dayliz_app/widgets/home/search_bar.dart';
import 'package:dayliz_app/widgets/home/section_widgets.dart';
import 'package:dayliz_app/providers/home_providers.dart' hide categoriesCacheProvider;
import 'package:dayliz_app/providers/search_providers.dart';
import 'package:dayliz_app/screens/home/categories_screen.dart' hide selectedCategoryProvider;
import 'package:dayliz_app/screens/search/search_screen.dart';
import 'package:dayliz_app/utils/shimmer.dart';
import 'package:dayliz_app/providers/category_providers.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

// Provider for bottom navigation current index
final currentIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchSuggestions = [
    'Fresh fruits',
    'Vegetables',
    'Dairy products',
    'Bread'
  ];
  bool _isLoading = true; // Initial loading state
  final RefreshController _refreshController = RefreshController();

  // Add navigateToSubcategory method to match the one from category_providers
  void navigateToSubcategory(BuildContext context, SubCategory subcategory) {
    context.go(
      '/category/${subcategory.id}',
      extra: {
        'name': subcategory.name,
        'parentCategory': subcategory.parentId,
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Register all loading state listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listen to all loading indicators
      ref.read(bannersLoadingListener);
      ref.read(featuredProductsLoadingListener);
      ref.read(homeLoadingListener);
      ref.read(saleProductsLoadingListener);
      ref.read(allProductsLoadingListener);
      
      // Initialize the selected category provider
      ref.read(initializeSelectedCategoryProvider);
      
      // Simulate loading delay for initial app startup
      Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
  
  void _onRefresh() async {
    // Force refresh by resetting cache
    ref.invalidate(bannersCacheProvider);
    ref.invalidate(featuredProductsCacheProvider);
    ref.invalidate(categoriesCacheProvider);
    ref.invalidate(saleProductsCacheProvider);
    ref.invalidate(allProductsCacheProvider);
    
    // Wait for some time to allow data to be refreshed
    await Future.delayed(const Duration(milliseconds: 1500));
    
    _refreshController.refreshCompleted();
  }

  @override
  Widget build(BuildContext context) {
    // Get loading states
    final bannersLoading = ref.watch(bannersLoadingProvider);
    final featuredLoading = ref.watch(featuredProductsLoadingProvider);
    final categoriesData = ref.watch(categoriesProvider);
    final allProductsLoading = ref.watch(allProductsLoadingProvider);

    return Scaffold(
      body: SafeArea(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          header: const ClassicHeader(),
        child: CustomScrollView(
          slivers: [
              // App bar with search
            SliverAppBar(
              floating: true,
              elevation: 4, // Add shadow to app bar
              shadowColor: Colors.black.withOpacity(0.3), // Set shadow color
                title: const Text(
                  'Dayliz',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Navigate to notifications
                  },
                ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () {
                      // Navigate to wishlist
                      context.go('/clean-wishlist');
                  },
                ),
              ],
              bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                child: Container(
                    height: 50,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                        hintText: 'Search for products...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () {
                        // When search field is tapped, navigate to search screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SearchScreen(),
                          ),
                        );
                      },
                      readOnly: true, // Make it readonly so keyboard doesn't show
                    ),
                  ),
                ),
              ),

              // Content sections
              if (_isLoading)
                _buildLoadingScreen()
              else
                ...[
                  // Banners
                  _buildBannerSection(bannersLoading),

                  // Featured products
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: FeaturedProductsSection(),
                    ),
                  ),

                  // Categories grid
                  _buildCategoriesSection(categoriesData),

                  // All products
                  _buildProductSection(
                    title: 'All Products',
                    isLoading: allProductsLoading,
                    provider: allProductsProvider,
                    gridView: true,
                  ),

                  // Bottom padding
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return SliverToBoxAdapter(
      child: Column(
      children: [
          const SizedBox(height: 20),
          // Banner skeleton
          ShimmerLoading(height: 150, width: double.infinity),
          const SizedBox(height: 20),
          // Section title skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoading(height: 24, width: 180),
          ),
          const SizedBox(height: 12),
          // Product row skeleton
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ShimmerLoading(height: 220, width: 160),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Categories skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ShimmerLoading(height: 24, width: 180),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.9,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 8,
              itemBuilder: (context, index) {
                return ShimmerLoading(height: 80, width: 80);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection(bool isLoading) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          const SizedBox(height: 16),
          if (isLoading)
            _buildBannerSkeleton()
          else
            _buildBannerCarousel(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBannerSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerLoading(height: 150, width: double.infinity),
    );
  }

  Widget _buildBannerCarousel() {
    final AsyncValue<List<BannerModel>> banners = ref.watch(bannersProvider);
    
    return banners.when(
      data: (bannerList) {
        // Return empty container if no banners
        if (bannerList.isEmpty) {
          return const SizedBox.shrink();
        }

        // Use a StatefulBuilder to track current page
        return StatefulBuilder(
          builder: (context, setState) {
            final pageController = PageController(viewportFraction: 0.9);
            int currentPage = 0;
            
            // Setup auto-scroll
            // Note: in a real implementation, this would be in a StatefulWidget's initState
            // with proper disposal in dispose() method to prevent memory leaks
            void startAutoScroll() {
              Future.delayed(const Duration(milliseconds: 100), () {
                Timer.periodic(const Duration(seconds: 5), (timer) {
                  if (!context.mounted) {
                    timer.cancel();
                    return;
                  }
                  
                  if (currentPage < bannerList.length - 1) {
                    currentPage++;
                  } else {
                    currentPage = 0;
                  }
                  
                  if (pageController.hasClients) {
                    pageController.animateToPage(
                      currentPage,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              });
            }
            
            // Start auto-scroll
            startAutoScroll();

            return Column(
              children: [
                SizedBox(
                  height: 150,
                  child: PageView.builder(
                    controller: pageController,
                    itemCount: bannerList.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final banner = bannerList[index];
                      return GestureDetector(
                        onTap: () {
                          // Navigate based on banner's actionUrl
                          if (banner.actionUrl.isNotEmpty) {
                            _handleBannerNavigation(banner.actionUrl);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.blue.withOpacity(0.1),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              // Banner image
                              CachedNetworkImage(
                                imageUrl: banner.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    color: Colors.white,
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                              // Gradient overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withOpacity(0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              // Text content
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      banner.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      banner.subtitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Navigate using banner's actionUrl
                                        if (banner.actionUrl.isNotEmpty) {
                                          _handleBannerNavigation(banner.actionUrl);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        minimumSize: const Size(100, 30),
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                      child: const Text('Shop Now'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Page indicator dots
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    bannerList.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPage == index
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => _buildBannerSkeleton(),
      error: (error, stackTrace) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading banners: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildProductSection({
    required String title,
    String? subtitle,
    required bool isLoading,
    required FutureProvider<List<Product>> provider,
    bool gridView = false,
  }) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: title,
            subtitle: subtitle,
            onSeeAllPressed: () {
              // TODO: Navigate to product listing
            },
          ),
          const SizedBox(height: 8),
          if (isLoading)
            _buildProductSkeleton(gridView: gridView)
          else
            _buildProductList(provider, gridView: gridView),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProductSkeleton({bool gridView = false}) {
    if (gridView) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 20,
      ),
          itemCount: 4,
      itemBuilder: (context, index) {
            return ShimmerLoading(height: 220, width: 160);
          },
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ShimmerLoading(height: 220, width: 160),
          );
        },
      ),
    );
  }

  Widget _buildProductList(FutureProvider<List<Product>> provider, {bool gridView = false}) {
    final AsyncValue<List<Product>> products = ref.watch(provider);

    return products.when(
      data: (productList) {
        if (gridView) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 10,
                mainAxisSpacing: 20,
              ),
              itemCount: productList.length,
              itemBuilder: (context, index) {
                return ProductCard(product: productList[index]);
              },
            ),
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: productList.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ProductCard(product: productList[index]),
              );
            },
          ),
        );
      },
      loading: () => _buildProductSkeleton(gridView: gridView),
      error: (error, stackTrace) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading products: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  Widget _buildCategoriesSection(AsyncValue<List<Category>> categoriesData) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          SectionTitle(
            title: 'Shop by Category',
            onSeeAllPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          if (categoriesData.isLoading)
            _buildCategoriesSkeleton()
          else if (categoriesData.hasValue && categoriesData.value != null)
            _buildCategoriesWithSubcategories(categoriesData.value!)
          else if (categoriesData.hasError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading categories: ${categoriesData.error}',
                style: const TextStyle(color: Colors.red),
              ),
            )
          else
            _buildCategoriesSkeleton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoriesSkeleton() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLoading(height: 24, width: 150),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerLoading(height: 100, width: double.infinity)),
              SizedBox(width: 16),
              Expanded(child: ShimmerLoading(height: 100, width: double.infinity)),
              SizedBox(width: 16),
              Expanded(child: ShimmerLoading(height: 100, width: double.infinity)),
            ],
          ),
          SizedBox(height: 24),
          ShimmerLoading(height: 24, width: 180),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ShimmerLoading(height: 100, width: double.infinity)),
              SizedBox(width: 16),
              Expanded(child: ShimmerLoading(height: 100, width: double.infinity)),
              SizedBox(width: 16),
              Expanded(child: ShimmerLoading(height: 100, width: double.infinity)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesWithSubcategories(List<Category> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
      itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategorySection(category);
        },
      ),
    );
  }

  Widget _buildCategorySection(Category category) {
    // Only show subcategories if there are some
    if (category.subCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        InkWell(
                onTap: () {
            // Set the selected category and navigate
            ref.read(selectedCategoryProvider.notifier).state = category.id;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesScreen(),
                    ),
                  );
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  category.icon,
                  color: category.themeColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[600],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        
        // Add spacing between header and subcategories
        const SizedBox(height: 20),
        
        // Subcategories (3-grid)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: category.subCategories.length > 6 
              ? 6 // Show maximum 6 subcategories on home screen
              : category.subCategories.length,
          itemBuilder: (context, index) {
            final subcategory = category.subCategories[index];
            return _buildSubcategoryCard(subcategory);
          },
        ),
        
        // Increased spacing between category sections
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSubcategoryCard(SubCategory subcategory) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          // Use the navigation function from category providers
          navigateToSubcategory(context, subcategory);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: subcategory.imageUrl ?? 'https://placehold.co/100x100/CCCCCC/FFFFFF?text=No+Image',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                subcategory.name,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBannerNavigation(String actionUrl) {
    if (actionUrl.isEmpty) return;
    
    // Check if it's an internal route or external URL
    if (actionUrl.startsWith('http://') || actionUrl.startsWith('https://')) {
      // External URL - launch in browser
      _launchExternalUrl(actionUrl);
    } else {
      // Internal route - navigate within the app
      _navigateToInternalRoute(actionUrl);
    }
  }
  
  void _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Show error if URL can't be launched
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link')),
          );
        }
      }
    } catch (e) {
      // Handle any exceptions
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
  
  void _navigateToInternalRoute(String route) {
    // Handle different internal routes
    switch (route) {
      case '/summer-sale':
        // Navigate to summer sale screen or filtered products
        Navigator.pushNamed(context, '/products', arguments: {'category': 'summer-sale'});
        break;
      
      case '/new-arrivals':
        // Navigate to new arrivals
        Navigator.pushNamed(context, '/products', arguments: {'filter': 'new-arrivals'});
        break;
        
      case '/flash-sale':
        // Navigate to flash sale
        Navigator.pushNamed(context, '/products', arguments: {'filter': 'flash-sale'});
        break;
        
      default:
        // If the route is not recognized, try to navigate directly
        Navigator.pushNamed(context, route);
    }
  }
} 