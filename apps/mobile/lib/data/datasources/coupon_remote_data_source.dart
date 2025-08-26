import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/coupon.dart';
import '../models/coupon_model.dart';

/// Abstract class for coupon remote data source
abstract class CouponRemoteDataSource {
  Future<List<CouponModel>> getAvailableCoupons({
    int page = 1,
    int limit = 20,
  });

  Future<List<CouponWithUserInfo>> getUserCoupons({
    required String userId,
    int page = 1,
    int limit = 20,
    bool? isUsed,
  });

  Future<CouponModel> getCouponByCode(String code);
  Future<CouponModel> getCouponById(String id);

  Future<CouponApplicationResult> validateCoupon({
    required String couponCode,
    required double orderValue,
    required String userId,
  });

  Future<UserCouponModel> applyCouponToUser({
    required String couponId,
    required String userId,
  });

  Future<UserCouponModel> useCoupon({
    required String couponCode,
    required String userId,
    required String orderId,
  });

  Future<Map<String, dynamic>> getCouponUsageStats(String userId);
  Future<List<CouponModel>> searchCoupons({
    required String keyword,
    int page = 1,
    int limit = 20,
  });

  Future<List<CouponModel>> getTrendingCoupons({int limit = 10});
  Future<List<CouponModel>> getCouponsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
  });

  Future<bool> hasUserCollectedCoupon({
    required String userId,
    required String couponId,
  });

  Future<List<UserCouponModel>> getUserCouponHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  Future<CouponModel?> getBestCouponForOrder({
    required double orderValue,
    required String userId,
  });

  Future<List<CouponWithUserInfo>> getExpiringSoonCoupons({
    required String userId,
    int daysThreshold = 7,
  });
}

/// Supabase implementation of coupon remote data source
class CouponSupabaseDataSource implements CouponRemoteDataSource {
  final SupabaseClient client;

  CouponSupabaseDataSource({required this.client});

  @override
  Future<List<CouponModel>> getAvailableCoupons({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting available coupons (page: $page, limit: $limit)');

      final response = await client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return response.map<CouponModel>((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting available coupons: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CouponWithUserInfo>> getUserCoupons({
    required String userId,
    int page = 1,
    int limit = 20,
    bool? isUsed,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting user coupons for user: $userId');

      var query = client
          .from('user_coupons')
          .select('''
            *,
            coupons (*)
          ''')
          .eq('user_id', userId);

      if (isUsed != null) {
        query = query.eq('is_used', isUsed);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return response.map<CouponWithUserInfo>((json) {
        final couponJson = json['coupons'] as Map<String, dynamic>;
        final userCouponJson = {
          'is_used': json['is_used'],
          'used_at': json['used_at'],
          'created_at': json['created_at'],
          'updated_at': json['updated_at'],
        };

        return CouponWithUserInfo.fromJsonWithUserData(couponJson, userCouponJson);
      }).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting user coupons: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CouponModel> getCouponByCode(String code) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting coupon by code: $code');

      final response = await client
          .from('coupons')
          .select()
          .eq('code', code.toUpperCase())
          .single();

      return CouponModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting coupon by code: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CouponModel> getCouponById(String id) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting coupon by ID: $id');

      final response = await client
          .from('coupons')
          .select()
          .eq('id', id)
          .single();

      return CouponModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting coupon by ID: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CouponApplicationResult> validateCoupon({
    required String couponCode,
    required double orderValue,
    required String userId,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Validating coupon: $couponCode for order value: $orderValue');

      // Get coupon by code
      final coupon = await getCouponByCode(couponCode);

      // Check if coupon is valid
      if (!coupon.isValid) {
        if (coupon.isExpired) {
          return CouponApplicationResult.failure('Coupon has expired');
        } else if (coupon.isNotStarted) {
          return CouponApplicationResult.failure('Coupon is not yet active');
        } else {
          return CouponApplicationResult.failure('Coupon is not active');
        }
      }

      // Check minimum order value
      if (coupon.minimumOrderValue != null && orderValue < coupon.minimumOrderValue!) {
        return CouponApplicationResult.failure(
          'Minimum order value of ₹${coupon.minimumOrderValue!.toInt()} required'
        );
      }

      // Check if user has collected this coupon
      final hasCollected = await hasUserCollectedCoupon(
        userId: userId,
        couponId: coupon.id,
      );

      if (!hasCollected) {
        return CouponApplicationResult.failure('Coupon not available in your account');
      }

      // Check if user has already used this coupon
      final userCouponResponse = await client
          .from('user_coupons')
          .select()
          .eq('user_id', userId)
          .eq('coupon_id', coupon.id)
          .eq('is_used', true)
          .maybeSingle();

      if (userCouponResponse != null) {
        return CouponApplicationResult.failure('Coupon has already been used');
      }

      // Calculate discount
      final discountAmount = coupon.calculateDiscount(orderValue);

      return CouponApplicationResult.success(
        discountAmount: discountAmount,
        coupon: coupon,
      );
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error validating coupon: $e');
      if (e is ServerException) {
        return CouponApplicationResult.failure('Coupon not found');
      }
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserCouponModel> applyCouponToUser({
    required String couponId,
    required String userId,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Applying coupon to user: $userId, coupon: $couponId');

      // Check if user already has this coupon
      final existingUserCoupon = await client
          .from('user_coupons')
          .select()
          .eq('user_id', userId)
          .eq('coupon_id', couponId)
          .maybeSingle();

      if (existingUserCoupon != null) {
        throw ServerException(message: 'Coupon already collected');
      }

      // Add coupon to user's account
      final response = await client
          .from('user_coupons')
          .insert({
            'user_id': userId,
            'coupon_id': couponId,
            'is_used': false,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return UserCouponModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error applying coupon to user: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<UserCouponModel> useCoupon({
    required String couponCode,
    required String userId,
    required String orderId,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Using coupon: $couponCode for order: $orderId');

      // Get coupon by code
      final coupon = await getCouponByCode(couponCode);

      // Find user's coupon record
      final userCouponResponse = await client
          .from('user_coupons')
          .select()
          .eq('user_id', userId)
          .eq('coupon_id', coupon.id)
          .eq('is_used', false)
          .single();

      // Mark coupon as used
      final updatedResponse = await client
          .from('user_coupons')
          .update({
            'is_used': true,
            'used_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userCouponResponse['id'])
          .select()
          .single();

      return UserCouponModel.fromJson(updatedResponse);
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error using coupon: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getCouponUsageStats(String userId) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting coupon usage stats for user: $userId');

      final response = await client.rpc('get_coupon_usage_stats', params: {
        'user_id_param': userId,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting coupon usage stats: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CouponModel>> searchCoupons({
    required String keyword,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Searching coupons with keyword: $keyword');

      final response = await client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String())
          .or('code.ilike.%$keyword%,description.ilike.%$keyword%')
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return response.map<CouponModel>((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error searching coupons: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CouponModel>> getTrendingCoupons({int limit = 10}) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting trending coupons');

      // For now, return most recently created active coupons
      // In the future, this could be based on usage statistics
      final response = await client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<CouponModel>((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting trending coupons: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CouponModel>> getCouponsByCategory({
    required String category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting coupons by category: $category');

      // For now, filter by discount type as category
      final response = await client
          .from('coupons')
          .select()
          .eq('is_active', true)
          .eq('discount_type', category)
          .lte('start_date', DateTime.now().toIso8601String())
          .gte('end_date', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return response.map<CouponModel>((json) => CouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting coupons by category: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<bool> hasUserCollectedCoupon({
    required String userId,
    required String couponId,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Checking if user has collected coupon: $userId, $couponId');

      final response = await client
          .from('user_coupons')
          .select('id')
          .eq('user_id', userId)
          .eq('coupon_id', couponId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error checking user coupon collection: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<UserCouponModel>> getUserCouponHistory({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting user coupon history: $userId');

      final response = await client
          .from('user_coupons')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return response.map<UserCouponModel>((json) => UserCouponModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting user coupon history: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<CouponModel?> getBestCouponForOrder({
    required double orderValue,
    required String userId,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting best coupon for order value: $orderValue');

      // Get user's available coupons
      final userCoupons = await getUserCoupons(userId: userId, isUsed: false);

      if (userCoupons.isEmpty) return null;

      // Calculate discount for each coupon and find the best one
      CouponModel? bestCoupon;
      double maxDiscount = 0.0;

      for (final couponWithInfo in userCoupons) {
        if (couponWithInfo.isValid && couponWithInfo.canBeUsed) {
          final discount = couponWithInfo.calculateDiscount(orderValue);
          if (discount > maxDiscount) {
            maxDiscount = discount;
            bestCoupon = CouponModel.fromEntity(couponWithInfo);
          }
        }
      }

      return bestCoupon;
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting best coupon for order: $e');
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<CouponWithUserInfo>> getExpiringSoonCoupons({
    required String userId,
    int daysThreshold = 7,
  }) async {
    try {
      debugPrint('🎫 [CouponSupabaseDataSource] Getting expiring soon coupons for user: $userId');

      final thresholdDate = DateTime.now().add(Duration(days: daysThreshold));

      final response = await client
          .from('user_coupons')
          .select('''
            *,
            coupons (*)
          ''')
          .eq('user_id', userId)
          .eq('is_used', false)
          .lte('coupons.end_date', thresholdDate.toIso8601String())
          .gte('coupons.end_date', DateTime.now().toIso8601String())
          .order('coupons.end_date', ascending: true);

      return response.map<CouponWithUserInfo>((json) {
        final couponJson = json['coupons'] as Map<String, dynamic>;
        final userCouponJson = {
          'is_used': json['is_used'],
          'used_at': json['used_at'],
          'created_at': json['created_at'],
          'updated_at': json['updated_at'],
        };

        return CouponWithUserInfo.fromJsonWithUserData(couponJson, userCouponJson);
      }).toList();
    } catch (e) {
      debugPrint('❌ [CouponSupabaseDataSource] Error getting expiring soon coupons: $e');
      throw ServerException(message: e.toString());
    }
  }
}
