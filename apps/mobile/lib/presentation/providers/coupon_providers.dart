import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/coupon.dart';
import '../../domain/usecases/coupons/get_available_coupons_usecase.dart';

/// State class for coupons
class CouponState {
  final List<Coupon> availableCoupons;
  final List<Coupon> userCoupons;
  final List<Coupon> trendingCoupons;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final Coupon? appliedCoupon;
  final double appliedDiscount;

  const CouponState({
    this.availableCoupons = const [],
    this.userCoupons = const [],
    this.trendingCoupons = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
    this.appliedCoupon,
    this.appliedDiscount = 0.0,
  });

  CouponState copyWith({
    List<Coupon>? availableCoupons,
    List<Coupon>? userCoupons,
    List<Coupon>? trendingCoupons,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    Coupon? appliedCoupon,
    double? appliedDiscount,
    bool clearError = false,
    bool clearAppliedCoupon = false,
  }) {
    return CouponState(
      availableCoupons: availableCoupons ?? this.availableCoupons,
      userCoupons: userCoupons ?? this.userCoupons,
      trendingCoupons: trendingCoupons ?? this.trendingCoupons,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      appliedCoupon: clearAppliedCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      appliedDiscount: clearAppliedCoupon ? 0.0 : (appliedDiscount ?? this.appliedDiscount),
    );
  }

  /// Check if any coupon is applied
  bool get hasCouponApplied => appliedCoupon != null;

  /// Get applied coupon savings text
  String get appliedCouponSavingsText {
    if (appliedCoupon != null && appliedDiscount > 0) {
      return 'You saved ₹${appliedDiscount.toStringAsFixed(0)} with ${appliedCoupon!.code}';
    }
    return '';
  }
}

/// Provider for coupon state
final couponStateProvider = StateNotifierProvider<CouponNotifier, CouponState>((ref) {
  return CouponNotifier(ref);
});

/// Provider for available coupons
final availableCouponsProvider = Provider<List<Coupon>>((ref) {
  final state = ref.watch(couponStateProvider);
  return state.availableCoupons;
});

/// Provider for user coupons
final userCouponsProvider = Provider<List<Coupon>>((ref) {
  final state = ref.watch(couponStateProvider);
  return state.userCoupons;
});

/// Provider for trending coupons
final trendingCouponsProvider = Provider<List<Coupon>>((ref) {
  final state = ref.watch(couponStateProvider);
  return state.trendingCoupons;
});

/// Provider for applied coupon
final appliedCouponProvider = Provider<Coupon?>((ref) {
  final state = ref.watch(couponStateProvider);
  return state.appliedCoupon;
});

/// Provider for applied discount amount
final appliedDiscountProvider = Provider<double>((ref) {
  final state = ref.watch(couponStateProvider);
  return state.appliedDiscount;
});

/// Coupon state notifier
class CouponNotifier extends StateNotifier<CouponState> {
  final Ref ref;

  CouponNotifier(this.ref) : super(const CouponState()) {
    _initialize();
  }

  /// Initialize coupon system
  Future<void> _initialize() async {
    try {
      // Load initial data
      await loadAvailableCoupons();
      await loadUserCoupons();
      await loadTrendingCoupons();
    } catch (e) {
      debugPrint('Error initializing coupon system: $e');
      state = state.copyWith(
        errorMessage: 'Failed to initialize coupons: $e',
        isLoading: false,
      );
    }
  }

  /// Load available coupons
  Future<void> loadAvailableCoupons({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        availableCoupons: [],
        currentPage: 1,
        hasMore: true,
        clearError: true,
      );
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // TODO: Implement with actual use case
      // For now, using mock data
      await Future.delayed(const Duration(milliseconds: 500));

      final mockCoupons = _generateMockAvailableCoupons();
      
      state = state.copyWith(
        availableCoupons: refresh ? mockCoupons : [...state.availableCoupons, ...mockCoupons],
        isLoading: false,
        hasMore: false, // For mock data
      );
    } catch (e) {
      debugPrint('Error loading available coupons: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load available coupons: $e',
      );
    }
  }

  /// Load user coupons
  Future<void> loadUserCoupons({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        userCoupons: [],
        clearError: true,
      );
    }

    try {
      // TODO: Implement with actual use case
      await Future.delayed(const Duration(milliseconds: 300));

      final mockUserCoupons = _generateMockUserCoupons();
      
      state = state.copyWith(
        userCoupons: mockUserCoupons,
      );
    } catch (e) {
      debugPrint('Error loading user coupons: $e');
      state = state.copyWith(
        errorMessage: 'Failed to load user coupons: $e',
      );
    }
  }

  /// Load trending coupons
  Future<void> loadTrendingCoupons() async {
    try {
      // TODO: Implement with actual use case
      await Future.delayed(const Duration(milliseconds: 200));

      final mockTrendingCoupons = _generateMockTrendingCoupons();
      
      state = state.copyWith(
        trendingCoupons: mockTrendingCoupons,
      );
    } catch (e) {
      debugPrint('Error loading trending coupons: $e');
      state = state.copyWith(
        errorMessage: 'Failed to load trending coupons: $e',
      );
    }
  }

  /// Apply coupon to cart
  Future<bool> applyCoupon(String couponCode, double orderValue) async {
    try {
      debugPrint('🎫 [CouponNotifier] Applying coupon: $couponCode for order value: $orderValue');

      // Find coupon by code
      final coupon = _findCouponByCode(couponCode);
      if (coupon == null) {
        state = state.copyWith(errorMessage: 'Coupon not found');
        return false;
      }

      // Validate coupon
      if (!coupon.isValid) {
        state = state.copyWith(errorMessage: 'Coupon is not valid');
        return false;
      }

      // Check minimum order value
      if (coupon.minimumOrderValue != null && orderValue < coupon.minimumOrderValue!) {
        state = state.copyWith(
          errorMessage: 'Minimum order value of ₹${coupon.minimumOrderValue!.toInt()} required'
        );
        return false;
      }

      // Calculate discount
      final discount = coupon.calculateDiscount(orderValue);

      state = state.copyWith(
        appliedCoupon: coupon,
        appliedDiscount: discount,
        clearError: true,
      );

      return true;
    } catch (e) {
      debugPrint('Error applying coupon: $e');
      state = state.copyWith(errorMessage: 'Failed to apply coupon: $e');
      return false;
    }
  }

  /// Remove applied coupon
  void removeCoupon() {
    state = state.copyWith(
      clearAppliedCoupon: true,
      clearError: true,
    );
  }

  /// Collect/claim a coupon
  Future<bool> collectCoupon(String couponId) async {
    try {
      debugPrint('🎫 [CouponNotifier] Collecting coupon: $couponId');

      // TODO: Implement with actual use case
      await Future.delayed(const Duration(milliseconds: 500));

      // For mock implementation, just add to user coupons
      final coupon = state.availableCoupons.firstWhere(
        (c) => c.id == couponId,
        orElse: () => throw Exception('Coupon not found'),
      );

      final updatedUserCoupons = [...state.userCoupons, coupon];
      
      state = state.copyWith(
        userCoupons: updatedUserCoupons,
        clearError: true,
      );

      return true;
    } catch (e) {
      debugPrint('Error collecting coupon: $e');
      state = state.copyWith(errorMessage: 'Failed to collect coupon: $e');
      return false;
    }
  }

  /// Search coupons
  Future<List<Coupon>> searchCoupons(String keyword) async {
    try {
      debugPrint('🎫 [CouponNotifier] Searching coupons: $keyword');

      // TODO: Implement with actual use case
      await Future.delayed(const Duration(milliseconds: 300));

      // For mock implementation, filter available coupons
      final filteredCoupons = state.availableCoupons.where((coupon) {
        return coupon.code.toLowerCase().contains(keyword.toLowerCase()) ||
               (coupon.description?.toLowerCase().contains(keyword.toLowerCase()) ?? false);
      }).toList();

      return filteredCoupons;
    } catch (e) {
      debugPrint('Error searching coupons: $e');
      return [];
    }
  }

  /// Get best coupon for order value
  Coupon? getBestCouponForOrder(double orderValue) {
    try {
      debugPrint('🎫 [CouponNotifier] Getting best coupon for order value: $orderValue');

      Coupon? bestCoupon;
      double maxDiscount = 0.0;

      for (final coupon in state.userCoupons) {
        if (coupon.isValid) {
          final discount = coupon.calculateDiscount(orderValue);
          if (discount > maxDiscount) {
            maxDiscount = discount;
            bestCoupon = coupon;
          }
        }
      }

      return bestCoupon;
    } catch (e) {
      debugPrint('Error getting best coupon: $e');
      return null;
    }
  }

  /// Find coupon by code
  Coupon? _findCouponByCode(String code) {
    // Search in user coupons first
    try {
      return state.userCoupons.firstWhere(
        (coupon) => coupon.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      // If not found in user coupons, search in available coupons
      try {
        return state.availableCoupons.firstWhere(
          (coupon) => coupon.code.toUpperCase() == code.toUpperCase(),
        );
      } catch (e) {
        return null;
      }
    }
  }

  /// Generate mock available coupons
  List<Coupon> _generateMockAvailableCoupons() {
    return [
      Coupon(
        id: '1',
        code: 'WELCOME20',
        description: 'Welcome offer for new users',
        discountValue: 20,
        discountType: Coupon.discountTypePercentage,
        minimumOrderValue: 200,
        maximumDiscount: 100,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 30)),
        usageLimit: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Coupon(
        id: '2',
        code: 'SAVE50',
        description: 'Flat ₹50 off on orders above ₹300',
        discountValue: 50,
        discountType: Coupon.discountTypeFixed,
        minimumOrderValue: 300,
        startDate: DateTime.now().subtract(const Duration(days: 2)),
        endDate: DateTime.now().add(const Duration(days: 15)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Coupon(
        id: '3',
        code: 'WEEKEND15',
        description: '15% off on weekend orders',
        discountValue: 15,
        discountType: Coupon.discountTypePercentage,
        minimumOrderValue: 150,
        maximumDiscount: 75,
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ];
  }

  /// Generate mock user coupons
  List<Coupon> _generateMockUserCoupons() {
    return [
      Coupon(
        id: '4',
        code: 'FIRST25',
        description: '25% off on your first order',
        discountValue: 25,
        discountType: Coupon.discountTypePercentage,
        minimumOrderValue: 100,
        maximumDiscount: 150,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 45)),
        usageLimit: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Coupon(
        id: '5',
        code: 'LOYALTY100',
        description: 'Loyalty reward - ₹100 off',
        discountValue: 100,
        discountType: Coupon.discountTypeFixed,
        minimumOrderValue: 500,
        startDate: DateTime.now().subtract(const Duration(days: 5)),
        endDate: DateTime.now().add(const Duration(days: 20)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  /// Generate mock trending coupons
  List<Coupon> _generateMockTrendingCoupons() {
    return [
      Coupon(
        id: '6',
        code: 'TRENDING30',
        description: 'Most popular - 30% off',
        discountValue: 30,
        discountType: Coupon.discountTypePercentage,
        minimumOrderValue: 250,
        maximumDiscount: 200,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  void dispose() {
    // PERFORMANCE: Proper disposal of coupon provider resources
    state = const CouponState();
    super.dispose();
  }
}
