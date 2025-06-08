import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Advanced cache manager for API responses and files
class AdvancedCacheManager {
  static const String _apiCacheKey = 'api_cache';
  static const String _imageCacheKey = 'image_cache';
  static const String _productCacheKey = 'product_cache';

  /// API response cache manager with optimized settings
  static final CacheManager apiCache = CacheManager(
    Config(
      _apiCacheKey,
      stalePeriod: const Duration(hours: 2), // Cache for 2 hours
      maxNrOfCacheObjects: 1000, // Store up to 1000 API responses
      repo: JsonCacheInfoRepository(databaseName: _apiCacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Image cache manager with optimized settings for product images
  static final CacheManager imageCache = CacheManager(
    Config(
      _imageCacheKey,
      stalePeriod: const Duration(days: 7), // Images cache for 7 days
      maxNrOfCacheObjects: 2000, // Store up to 2000 images
      repo: JsonCacheInfoRepository(databaseName: _imageCacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Product-specific cache manager for product data
  static final CacheManager productCache = CacheManager(
    Config(
      _productCacheKey,
      stalePeriod: const Duration(hours: 4), // Product data cache for 4 hours
      maxNrOfCacheObjects: 5000, // Store up to 5000 product entries
      repo: JsonCacheInfoRepository(databaseName: _productCacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Cache API response with automatic JSON handling
  static Future<void> cacheApiResponse(
    String key,
    Map<String, dynamic> data, {
    Duration? maxAge,
  }) async {
    try {
      final jsonString = json.encode(data);
      final bytes = utf8.encode(jsonString);
      
      await apiCache.putFile(
        key,
        bytes,
        maxAge: maxAge ?? const Duration(hours: 2),
        fileExtension: 'json',
      );
      
      debugPrint('✅ Cached API response for key: $key');
    } catch (e) {
      debugPrint('❌ Failed to cache API response for key $key: $e');
    }
  }

  /// Get cached API response with automatic JSON parsing
  static Future<Map<String, dynamic>?> getCachedApiResponse(String key) async {
    try {
      final file = await apiCache.getFileFromCache(key);
      if (file != null) {
        final jsonString = await file.file.readAsString();
        final data = json.decode(jsonString) as Map<String, dynamic>;
        debugPrint('✅ Retrieved cached API response for key: $key');
        return data;
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached API response for key $key: $e');
    }
    return null;
  }

  /// Cache product list with metadata
  static Future<void> cacheProductList(
    String key,
    List<Map<String, dynamic>> products, {
    Duration? maxAge,
  }) async {
    try {
      final cacheData = {
        'products': products,
        'cached_at': DateTime.now().toIso8601String(),
        'count': products.length,
      };
      
      await cacheApiResponse(
        'products_$key',
        cacheData,
        maxAge: maxAge ?? const Duration(hours: 4),
      );
      
      debugPrint('✅ Cached ${products.length} products for key: $key');
    } catch (e) {
      debugPrint('❌ Failed to cache product list for key $key: $e');
    }
  }

  /// Get cached product list with metadata validation
  static Future<List<Map<String, dynamic>>?> getCachedProductList(String key) async {
    try {
      final cacheData = await getCachedApiResponse('products_$key');
      if (cacheData != null) {
        final products = cacheData['products'] as List<dynamic>?;
        if (products != null) {
          final productList = products.cast<Map<String, dynamic>>();
          debugPrint('✅ Retrieved ${productList.length} cached products for key: $key');
          return productList;
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to get cached product list for key $key: $e');
    }
    return null;
  }

  /// Preload critical images for better performance
  static Future<void> preloadCriticalImages(List<String> imageUrls) async {
    try {
      final futures = imageUrls.map((url) => imageCache.downloadFile(url));
      await Future.wait(futures);
      debugPrint('✅ Preloaded ${imageUrls.length} critical images');
    } catch (e) {
      debugPrint('❌ Failed to preload critical images: $e');
    }
  }

  /// Clear specific cache type
  static Future<void> clearCache(CacheType type) async {
    try {
      switch (type) {
        case CacheType.api:
          await apiCache.emptyCache();
          debugPrint('✅ API cache cleared');
          break;
        case CacheType.images:
          await imageCache.emptyCache();
          debugPrint('✅ Image cache cleared');
          break;
        case CacheType.products:
          await productCache.emptyCache();
          debugPrint('✅ Product cache cleared');
          break;
        case CacheType.all:
          await Future.wait([
            apiCache.emptyCache(),
            imageCache.emptyCache(),
            productCache.emptyCache(),
          ]);
          debugPrint('✅ All caches cleared');
          break;
      }
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  /// Get cache statistics for debugging
  static Future<Map<String, dynamic>> getCacheStats() async {
    final stats = <String, dynamic>{};
    
    try {
      // This is a simplified version - actual implementation would need
      // to access internal cache statistics
      stats['api_cache_available'] = true;
      stats['image_cache_available'] = true;
      stats['product_cache_available'] = true;
      stats['timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      stats['error'] = e.toString();
    }

    return stats;
  }
}

/// Cache types for selective clearing
enum CacheType {
  api,
  images,
  products,
  all,
}
