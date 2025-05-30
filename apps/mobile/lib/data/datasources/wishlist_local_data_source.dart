import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/errors/exceptions.dart';
import '../models/wishlist_item_model.dart';
import '../models/product_model.dart';

/// Interface for wishlist local data source
abstract class WishlistLocalDataSource {
  /// Get all wishlist items for the current user
  Future<List<WishlistItemModel>> getWishlistItems();

  /// Add a product to the wishlist
  Future<WishlistItemModel> addToWishlist(String productId);

  /// Remove a product from the wishlist
  Future<bool> removeFromWishlist(String productId);

  /// Check if a product is in the wishlist
  Future<bool> isInWishlist(String productId);

  /// Clear the wishlist
  Future<bool> clearWishlist();

  /// Cache product models for wishlist items
  Future<bool> cacheWishlistProducts(List<ProductModel> products);

  /// Get cached product models for wishlist items
  Future<List<ProductModel>> getCachedWishlistProducts();

  /// Get wishlist products
  Future<List<ProductModel>> getWishlistProducts();
}

/// Implementation of [WishlistLocalDataSource] using SharedPreferences
class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  final SharedPreferences sharedPreferences;
  final Uuid uuid = const Uuid();

  WishlistLocalDataSourceImpl({
    required this.sharedPreferences,
  });

  static const String _wishlistItemsKey = 'WISHLIST_ITEMS';
  static const String _wishlistProductsKey = 'WISHLIST_PRODUCTS';

  @override
  Future<List<WishlistItemModel>> getWishlistItems() async {
    try {
      final jsonString = sharedPreferences.getString(_wishlistItemsKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData
          .map((item) => WishlistItemModel.fromJson(item))
          .toList();
    } catch (e) {
      throw CacheException(
        message: 'Error fetching wishlist items from cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<WishlistItemModel> addToWishlist(String productId) async {
    try {
      final wishlistItems = await getWishlistItems();
      
      // Check if item already exists
      if (wishlistItems.any((item) => item.productId == productId)) {
        final existingItem = wishlistItems.firstWhere(
          (item) => item.productId == productId,
        );
        return existingItem;
      }
      
      // Create new item
      final newItem = WishlistItemModel(
        id: uuid.v4(),
        productId: productId,
        dateAdded: DateTime.now(),
      );
      
      // Add to list and save
      wishlistItems.add(newItem);
      
      final jsonList = wishlistItems.map((item) => item.toJson()).toList();
      final success = await sharedPreferences.setString(
        _wishlistItemsKey,
        json.encode(jsonList),
      );
      
      if (!success) {
        throw CacheException(
          message: 'Failed to save wishlist item to cache',
        );
      }
      
      return newItem;
    } catch (e) {
      throw CacheException(
        message: 'Error adding item to wishlist cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final wishlistItems = await getWishlistItems();
      final updatedItems = wishlistItems
          .where((item) => item.productId != productId)
          .toList();
      
      final jsonList = updatedItems.map((item) => item.toJson()).toList();
      final success = await sharedPreferences.setString(
        _wishlistItemsKey,
        json.encode(jsonList),
      );
      
      return success;
    } catch (e) {
      throw CacheException(
        message: 'Error removing item from wishlist cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> isInWishlist(String productId) async {
    try {
      final wishlistItems = await getWishlistItems();
      return wishlistItems.any((item) => item.productId == productId);
    } catch (e) {
      throw CacheException(
        message: 'Error checking if item is in wishlist cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> clearWishlist() async {
    try {
      final successItems = await sharedPreferences.remove(_wishlistItemsKey);
      final successProducts = await sharedPreferences.remove(_wishlistProductsKey);
      return successItems && successProducts;
    } catch (e) {
      throw CacheException(
        message: 'Error clearing wishlist cache: ${e.toString()}',
      );
    }
  }

  @override
  Future<bool> cacheWishlistProducts(List<ProductModel> products) async {
    try {
      final jsonList = products.map((product) => product.toJson()).toList();
      final success = await sharedPreferences.setString(
        _wishlistProductsKey,
        json.encode(jsonList),
      );
      
      return success;
    } catch (e) {
      throw CacheException(
        message: 'Error caching wishlist products: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ProductModel>> getCachedWishlistProducts() async {
    try {
      final jsonString = sharedPreferences.getString(_wishlistProductsKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData
          .map((item) => ProductModel.fromJson(item))
          .toList();
    } catch (e) {
      throw CacheException(
        message: 'Error fetching cached wishlist products: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<ProductModel>> getWishlistProducts() async {
    try {
      // Get cached products
      final cachedProducts = await getCachedWishlistProducts();
      
      // If no products are cached, return a sample product
      if (cachedProducts.isEmpty) {
        // Create a list of wishlist items
        final wishlistItems = await getWishlistItems();
        
        // If there are wishlist items but no cached products, create some sample products
        if (wishlistItems.isNotEmpty) {
          final sampleProducts = wishlistItems.map((item) => ProductModel(
            id: item.productId,
            name: 'Sample Product ${item.id.substring(0, 4)}',
            description: 'This is a sample product for the wishlist',
            price: 99.99,
            discountPercentage: 20.0,
            mainImageUrl: 'https://source.unsplash.com/random/400x400?product',
            rating: 4.5,
            reviewCount: 10,
            inStock: true,
            categoryId: 'sample-category',
          )).toList();
          
          // Cache these products for future use
          await cacheWishlistProducts(sampleProducts);
          
          return sampleProducts;
        }
      }
      
      return cachedProducts;
    } catch (e) {
      throw CacheException(
        message: 'Error fetching wishlist products: ${e.toString()}',
      );
    }
  }
} 