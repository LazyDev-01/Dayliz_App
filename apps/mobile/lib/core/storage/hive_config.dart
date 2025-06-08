import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Hive configuration and initialization for high-performance local storage
class HiveConfig {
  static const String _cartBoxName = 'cart_box';
  static const String _userPreferencesBoxName = 'user_preferences_box';
  static const String _cacheBoxName = 'cache_box';
  static const String _productCacheBoxName = 'product_cache_box';

  /// Initialize Hive with all required boxes
  static Future<void> initialize() async {
    try {
      // Initialize Hive for Flutter
      await Hive.initFlutter();

      // Register adapters if needed (for custom objects)
      // Note: For now we'll use basic types and JSON strings
      // Later we can add custom adapters for better performance

      // Open all required boxes
      await Future.wait([
        _openBox(_cartBoxName),
        _openBox(_userPreferencesBoxName),
        _openBox(_cacheBoxName),
        _openBox(_productCacheBoxName),
      ]);

      debugPrint('✅ Hive initialized successfully with all boxes');
    } catch (e) {
      debugPrint('❌ Failed to initialize Hive: $e');
      rethrow;
    }
  }

  /// Safely open a Hive box with error handling
  static Future<Box> _openBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box(boxName);
      }
      return await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('❌ Failed to open Hive box "$boxName": $e');
      // If box is corrupted, delete and recreate
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return await Hive.openBox(boxName);
      } catch (deleteError) {
        debugPrint('❌ Failed to recreate corrupted box "$boxName": $deleteError');
        rethrow;
      }
    }
  }

  /// Get cart storage box
  static Box get cartBox {
    if (!Hive.isBoxOpen(_cartBoxName)) {
      throw Exception('Cart box is not open. Call HiveConfig.initialize() first.');
    }
    return Hive.box(_cartBoxName);
  }

  /// Get user preferences storage box
  static Box get userPreferencesBox {
    if (!Hive.isBoxOpen(_userPreferencesBoxName)) {
      throw Exception('User preferences box is not open. Call HiveConfig.initialize() first.');
    }
    return Hive.box(_userPreferencesBoxName);
  }

  /// Get cache storage box
  static Box get cacheBox {
    if (!Hive.isBoxOpen(_cacheBoxName)) {
      throw Exception('Cache box is not open. Call HiveConfig.initialize() first.');
    }
    return Hive.box(_cacheBoxName);
  }

  /// Get product cache storage box
  static Box get productCacheBox {
    if (!Hive.isBoxOpen(_productCacheBoxName)) {
      throw Exception('Product cache box is not open. Call HiveConfig.initialize() first.');
    }
    return Hive.box(_productCacheBoxName);
  }

  /// Clear all data (useful for logout or reset)
  static Future<void> clearAllData() async {
    try {
      await Future.wait([
        cartBox.clear(),
        userPreferencesBox.clear(),
        cacheBox.clear(),
        productCacheBox.clear(),
      ]);
      debugPrint('✅ All Hive data cleared successfully');
    } catch (e) {
      debugPrint('❌ Failed to clear Hive data: $e');
      rethrow;
    }
  }

  /// Close all boxes (call on app termination)
  static Future<void> closeAll() async {
    try {
      await Hive.close();
      debugPrint('✅ All Hive boxes closed successfully');
    } catch (e) {
      debugPrint('❌ Failed to close Hive boxes: $e');
    }
  }

  /// Get storage statistics for debugging
  static Map<String, dynamic> getStorageStats() {
    final stats = <String, dynamic>{};
    
    try {
      if (Hive.isBoxOpen(_cartBoxName)) {
        stats['cart_items'] = cartBox.length;
      }
      if (Hive.isBoxOpen(_userPreferencesBoxName)) {
        stats['user_preferences'] = userPreferencesBox.length;
      }
      if (Hive.isBoxOpen(_cacheBoxName)) {
        stats['cache_items'] = cacheBox.length;
      }
      if (Hive.isBoxOpen(_productCacheBoxName)) {
        stats['product_cache_items'] = productCacheBox.length;
      }
    } catch (e) {
      stats['error'] = e.toString();
    }

    return stats;
  }
}
