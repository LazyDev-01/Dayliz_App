import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/coupon.dart';
import '../../providers/coupon_providers.dart';
import '../../widgets/common/unified_app_bar.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/coupons/coupon_card.dart';

/// Coupons screen showing available and user coupons
class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couponState = ref.watch(couponStateProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: UnifiedAppBars.withBackButton(
        title: 'Gifts & Offers',
        fallbackRoute: '/home',
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildTabBar(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshCoupons(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailableCouponsTab(couponState),
            _buildMyCouponsTab(couponState),
            _buildTrendingCouponsTab(couponState),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Available'),
          Tab(text: 'My Gifts'),
          Tab(text: 'Trending'),
        ],
      ),
    );
  }

  Widget _buildAvailableCouponsTab(CouponState state) {
    if (state.isLoading && state.availableCoupons.isEmpty) {
      return const Center(child: LoadingIndicator(message: 'Loading gifts...'));
    }

    if (state.errorMessage != null && state.availableCoupons.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => ref.read(couponStateProvider.notifier).loadAvailableCoupons(refresh: true),
      );
    }

    if (state.availableCoupons.isEmpty) {
      return const EmptyState(
        icon: Icons.card_giftcard,
        title: 'No gifts available',
        message: 'Check back later for new offers and discounts.',
      );
    }

    return _buildCouponsList(state.availableCoupons, isAvailable: true);
  }

  Widget _buildMyCouponsTab(CouponState state) {
    if (state.userCoupons.isEmpty) {
      return const EmptyState(
        icon: Icons.card_giftcard,
        title: 'No gifts collected',
        message: 'Collect gifts from the Available tab to see them here.',
      );
    }

    return _buildCouponsList(state.userCoupons, isAvailable: false);
  }

  Widget _buildTrendingCouponsTab(CouponState state) {
    if (state.trendingCoupons.isEmpty) {
      return const EmptyState(
        icon: Icons.trending_up,
        title: 'No trending gifts',
        message: 'Popular gifts will appear here.',
      );
    }

    return _buildCouponsList(state.trendingCoupons, isAvailable: true);
  }

  Widget _buildCouponsList(List<Coupon> coupons, {required bool isAvailable}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CouponCard(
            coupon: coupon,
            isAvailable: isAvailable,
            onTap: () => _handleCouponTap(coupon, isAvailable),
            onCollect: isAvailable ? () => _collectCoupon(coupon) : null,
            onApply: !isAvailable ? () => _applyCoupon(coupon) : null,
          ),
        );
      },
    );
  }

  Future<void> _refreshCoupons() async {
    await Future.wait([
      ref.read(couponStateProvider.notifier).loadAvailableCoupons(refresh: true),
      ref.read(couponStateProvider.notifier).loadUserCoupons(refresh: true),
      ref.read(couponStateProvider.notifier).loadTrendingCoupons(),
    ]);
  }

  void _handleCouponTap(Coupon coupon, bool isAvailable) {
    // Navigate to coupon details screen
    context.push('/coupons/${coupon.id}', extra: {
      'coupon': coupon,
      'isAvailable': isAvailable,
    });
  }

  Future<void> _collectCoupon(Coupon coupon) async {
    final success = await ref.read(couponStateProvider.notifier).collectCoupon(coupon.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gift ${coupon.code} collected successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        final errorMessage = ref.read(couponStateProvider).errorMessage ?? 'Failed to collect gift';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _applyCoupon(Coupon coupon) async {
    // For now, just show a message. In a real app, this would apply to cart
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Apply ${coupon.code} in your cart to use this gift'),
        backgroundColor: AppColors.info,
        action: SnackBarAction(
          label: 'Go to Cart',
          textColor: Colors.white,
          onPressed: () => context.go('/cart'),
        ),
      ),
    );
  }
}
