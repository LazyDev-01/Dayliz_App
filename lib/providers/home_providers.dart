import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/data/mock_products.dart' as mock;
import 'package:dayliz_app/widgets/home/category_grid.dart';
import 'package:dayliz_app/models/banner.dart';

// State providers for loading indicators
final bannersLoadingProvider = StateProvider<bool>((ref) => true);
final featuredProductsLoadingProvider = StateProvider<bool>((ref) => true);
final homeScreenCategoriesLoadingProvider = StateProvider<bool>((ref) => true);
final saleProductsLoadingProvider = StateProvider<bool>((ref) => true);
final allProductsLoadingProvider = StateProvider<bool>((ref) => true);

// Cache providers
final bannersCacheProvider = StateProvider<List<BannerModel>?>((ref) => null);
final featuredProductsCacheProvider = StateProvider<List<Product>?>((ref) => null);
final homeScreenCategoriesCacheProvider = StateProvider<List<String>?>((ref) => null);
final saleProductsCacheProvider = StateProvider<List<Product>?>((ref) => null);
final allProductsCacheProvider = StateProvider<List<Product>?>((ref) => null);

// Fetch banners
final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  // Check cache first
  final cachedBanners = ref.watch(bannersCacheProvider);
  if (cachedBanners != null) {
    print('🔄 Using cached banner data');
    return cachedBanners;
  }
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 800));
  
  print('🔄 Fetching banner data from API');
  
  // Mock data (in a real app, this would be API call)
  final banners = _getBanners();
  
  // Cache the results
  ref.read(bannersCacheProvider.notifier).state = banners;
  
  return banners;
});

// Listeners for loading state updates
final bannersLoadingListener = Provider<void>((ref) {
  ref.listen<AsyncValue<List<BannerModel>>>(
    bannersProvider,
    (_, next) {
      if (next.hasValue) {
        ref.read(bannersLoadingProvider.notifier).state = false;
      } else if (next.isLoading) {
        ref.read(bannersLoadingProvider.notifier).state = true;
      }
    }
  );
});

// Fetch featured products
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Check cache first
  final cachedProducts = ref.watch(featuredProductsCacheProvider);
  if (cachedProducts != null) {
    print('🔄 Using cached featured products data');
    return cachedProducts;
  }
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 1000));
  
  print('🔄 Fetching featured products data from API');
  
  // Mock data (in a real app, this would be API call)
  final products = _getFeaturedProducts();
  
  // Cache the results
  ref.read(featuredProductsCacheProvider.notifier).state = products;
  
  return products;
});

// Listener for featured products loading state
final featuredProductsLoadingListener = Provider<void>((ref) {
  ref.listen<AsyncValue<List<Product>>>(
    featuredProductsProvider,
    (_, next) {
      if (next.hasValue) {
        ref.read(featuredProductsLoadingProvider.notifier).state = false;
      } else if (next.isLoading) {
        ref.read(featuredProductsLoadingProvider.notifier).state = true;
      }
    }
  );
});

// Rename this to avoid conflict with our new unifiedCategoriesProvider
final homeScreenCategoriesProvider = FutureProvider<List<String>>((ref) async {
  // Check cache first
  final cachedCategories = ref.watch(homeScreenCategoriesCacheProvider);
  if (cachedCategories != null) {
    print('🔄 Using cached categories data');
    return cachedCategories;
  }
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 600));
  
  print('🔄 Fetching categories data from API');
  
  // Mock data (in a real app, this would be API call)
  final categories = [
    'Electronics',
    'Fashion',
    'Beauty',
    'Home',
    'Grocery',
    'Toys',
    'Sports',
    'Books',
    'Health',
  ];
  
  // Cache the results
  ref.read(homeScreenCategoriesCacheProvider.notifier).state = categories;
  
  return categories;
});

// Update the listener to use the renamed provider
final homeLoadingListener = Provider<void>((ref) {
  ref.listen<AsyncValue<List<String>>>(
    homeScreenCategoriesProvider,
    (_, next) {
      if (next.hasValue) {
        ref.read(homeScreenCategoriesLoadingProvider.notifier).state = false;
      } else if (next.isLoading) {
        ref.read(homeScreenCategoriesLoadingProvider.notifier).state = true;
      }
    }
  );
});

// Fetch sale products
final saleProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Check cache first
  final cachedProducts = ref.watch(saleProductsCacheProvider);
  if (cachedProducts != null) {
    print('🔄 Using cached sale products data');
    return cachedProducts;
  }
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 1200));
  
  print('🔄 Fetching sale products data from API');
  
  // Mock data (in a real app, this would be API call)
  final products = _getSaleProducts();
  
  // Cache the results
  ref.read(saleProductsCacheProvider.notifier).state = products;
  
  return products;
});

// Listener for sale products loading state
final saleProductsLoadingListener = Provider<void>((ref) {
  ref.listen<AsyncValue<List<Product>>>(
    saleProductsProvider,
    (_, next) {
      if (next.hasValue) {
        ref.read(saleProductsLoadingProvider.notifier).state = false;
      } else if (next.isLoading) {
        ref.read(saleProductsLoadingProvider.notifier).state = true;
      }
    }
  );
});

// Fetch all products
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Check cache first
  final cachedProducts = ref.watch(allProductsCacheProvider);
  if (cachedProducts != null) {
    print('🔄 Using cached all products data');
    return cachedProducts;
  }
  
  // Simulate network delay
  await Future.delayed(const Duration(milliseconds: 1500));
  
  print('🔄 Fetching all products data from API');
  
  // Mock data (in a real app, this would be API call)
  final products = _getAllProducts();
  
  // Cache the results
  ref.read(allProductsCacheProvider.notifier).state = products;
  
  return products;
});

// Listener for all products loading state
final allProductsLoadingListener = Provider<void>((ref) {
  ref.listen<AsyncValue<List<Product>>>(
    allProductsProvider,
    (_, next) {
      if (next.hasValue) {
        ref.read(allProductsLoadingProvider.notifier).state = false;
      } else if (next.isLoading) {
        ref.read(allProductsLoadingProvider.notifier).state = true;
      }
    }
  );
});

// Mock data generators
List<BannerModel> _getBanners() {
  return [
    BannerModel(
      id: '1',
      title: 'Summer Sale',
      subtitle: 'Up to 50% off on all summer essentials',
      imageUrl: 'https://picsum.photos/id/26/800/400',
      actionUrl: '/summer-sale',
    ),
    BannerModel(
      id: '2',
      title: 'New Arrivals',
      subtitle: 'Check out our latest collection',
      imageUrl: 'https://picsum.photos/id/96/800/400',
      actionUrl: '/new-arrivals',
    ),
    BannerModel(
      id: '3',
      title: 'Flash Sale',
      subtitle: 'Limited time offers on premium products',
      imageUrl: 'https://picsum.photos/id/65/800/400',
      actionUrl: '/flash-sale',
    ),
  ];
}

List<Product> _getFeaturedProducts() {
  return [
    Product(
      id: '1',
      name: 'Wireless Earbuds',
      description: 'High-quality wireless earbuds with noise cancellation.',
      price: 129.99,
      discountPrice: 99.99,
      imageUrl: 'https://picsum.photos/id/100/400/400',
      rating: 4.5,
      categoryId: 'electronics',
      isFeatured: true,
      isOnSale: false,
      isInStock: true,
      stockQuantity: 50,
      categories: ['Electronics', 'Audio'],
      reviewCount: 120,
      brand: 'TechSound',
      dateAdded: DateTime.now().subtract(const Duration(days: 30)),
    ),
    Product(
      id: '2',
      name: 'Smart Watch',
      description: 'Track your fitness and stay connected with this smartwatch.',
      price: 199.99,
      discountPrice: null,
      imageUrl: 'https://picsum.photos/id/111/400/400',
      rating: 4.2,
      categoryId: 'electronics',
      isFeatured: true,
      isOnSale: false,
      isInStock: true,
      stockQuantity: 35,
      categories: ['Electronics', 'Wearables'],
      reviewCount: 85,
      brand: 'SmartLife',
      dateAdded: DateTime.now().subtract(const Duration(days: 45)),
    ),
    Product(
      id: '3',
      name: 'Portable Charger',
      description: '10000mAh portable charger for all your devices.',
      price: 49.99,
      discountPrice: 39.99,
      imageUrl: 'https://picsum.photos/id/160/400/400',
      rating: 4.7,
      categoryId: 'electronics',
      isFeatured: true,
      isOnSale: true,
      isInStock: true,
      stockQuantity: 120,
      categories: ['Electronics', 'Accessories'],
      reviewCount: 230,
      brand: 'PowerMax',
      dateAdded: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Product(
      id: '4',
      name: 'Bluetooth Speaker',
      description: 'Waterproof bluetooth speaker with amazing sound quality.',
      price: 79.99,
      discountPrice: null,
      imageUrl: 'https://picsum.photos/id/119/400/400',
      rating: 4.0,
      categoryId: 'electronics',
      isFeatured: true,
      isOnSale: false,
      isInStock: true,
      stockQuantity: 65,
      categories: ['Electronics', 'Audio'],
      reviewCount: 95,
      brand: 'SoundWave',
      dateAdded: DateTime.now().subtract(const Duration(days: 60)),
    ),
  ];
}

List<Product> _getSaleProducts() {
  return [
    Product(
      id: '3',
      name: 'Portable Charger',
      description: '10000mAh portable charger for all your devices.',
      price: 49.99,
      discountPrice: 39.99,
      imageUrl: 'https://picsum.photos/id/160/400/400',
      rating: 4.7,
      categoryId: 'electronics',
      isFeatured: true,
      isOnSale: true,
      isInStock: true,
      stockQuantity: 120,
      categories: ['Electronics', 'Accessories'],
      reviewCount: 230,
      brand: 'PowerMax',
      dateAdded: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Product(
      id: '5',
      name: 'Coffee Maker',
      description: 'Programmable coffee maker with timer.',
      price: 89.99,
      discountPrice: 69.99,
      imageUrl: 'https://picsum.photos/id/225/400/400',
      rating: 4.3,
      categoryId: 'home',
      isFeatured: false,
      isOnSale: true,
      isInStock: true,
      stockQuantity: 45,
      categories: ['Home', 'Kitchen'],
      reviewCount: 78,
      brand: 'HomeBrew',
      dateAdded: DateTime.now().subtract(const Duration(days: 20)),
    ),
    Product(
      id: '6',
      name: 'Running Shoes',
      description: 'Lightweight running shoes with cushioned soles.',
      price: 119.99,
      discountPrice: 89.99,
      imageUrl: 'https://picsum.photos/id/21/400/400',
      rating: 4.6,
      categoryId: 'sports',
      isFeatured: false,
      isOnSale: true,
      isInStock: true,
      stockQuantity: 55,
      categories: ['Sports', 'Footwear'],
      reviewCount: 112,
      brand: 'SpeedRun',
      dateAdded: DateTime.now().subtract(const Duration(days: 25)),
    ),
    Product(
      id: '7',
      name: 'Stand Mixer',
      description: 'Powerful stand mixer for all your baking needs.',
      price: 299.99,
      discountPrice: 249.99,
      imageUrl: 'https://picsum.photos/id/250/400/400',
      rating: 4.8,
      categoryId: 'home',
      isFeatured: false,
      isOnSale: true,
      isInStock: true,
      stockQuantity: 30,
      categories: ['Home', 'Kitchen'],
      reviewCount: 64,
      brand: 'KitchenPro',
      dateAdded: DateTime.now().subtract(const Duration(days: 40)),
    ),
  ];
}

List<Product> _getAllProducts() {
  final List<Product> allProducts = [
    ..._getFeaturedProducts(),
    ..._getSaleProducts(),
    Product(
      id: '8',
      name: 'Yoga Mat',
      description: 'Non-slip yoga mat for home workouts.',
      price: 29.99,
      discountPrice: null,
      imageUrl: 'https://picsum.photos/id/28/400/400',
      rating: 4.4,
      categoryId: 'sports',
      isFeatured: false,
      isOnSale: false,
      isInStock: true,
      stockQuantity: 80,
      categories: ['Sports', 'Yoga'],
      reviewCount: 48,
      brand: 'FlexFit',
      dateAdded: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Product(
      id: '9',
      name: 'Air Purifier',
      description: 'HEPA air purifier for cleaner indoor air.',
      price: 149.99,
      discountPrice: null,
      imageUrl: 'https://picsum.photos/id/118/400/400',
      rating: 4.2,
      categoryId: 'home',
      isFeatured: false,
      isOnSale: false,
      isInStock: true,
      stockQuantity: 25,
      categories: ['Home', 'Appliances'],
      reviewCount: 56,
      brand: 'PureAir',
      dateAdded: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Product(
      id: '10',
      name: 'Digital Camera',
      description: '24MP digital camera with 4K video recording.',
      price: 599.99,
      discountPrice: null,
      imageUrl: 'https://picsum.photos/id/250/400/400',
      rating: 4.7,
      categoryId: 'electronics',
      isFeatured: false,
      isOnSale: false,
      isInStock: true,
      stockQuantity: 15,
      categories: ['Electronics', 'Photography'],
      reviewCount: 38,
      brand: 'PixelPro',
      dateAdded: DateTime.now().subtract(const Duration(days: 30)),
    ),
  ];
  
  // Remove duplicates based on id
  final uniqueProducts = <Product>[];
  final ids = <String>{};
  
  for (final product in allProducts) {
    if (!ids.contains(product.id)) {
      uniqueProducts.add(product);
      ids.add(product.id);
    }
  }
  
  return uniqueProducts;
}

// Category grid item class is now imported from category_grid.dart 