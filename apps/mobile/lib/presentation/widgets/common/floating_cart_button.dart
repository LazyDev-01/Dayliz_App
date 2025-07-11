import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/animation_constants.dart';
import '../../providers/cart_providers.dart';

/// Enhanced floating cart button with premium animations and visual effects
/// Provides quick access to cart from product listing screens with delightful micro-interactions
class FloatingCartButton extends ConsumerStatefulWidget {
  /// Whether to show the button even when cart is empty (for testing)
  final bool forceShow;

  /// Custom position from bottom (default: 20)
  final double? bottomPosition;

  /// Custom position from left (default: center)
  final double? leftPosition;

  /// Custom position from right (default: center)
  final double? rightPosition;

  /// Whether to center the button horizontally (default: true)
  final bool centerHorizontally;

  /// Enable enhanced visual effects (glassmorphism, particles, etc.)
  final bool enableEnhancedEffects;

  /// Enable idle breathing animation
  final bool enableBreathingAnimation;

  /// Custom hero tag for hero animations
  final String? heroTag;

  const FloatingCartButton({
    Key? key,
    this.forceShow = false,
    this.bottomPosition,
    this.leftPosition,
    this.rightPosition,
    this.centerHorizontally = true,
    this.enableEnhancedEffects = true,
    this.enableBreathingAnimation = true,
    this.heroTag,
  }) : super(key: key);

  @override
  ConsumerState<FloatingCartButton> createState() => _FloatingCartButtonState();
}

class _FloatingCartButtonState extends ConsumerState<FloatingCartButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _breathingController;
  late AnimationController _rotationController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  bool _isVisible = false;
  int _previousItemCount = 0;

  @override
  void initState() {
    super.initState();

    // Scale animation for show/hide with spring physics
    _scaleController = AnimationController(
      duration: AnimationConstants.fast,
      vsync: this,
    );

    // Slide animation for entrance with enhanced curve
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pulse animation for item count changes
    _pulseController = AnimationController(
      duration: AnimationConstants.veryFast,
      vsync: this,
    );

    // Breathing animation for idle state
    _breathingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Rotation animation for tap feedback
    _rotationController = AnimationController(
      duration: AnimationConstants.veryFast,
      vsync: this,
    );

    // Glow animation for enhanced effects
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Start breathing animation if enabled
    if (widget.enableBreathingAnimation) {
      _startBreathingAnimation();
    }

    // Start subtle glow animation if enhanced effects are enabled
    if (widget.enableEnhancedEffects) {
      _startGlowAnimation();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _breathingController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startBreathingAnimation() {
    _breathingController.repeat(reverse: true);
  }

  void _startGlowAnimation() {
    _glowController.repeat(reverse: true);
  }

  void _handleCartTap() {
    // Enhanced haptic feedback pattern
    HapticFeedback.lightImpact();

    // Add rotation animation on tap
    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });

    // Navigate to cart using the correct route
    context.push('/clean/cart');
  }

  void _animateItemCountChange() {
    // Enhanced pulse animation with haptic feedback
    HapticFeedback.selectionClick();
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
      left: widget.centerHorizontally ? 0 : widget.leftPosition,
      right: widget.centerHorizontally ? 0 : widget.rightPosition ?? 16.w,
      child: widget.centerHorizontally
        ? Center(
            child: Hero(
              tag: widget.heroTag ?? 'floating_cart_button',
              child: RepaintBoundary(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _buildEnhancedCartButton(itemCount),
                  ),
                ),
              ),
            ),
          )
        : Hero(
            tag: widget.heroTag ?? 'floating_cart_button',
            child: RepaintBoundary(
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildEnhancedCartButton(itemCount),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildEnhancedCartButton(int itemCount) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseAnimation,
        _breathingAnimation,
        _rotationAnimation,
        _glowAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value *
                 (widget.enableBreathingAnimation ? _breathingAnimation.value : 1.0),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: _buildEnhancedGradient(),
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: _buildEnhancedShadows(),
                border: widget.enableEnhancedEffects
                  ? Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    )
                  : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleCartTap,
                  borderRadius: BorderRadius.circular(30.r),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18.w,
                      vertical: 14.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEnhancedCartIcon(itemCount),
                        SizedBox(width: 8.w),
                        Text(
                          'Cart',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build enhanced gradient with modern color scheme
  LinearGradient _buildEnhancedGradient() {
    if (widget.enableEnhancedEffects) {
      return const LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.primaryDark,
          AppColors.forestGreen,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.6, 1.0],
      );
    }
    return const LinearGradient(
      colors: [AppColors.primary, AppColors.primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Build enhanced shadow effects
  List<BoxShadow> _buildEnhancedShadows() {
    final baseShadows = [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.3),
        blurRadius: 12.r,
        offset: Offset(0, 4.h),
      ),
    ];

    if (widget.enableEnhancedEffects) {
      baseShadows.addAll([
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.1 * _glowAnimation.value),
          blurRadius: 20.r,
          offset: Offset(0, 2.h),
          spreadRadius: 2.r,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
      ]);
    }

    return baseShadows;
  }

  /// Build enhanced cart icon with improved badge
  Widget _buildEnhancedCartIcon(int itemCount) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.shopping_cart_rounded,
          color: Colors.white,
          size: 26.sp,
        ),
        if (itemCount > 0)
          Positioned(
            right: -10.w,
            top: -10.h,
            child: _buildEnhancedBadge(itemCount),
          ),
      ],
    );
  }

  /// Build enhanced badge with better design
  Widget _buildEnhancedBadge(int itemCount) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: itemCount > 9 ? 6.w : 5.w,
              vertical: 3.h,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accentDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 6.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            constraints: BoxConstraints(
              minWidth: 22.w,
              minHeight: 22.h,
            ),
            child: Text(
              itemCount > 99 ? '99+' : itemCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
