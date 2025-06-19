import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/cart_providers.dart';

/// Floating cart button that appears when cart has items
/// Provides quick access to cart from product listing screens
class FloatingCartButton extends ConsumerStatefulWidget {
  /// Whether to show the button even when cart is empty (for testing)
  final bool forceShow;
  
  /// Custom position from bottom (default: 20)
  final double? bottomPosition;
  
  /// Custom position from right (default: 16)
  final double? rightPosition;

  const FloatingCartButton({
    Key? key,
    this.forceShow = false,
    this.bottomPosition,
    this.rightPosition,
  }) : super(key: key);

  @override
  ConsumerState<FloatingCartButton> createState() => _FloatingCartButtonState();
}

class _FloatingCartButtonState extends ConsumerState<FloatingCartButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isVisible = false;
  int _previousItemCount = 0;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for show/hide
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Slide animation for entrance
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // Pulse animation for item count changes
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleCartTap() {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Navigate to cart using the correct route
    context.push('/clean/cart');
  }

  void _animateItemCountChange() {
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    final itemCount = cartState.itemCount;
    
    // Determine visibility
    final shouldShow = widget.forceShow || itemCount > 0;
    
    // Handle visibility changes
    if (shouldShow != _isVisible) {
      _isVisible = shouldShow;
      if (_isVisible) {
        _slideController.forward();
        _scaleController.forward();
      } else {
        _scaleController.reverse().then((_) {
          _slideController.reverse();
        });
      }
    }
    
    // Handle item count changes (pulse animation)
    if (itemCount != _previousItemCount && itemCount > 0) {
      _animateItemCountChange();
      _previousItemCount = itemCount;
    }
    
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: widget.bottomPosition ?? 20.h,
      right: widget.rightPosition ?? 16.w,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: _buildCartButton(itemCount),
        ),
      ),
    );
  }

  Widget _buildCartButton(int itemCount) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleCartTap,
                borderRadius: BorderRadius.circular(28.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                          if (itemCount > 0)
                            Positioned(
                              right: -8.w,
                              top: -8.h,
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 20.w,
                                  minHeight: 20.h,
                                ),
                                child: Text(
                                  itemCount > 99 ? '99+' : itemCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
