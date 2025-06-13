import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/coupon.dart';
import '../../providers/coupon_providers.dart';

/// Widget for coupon input and application in cart
class CouponInputWidget extends ConsumerStatefulWidget {
  final double orderValue;
  final Function(Coupon? coupon, double discount)? onCouponApplied;

  const CouponInputWidget({
    super.key,
    required this.orderValue,
    this.onCouponApplied,
  });

  @override
  ConsumerState<CouponInputWidget> createState() => _CouponInputWidgetState();
}

class _CouponInputWidgetState extends ConsumerState<CouponInputWidget> {
  final TextEditingController _couponController = TextEditingController();
  bool _isApplying = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final couponState = ref.watch(couponStateProvider);
    final appliedCoupon = couponState.appliedCoupon;
    final appliedDiscount = couponState.appliedDiscount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and see all button
          Row(
            children: [
              const Text(
                'Gifts & Offers',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/coupons'),
                child: const Text(
                  'See all gifts ▶',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Applied coupon display or coupon input
          if (appliedCoupon != null) ...[
            _buildAppliedCouponCard(appliedCoupon, appliedDiscount),
          ] else ...[
            _buildCouponInput(),
            const SizedBox(height: 12),
            _buildBestCouponSuggestion(),
          ],
        ],
      ),
    );
  }

  Widget _buildAppliedCouponCard(Coupon coupon, double discount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'You saved ₹${discount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _removeCoupon,
            icon: const Icon(
              Icons.close,
              color: AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Remove coupon',
          ),
        ],
      ),
    );
  }

  Widget _buildCouponInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _couponController,
            decoration: InputDecoration(
              hintText: 'Enter coupon code',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _applyCoupon(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isApplying ? null : _applyCoupon,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isApplying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildBestCouponSuggestion() {
    final bestCoupon = ref.read(couponStateProvider.notifier).getBestCouponForOrder(widget.orderValue);
    
    if (bestCoupon == null) {
      return const SizedBox.shrink();
    }

    final potentialDiscount = bestCoupon.calculateDiscount(widget.orderValue);
    
    if (potentialDiscount <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best for you: ${bestCoupon.code}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Save ₹${potentialDiscount.toStringAsFixed(0)} on this order',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _applyCouponDirectly(bestCoupon),
            child: const Text(
              'Apply',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim().toUpperCase();
    
    if (couponCode.isEmpty) {
      _showErrorMessage('Please enter a coupon code');
      return;
    }

    setState(() {
      _isApplying = true;
    });

    try {
      final success = await ref.read(couponStateProvider.notifier).applyCoupon(
        couponCode,
        widget.orderValue,
      );

      if (success) {
        final couponState = ref.read(couponStateProvider);
        widget.onCouponApplied?.call(
          couponState.appliedCoupon,
          couponState.appliedDiscount,
        );
        
        _couponController.clear();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(couponState.appliedCouponSavingsText),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final errorMessage = ref.read(couponStateProvider).errorMessage ?? 'Failed to apply coupon';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      _showErrorMessage('Failed to apply coupon: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  Future<void> _applyCouponDirectly(Coupon coupon) async {
    setState(() {
      _isApplying = true;
    });

    try {
      final success = await ref.read(couponStateProvider.notifier).applyCoupon(
        coupon.code,
        widget.orderValue,
      );

      if (success) {
        final couponState = ref.read(couponStateProvider);
        widget.onCouponApplied?.call(
          couponState.appliedCoupon,
          couponState.appliedDiscount,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(couponState.appliedCouponSavingsText),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        final errorMessage = ref.read(couponStateProvider).errorMessage ?? 'Failed to apply coupon';
        _showErrorMessage(errorMessage);
      }
    } catch (e) {
      _showErrorMessage('Failed to apply coupon: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  void _removeCoupon() {
    ref.read(couponStateProvider.notifier).removeCoupon();
    widget.onCouponApplied?.call(null, 0.0);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon removed'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
