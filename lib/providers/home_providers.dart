import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:dayliz_app/models/product.dart';
import 'package:dayliz_app/widgets/home/category_grid.dart';
import 'package:dayliz_app/models/banner.dart';
import 'package:dayliz_app/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

// Product service provider
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

// Fetch banners
final bannersProvider = FutureProvider<List<BannerModel>>((ref) async {
  // Check cache first
  final cachedBanners = ref.watch(bannersCacheProvider);
  if (cachedBanners != null) {
    print('🔄 Using cached banner data');
    return cachedBanners;
  }
  
  try {
    print('🔄 Fetching banner data from Supabase');
    
    // Fetch from Supabase
    final response = await Supabase.instance.client
        .from('banners')
        .select('*')
        .order('display_order');
    
    final banners = response.map<BannerModel>((json) => BannerModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? 'https://placehold.co/800x400/4CAF50/FFFFFF?text=Banner',
      actionUrl: json['action_url'] ?? '/home',
    )).toList();
    
    if (banners.isEmpty) {
      // Fallback to default banners if none exist in database
      final defaultBanners = _getDefaultBanners();
      ref.read(bannersCacheProvider.notifier).state = defaultBanners;
      return defaultBanners;
    }
    
    // Cache the results
    ref.read(bannersCacheProvider.notifier).state = banners;
    
    return banners;
  } catch (e) {
    print('❌ Error fetching banners: $e');
    
    // Fallback to default banners on error
    final defaultBanners = _getDefaultBanners();
    ref.read(bannersCacheProvider.notifier).state = defaultBanners;
    return defaultBanners;
  }
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

// Fetch featured products from Supabase
final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Check cache first
  final cachedProducts = ref.watch(featuredProductsCacheProvider);
  if (cachedProducts != null) {
    print('🔄 Using cached featured products data');
    return cachedProducts;
  }
  
  try {
    final productService = ref.read(productServiceProvider);
    final products = await productService.getFeaturedProducts();
    
    // Cache the results
    ref.read(featuredProductsCacheProvider.notifier).state = products;
    
    return products;
  } catch (e) {
    print('❌ Error fetching featured products: $e');
    rethrow;
  }
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
  
  try {
    print('🔄 Fetching categories data from Supabase');
    
    // Get main categories from database
    final response = await Supabase.instance.client
        .from('categories')
        .select('name')
        .order('display_order');
    
    // Extract category names 
    final categories = response.map<String>((json) => json['name'] as String).toList();
    
    if (categories.isEmpty) {
      // Fallback categories
      final defaultCategories = [
        'Grocery & Kitchen',
        'Snacks & Beverages',
        'Beauty & Hygiene',
        'Household & Essentials',
      ];
      
      ref.read(homeScreenCategoriesCacheProvider.notifier).state = defaultCategories;
      return defaultCategories;
    }
    
    // Cache the results
    ref.read(homeScreenCategoriesCacheProvider.notifier).state = categories;
    
    return categories;
  } catch (e) {
    print('❌ Error fetching categories: $e');
    
    // Fallback categories on error
    final defaultCategories = [
      'Grocery',
      'Snacks',
      'Beauty',
      'Household',
    ];
    
    ref.read(homeScreenCategoriesCacheProvider.notifier).state = defaultCategories;
    return defaultCategories;
  }
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

// Fetch sale products from Supabase
final saleProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Check cache first
  final cachedProducts = ref.watch(saleProductsCacheProvider);
  if (cachedProducts != null) {
    print('🔄 Using cached sale products data');
    return cachedProducts;
  }
  
  try {
    final productService = ref.read(productServiceProvider);
    final products = await productService.getSaleProducts();
    
    // Cache the results
    ref.read(saleProductsCacheProvider.notifier).state = products;
    
    return products;
  } catch (e) {
    print('❌ Error fetching sale products: $e');
    rethrow;
  }
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

// Fetch all products from Supabase
final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  // Check cache first
  final cachedProducts = ref.watch(allProductsCacheProvider);
  if (cachedProducts != null) {
    print('🔄 Using cached all products data');
    return cachedProducts;
  }
  
  try {
    final productService = ref.read(productServiceProvider);
    final products = await productService.getAllProducts();
    
    // Cache the results
    ref.read(allProductsCacheProvider.notifier).state = products;
    
    return products;
  } catch (e) {
    print('❌ Error fetching all products: $e');
    rethrow;
  }
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

// Default banners for fallback
List<BannerModel> _getDefaultBanners() {
  return [
    BannerModel(
      id: '1',
      title: 'Summer Sale',
      subtitle: 'Up to 50% off on all summer essentials',
      imageUrl: 'https://placehold.co/800x400/4CAF50/FFFFFF?text=Summer+Sale',
      actionUrl: '/summer-sale',
    ),
    BannerModel(
      id: '2',
      title: 'New Arrivals',
      subtitle: 'Check out our latest collection',
      imageUrl: 'https://placehold.co/800x400/2196F3/FFFFFF?text=New+Arrivals',
      actionUrl: '/new-arrivals',
    ),
    BannerModel(
      id: '3',
      title: 'Flash Sale',
      subtitle: 'Limited time offers on premium products',
      imageUrl: 'https://placehold.co/800x400/FF9800/FFFFFF?text=Flash+Sale',
      actionUrl: '/flash-sale',
    ),
  ];
}

// Category grid item class is now imported from category_grid.dart 