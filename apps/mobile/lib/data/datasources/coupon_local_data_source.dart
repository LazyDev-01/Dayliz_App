import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/exceptions.dart';
import '../models/coupon_model.dart';

/// Abstract class for coupon local data source
abstract class CouponLocalDataSource {
  Future<List<CouponModel>> getCachedAvailableCoupons();
  Future<void> cacheAvailableCoupons(List<CouponModel> coupons);

  Future<List<CouponWithUserInfo>> getCachedUserCoupons(String userId);
  Future<void> cacheUserCoupons(String userId, List<CouponWithUserInfo> coupons);

  Future<CouponModel?> getCachedCouponByCode(String code);
  Future<void> cacheCoupon(CouponModel coupon);

  Future<List<CouponModel>> getCachedTrendingCoupons();
  Future<void> cacheTrendingCoupons(List<CouponModel> coupons);

  Future<CouponModel?> getCachedBestCouponForOrder(String userId, double orderValue);
  Future<void> cacheBestCouponForOrder(String userId, double orderValue, CouponModel? coupon);

  Future<void> clearCachedCoupons();
  Future<void> clearUserCoupons(String userId);
}

/// SharedPreferences implementation of coupon local data source
class CouponSharedPrefsDataSource implements CouponLocalDataSource {
  final SharedPreferences sharedPreferences;

  CouponSharedPrefsDataSource({required this.sharedPreferences});

  static const String _availableCouponsKey = 'CACHED_AVAILABLE_COUPONS';
  static const String _userCouponsKey = 'CACHED_USER_COUPONS';
  static const String _couponByCodeKey = 'CACHED_COUPON_BY_CODE';
  static const String _trendingCouponsKey = 'CACHED_TRENDING_COUPONS';
  static const String _bestCouponKey = 'CACHED_BEST_COUPON';
  static const String _cacheTimestampKey = 'COUPON_CACHE_TIMESTAMP';

  // Cache expiry time (1 hour)
  static const Duration _cacheExpiry = Duration(hours: 1);

  @override
  Future<List<CouponModel>> getCachedAvailableCoupons() async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Getting cached available coupons');

      if (!_isCacheValid(_availableCouponsKey)) {
        throw CacheException(message: 'Cache expired');
      }

      final couponsJson = sharedPreferences.getString(_availableCouponsKey);
      if (couponsJson == null) {
        throw CacheException(message: 'No cached available coupons found');
      }

      final List<dynamic> couponsList = jsonDecode(couponsJson);
      return couponsList.map((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error getting cached available coupons: $e');
      throw CacheException(message: 'Failed to get cached available coupons');
    }
  }

  @override
  Future<void> cacheAvailableCoupons(List<CouponModel> coupons) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Caching available coupons: ${coupons.length}');

      final couponsJson = jsonEncode(coupons.map((coupon) => coupon.toJson()).toList());
      await sharedPreferences.setString(_availableCouponsKey, couponsJson);
      await _setCacheTimestamp(_availableCouponsKey);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error caching available coupons: $e');
      throw CacheException(message: 'Failed to cache available coupons');
    }
  }

  @override
  Future<List<CouponWithUserInfo>> getCachedUserCoupons(String userId) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Getting cached user coupons for: $userId');

      final key = '${_userCouponsKey}_$userId';
      if (!_isCacheValid(key)) {
        throw CacheException(message: 'Cache expired');
      }

      final couponsJson = sharedPreferences.getString(key);
      if (couponsJson == null) {
        throw CacheException(message: 'No cached user coupons found');
      }

      final List<dynamic> couponsList = jsonDecode(couponsJson);
      return couponsList.map((json) {
        // For local cache, we store the full CouponWithUserInfo data
        return CouponWithUserInfo(
          id: json['id'],
          code: json['code'],
          description: json['description'],
          discountValue: (json['discount_value'] as num).toDouble(),
          discountType: json['discount_type'],
          minimumOrderValue: json['minimum_order_value'] != null 
              ? (json['minimum_order_value'] as num).toDouble() 
              : null,
          maximumDiscount: json['maximum_discount'] != null 
              ? (json['maximum_discount'] as num).toDouble() 
              : null,
          startDate: DateTime.parse(json['start_date']),
          endDate: DateTime.parse(json['end_date']),
          usageLimit: json['usage_limit'],
          isActive: json['is_active'] ?? true,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: json['updated_at'] != null 
              ? DateTime.parse(json['updated_at']) 
              : null,
          isCollected: json['is_collected'] ?? false,
          isUsed: json['is_used'] ?? false,
          collectedAt: json['collected_at'] != null 
              ? DateTime.parse(json['collected_at']) 
              : null,
          usedAt: json['used_at'] != null 
              ? DateTime.parse(json['used_at']) 
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error getting cached user coupons: $e');
      throw CacheException(message: 'Failed to get cached user coupons');
    }
  }

  @override
  Future<void> cacheUserCoupons(String userId, List<CouponWithUserInfo> coupons) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Caching user coupons for $userId: ${coupons.length}');

      final key = '${_userCouponsKey}_$userId';
      final couponsJson = jsonEncode(coupons.map((coupon) {
        final json = coupon.toJson();
        json['is_collected'] = coupon.isCollected;
        json['is_used'] = coupon.isUsed;
        json['collected_at'] = coupon.collectedAt?.toIso8601String();
        json['used_at'] = coupon.usedAt?.toIso8601String();
        return json;
      }).toList());

      await sharedPreferences.setString(key, couponsJson);
      await _setCacheTimestamp(key);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error caching user coupons: $e');
      throw CacheException(message: 'Failed to cache user coupons');
    }
  }

  @override
  Future<CouponModel?> getCachedCouponByCode(String code) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Getting cached coupon by code: $code');

      final key = '${_couponByCodeKey}_${code.toUpperCase()}';
      if (!_isCacheValid(key)) {
        return null;
      }

      final couponJson = sharedPreferences.getString(key);
      if (couponJson == null) {
        return null;
      }

      final Map<String, dynamic> couponMap = jsonDecode(couponJson);
      return CouponModel.fromJson(couponMap);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error getting cached coupon by code: $e');
      return null;
    }
  }

  @override
  Future<void> cacheCoupon(CouponModel coupon) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Caching coupon: ${coupon.code}');

      final key = '${_couponByCodeKey}_${coupon.code.toUpperCase()}';
      final couponJson = jsonEncode(coupon.toJson());
      await sharedPreferences.setString(key, couponJson);
      await _setCacheTimestamp(key);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error caching coupon: $e');
      throw CacheException(message: 'Failed to cache coupon');
    }
  }

  @override
  Future<List<CouponModel>> getCachedTrendingCoupons() async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Getting cached trending coupons');

      if (!_isCacheValid(_trendingCouponsKey)) {
        throw CacheException(message: 'Cache expired');
      }

      final couponsJson = sharedPreferences.getString(_trendingCouponsKey);
      if (couponsJson == null) {
        throw CacheException(message: 'No cached trending coupons found');
      }

      final List<dynamic> couponsList = jsonDecode(couponsJson);
      return couponsList.map((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error getting cached trending coupons: $e');
      throw CacheException(message: 'Failed to get cached trending coupons');
    }
  }

  @override
  Future<void> cacheTrendingCoupons(List<CouponModel> coupons) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Caching trending coupons: ${coupons.length}');

      final couponsJson = jsonEncode(coupons.map((coupon) => coupon.toJson()).toList());
      await sharedPreferences.setString(_trendingCouponsKey, couponsJson);
      await _setCacheTimestamp(_trendingCouponsKey);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error caching trending coupons: $e');
      throw CacheException(message: 'Failed to cache trending coupons');
    }
  }

  @override
  Future<CouponModel?> getCachedBestCouponForOrder(String userId, double orderValue) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Getting cached best coupon for order: $userId, $orderValue');

      final key = '${_bestCouponKey}_${userId}_${orderValue.toInt()}';
      if (!_isCacheValid(key)) {
        return null;
      }

      final couponJson = sharedPreferences.getString(key);
      if (couponJson == null) {
        return null;
      }

      final Map<String, dynamic> couponMap = jsonDecode(couponJson);
      return CouponModel.fromJson(couponMap);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error getting cached best coupon: $e');
      return null;
    }
  }

  @override
  Future<void> cacheBestCouponForOrder(String userId, double orderValue, CouponModel? coupon) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Caching best coupon for order: $userId, $orderValue');

      final key = '${_bestCouponKey}_${userId}_${orderValue.toInt()}';
      
      if (coupon != null) {
        final couponJson = jsonEncode(coupon.toJson());
        await sharedPreferences.setString(key, couponJson);
      } else {
        await sharedPreferences.setString(key, 'null');
      }
      
      await _setCacheTimestamp(key);
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error caching best coupon: $e');
      throw CacheException(message: 'Failed to cache best coupon');
    }
  }

  @override
  Future<void> clearCachedCoupons() async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Clearing all cached coupons');

      final keys = sharedPreferences.getKeys().where((key) => 
        key.startsWith(_availableCouponsKey) ||
        key.startsWith(_couponByCodeKey) ||
        key.startsWith(_trendingCouponsKey) ||
        key.startsWith(_bestCouponKey) ||
        key.startsWith(_cacheTimestampKey)
      ).toList();

      for (final key in keys) {
        await sharedPreferences.remove(key);
      }
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error clearing cached coupons: $e');
      throw CacheException(message: 'Failed to clear cached coupons');
    }
  }

  @override
  Future<void> clearUserCoupons(String userId) async {
    try {
      debugPrint('🎫 [CouponLocalDataSource] Clearing cached user coupons for: $userId');

      final key = '${_userCouponsKey}_$userId';
      await sharedPreferences.remove(key);
      await sharedPreferences.remove('${_cacheTimestampKey}_$key');
    } catch (e) {
      debugPrint('❌ [CouponLocalDataSource] Error clearing user coupons: $e');
      throw CacheException(message: 'Failed to clear user coupons');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String key) {
    final timestampKey = '${_cacheTimestampKey}_$key';
    final timestamp = sharedPreferences.getInt(timestampKey);
    
    if (timestamp == null) return false;
    
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    
    return now.difference(cacheTime) < _cacheExpiry;
  }

  /// Set cache timestamp
  Future<void> _setCacheTimestamp(String key) async {
    final timestampKey = '${_cacheTimestampKey}_$key';
    await sharedPreferences.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }
}
