import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../../core/errors/exceptions.dart';

/// Interface for the local data source for product data
abstract class ProductLocalDataSource {
  /// Get cached products
  Future<List<ProductModel>> getCachedProducts();

  /// Cache products
  Future<void> cacheProducts(List<ProductModel> products);

  /// Get a cached product by ID
  Future<ProductModel> getCachedProductById(String id);

  /// Cache a product
  Future<void> cacheProduct(ProductModel product);

  /// Get cached featured products
  Future<List<ProductModel>> getCachedFeaturedProducts();

  /// Cache featured products
  Future<void> cacheFeaturedProducts(List<ProductModel> products);

  /// Get cached products on sale
  Future<List<ProductModel>> getCachedProductsOnSale();

  /// Cache products on sale
  Future<void> cacheProductsOnSale(List<ProductModel> products);

  /// Get cached related products for a product
  Future<List<ProductModel>> getCachedRelatedProducts(String productId);

  /// Cache related products for a product
  Future<void> cacheRelatedProducts(String productId, List<ProductModel> products);

  /// Get cached search results for a query
  Future<List<ProductModel>> getCachedSearchResults(String query);

  /// Cache search results for a query
  Future<void> cacheSearchResults(String query, List<ProductModel> products);

  /// Get cached products by category
  Future<List<ProductModel>> getLastProductsByCategory(String categoryId);

  /// Cache products by category
  Future<void> cacheProductsByCategory(String categoryId, List<ProductModel> products);

  /// Get cached products by IDs
  Future<List<ProductModel>> getLastProductsByIds(List<String> ids);

  /// Cache products by IDs
  Future<void> cacheProductsByIds(List<String> ids, List<ProductModel> products);

  /// Clear all cached data
  Future<void> clearCache();
}

/// Implementation of the ProductLocalDataSource interface using SharedPreferences
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final SharedPreferences sharedPreferences;

  // SharedPreferences keys
  static const String cachedProductsKey = 'CACHED_PRODUCTS';
  static const String cachedFeaturedProductsKey = 'CACHED_FEATURED_PRODUCTS';
  static const String cachedProductsOnSaleKey = 'CACHED_PRODUCTS_ON_SALE';
  static const String cachedRelatedProductsPrefix = 'CACHED_RELATED_PRODUCTS_';
  static const String cachedSearchResultsPrefix = 'CACHED_SEARCH_RESULTS_';
  static const String cachedCategoryProductsPrefix = 'CACHED_CATEGORY_PRODUCTS_';
  static const String cachedProductsByIdsKey = 'CACHED_PRODUCTS_BY_IDS_';

  ProductLocalDataSourceImpl({required this.sharedPreferences});

  /// Get cached products
  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final jsonString = sharedPreferences.getString(cachedProductsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(message: 'No cached products found');
    }
  }

  /// Cache products
  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      cachedProductsKey,
      json.encode(jsonList),
    );
  }

  /// Get a cached product by ID
  @override
  Future<ProductModel> getCachedProductById(String id) async {
    final jsonString = sharedPreferences.getString(cachedProductsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      final productJson = jsonList.firstWhere(
        (json) => json['id'] == id,
        orElse: () => null,
      );
      
      if (productJson != null) {
        return ProductModel.fromJson(productJson);
      }
    }
    
    throw CacheException(message: 'No cached product found with ID: $id');
  }

  /// Cache a product
  @override
  Future<void> cacheProduct(ProductModel product) async {
    // First, try to get the existing cached products
    try {
      final cachedProducts = await getCachedProducts();
      
      // Check if the product already exists in the cache
      final index = cachedProducts.indexWhere((p) => p.id == product.id);
      
      if (index >= 0) {
        // Update the existing product
        cachedProducts[index] = product;
      } else {
        // Add the new product
        cachedProducts.add(product);
      }
      
      // Save the updated list
      await cacheProducts(cachedProducts);
    } on CacheException {
      // If there are no cached products yet, create a new list
      await cacheProducts([product]);
    }
  }

  /// Get cached featured products
  @override
  Future<List<ProductModel>> getCachedFeaturedProducts() async {
    final jsonString = sharedPreferences.getString(cachedFeaturedProductsKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(message: 'No cached featured products found');
    }
  }

  /// Cache featured products
  @override
  Future<void> cacheFeaturedProducts(List<ProductModel> products) async {
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      cachedFeaturedProductsKey,
      json.encode(jsonList),
    );
  }

  /// Get cached products on sale
  @override
  Future<List<ProductModel>> getCachedProductsOnSale() async {
    final jsonString = sharedPreferences.getString(cachedProductsOnSaleKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(message: 'No cached products on sale found');
    }
  }

  /// Cache products on sale
  @override
  Future<void> cacheProductsOnSale(List<ProductModel> products) async {
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      cachedProductsOnSaleKey,
      json.encode(jsonList),
    );
  }

  /// Get cached related products for a product
  @override
  Future<List<ProductModel>> getCachedRelatedProducts(String productId) async {
    final jsonString = sharedPreferences.getString(
      '$cachedRelatedProductsPrefix$productId',
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(
        message: 'No cached related products found for product: $productId',
      );
    }
  }

  /// Cache related products for a product
  @override
  Future<void> cacheRelatedProducts(
    String productId,
    List<ProductModel> products,
  ) async {
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      '$cachedRelatedProductsPrefix$productId',
      json.encode(jsonList),
    );
  }

  /// Get cached search results for a query
  @override
  Future<List<ProductModel>> getCachedSearchResults(String query) async {
    final String normalizedQuery = query.toLowerCase().trim();
    final jsonString = sharedPreferences.getString(
      '$cachedSearchResultsPrefix$normalizedQuery',
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(
        message: 'No cached search results found for query: $query',
      );
    }
  }

  /// Cache search results for a query
  @override
  Future<void> cacheSearchResults(
    String query,
    List<ProductModel> products,
  ) async {
    final String normalizedQuery = query.toLowerCase().trim();
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      '$cachedSearchResultsPrefix$normalizedQuery',
      json.encode(jsonList),
    );
  }

  /// Get cached products by category ID
  @override
  Future<List<ProductModel>> getLastProductsByCategory(String categoryId) async {
    final jsonString = sharedPreferences.getString(
      '$cachedCategoryProductsPrefix$categoryId',
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(
        message: 'No cached products found for category: $categoryId',
      );
    }
  }

  /// Cache products by category ID
  @override
  Future<void> cacheProductsByCategory(
    String categoryId,
    List<ProductModel> products,
  ) async {
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      '$cachedCategoryProductsPrefix$categoryId',
      json.encode(jsonList),
    );
  }

  /// Get cached products by IDs
  @override
  Future<List<ProductModel>> getLastProductsByIds(List<String> ids) async {
    final String idsKey = ids.join('-');
    final jsonString = sharedPreferences.getString(
      '$cachedProductsByIdsKey$idsKey',
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ProductModel.fromJson(json)).toList();
    } else {
      throw CacheException(
        message: 'No cached products found for ids: ${ids.join(", ")}',
      );
    }
  }

  /// Cache products by IDs
  @override
  Future<void> cacheProductsByIds(
    List<String> ids,
    List<ProductModel> products,
  ) async {
    final String idsKey = ids.join('-');
    final List<Map<String, dynamic>> jsonList = products
        .map((product) => product.toJson())
        .toList();
    await sharedPreferences.setString(
      '$cachedProductsByIdsKey$idsKey',
      json.encode(jsonList),
    );
  }

  /// Clear all cached data
  @override
  Future<void> clearCache() async {
    final keys = sharedPreferences.getKeys();
    
    // Remove all product-related cache entries
    for (final key in keys) {
      if (key.startsWith('CACHED_')) {
        await sharedPreferences.remove(key);
      }
    }
  }
}