import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/banner_model.dart';
import '../../core/error/exceptions.dart';

/// Abstract interface for banner local data source
abstract class BannerLocalDataSource {
  /// Get cached banners from local storage
  Future<List<BannerModel>> getCachedBanners();
  
  /// Cache banners to local storage
  Future<void> cacheBanners(List<BannerModel> banners);
  
  /// Clear cached banners
  Future<void> clearCachedBanners();
  
  /// Check if banners are cached and not expired
  Future<bool> hasCachedBanners();
  
  /// Get cache timestamp
  Future<DateTime?> getCacheTimestamp();
}

/// Implementation of BannerLocalDataSource using SharedPreferences
class BannerLocalDataSourceImpl implements BannerLocalDataSource {
  final SharedPreferences sharedPreferences;
  
  static const String cachedBannersKey = 'CACHED_BANNERS';
  static const String bannersCacheTimestampKey = 'BANNERS_CACHE_TIMESTAMP';
  static const Duration cacheValidDuration = Duration(hours: 2); // Cache valid for 2 hours

  BannerLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<BannerModel>> getCachedBanners() async {
    try {
      // Check if cache is still valid
      final isValid = await _isCacheValid();
      if (!isValid) {
        throw CacheException('Banner cache has expired');
      }

      final jsonString = sharedPreferences.getString(cachedBannersKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => BannerModel.fromJson(json))
            .where((banner) => banner.isValid) // Additional validation
            .toList();
      } else {
        throw CacheException('No cached banners found');
      }
    } catch (e) {
      if (e is CacheException) {
        rethrow;
      }
      throw CacheException('Failed to get cached banners: $e');
    }
  }

  @override
  Future<void> cacheBanners(List<BannerModel> banners) async {
    try {
      // Convert banners to JSON and cache
      final jsonList = banners.map((banner) => banner.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      await sharedPreferences.setString(cachedBannersKey, jsonString);
      await sharedPreferences.setString(
        bannersCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
      
      print('✅ Cached ${banners.length} banners successfully');
    } catch (e) {
      print('❌ Failed to cache banners: $e');
      throw CacheException('Failed to cache banners: $e');
    }
  }

  @override
  Future<void> clearCachedBanners() async {
    try {
      await sharedPreferences.remove(cachedBannersKey);
      await sharedPreferences.remove(bannersCacheTimestampKey);
      print('✅ Cleared banner cache successfully');
    } catch (e) {
      print('❌ Failed to clear banner cache: $e');
      throw CacheException('Failed to clear banner cache: $e');
    }
  }

  @override
  Future<bool> hasCachedBanners() async {
    try {
      final hasData = sharedPreferences.containsKey(cachedBannersKey);
      final isValid = await _isCacheValid();
      return hasData && isValid;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DateTime?> getCacheTimestamp() async {
    try {
      final timestampString = sharedPreferences.getString(bannersCacheTimestampKey);
      if (timestampString != null) {
        return DateTime.parse(timestampString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if the cached data is still valid (not expired)
  Future<bool> _isCacheValid() async {
    try {
      final timestamp = await getCacheTimestamp();
      if (timestamp == null) return false;
      
      final now = DateTime.now();
      final difference = now.difference(timestamp);
      
      return difference <= cacheValidDuration;
    } catch (e) {
      return false;
    }
  }
}
