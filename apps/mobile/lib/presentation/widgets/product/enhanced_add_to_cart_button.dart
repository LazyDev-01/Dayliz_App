import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

/// Enhanced add to cart button with haptic feedback and bounce animation
/// Optimized for product cards with smooth micro-interactions
class EnhancedAddToCartButton extends StatefulWidget {
  /// Callback when button is pressed
  final VoidCallback onPressed;
  
  /// Whether the button is in loading state
  final bool isLoading;
  
  /// Whether the product is already in cart
  final bool isInCart;
  
  /// Current quantity in cart (if any)
  final int quantity;
  
  /// Button text when not in cart
  final String addText;
  
  /// Button text when in cart
  final String inCartText;
  
  /// Whether to show quantity controls when in cart
  final bool showQuantityControls;
  
  /// Callback for quantity increase
  final VoidCallback? onIncrease;
  
  /// Callback for quantity decrease
  final VoidCallback? onDecrease;
  
  /// Custom button size
  final Size? buttonSize;
  
  /// Whether to use compact mode (smaller button)
  final bool isCompact;

  const EnhancedAddToCartButton({
    Key? key,
    required this.onPressed,
    this.isLoading = false,
    this.isInCart = false,
    this.quantity = 0,
    this.addText = 'ADD',
    this.inCartText = 'ADDED',
    this.showQuantityControls = true,
    this.onIncrease,
    this.onDecrease,
    this.buttonSize,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<EnhancedAddToCartButton> createState() => _EnhancedAddToCartButtonState();
}

class _EnhancedAddToCartButtonState extends State<EnhancedAddToCartButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _scaleController;
  late AnimationController _colorController;
  
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // Bounce animation for tap feedback
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    // Scale animation for press effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    // Color animation for state changes
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: AppColors.primary,
      end: AppColors.success,
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));
    
    // Set initial color state
    if (widget.isInCart) {
      _colorController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EnhancedAddToCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate color change when cart state changes
    if (oldWidget.isInCart != widget.isInCart) {
      if (widget.isInCart) {
        _colorController.forward();
        _triggerBounce();
      } else {
        _colorController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _triggerBounce() {
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _handleTap() {
    // Additional haptic feedback for successful tap
    HapticFeedback.selectionClick();
    
    // Trigger bounce animation
    _triggerBounce();
    
    // Call the callback
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInCart && widget.showQuantityControls && widget.quantity > 0) {
      return _buildQuantityControls();
    }
    
    return _buildAddButton();
  }

  Widget _buildAddButton() {
    final buttonHeight = widget.buttonSize?.height ?? (widget.isCompact ? 32.h : 36.h);
    final buttonWidth = widget.buttonSize?.width ?? (widget.isCompact ? 60.w : 70.w);
    
    return AnimatedBuilder(
      animation: Listenable.merge([_bounceAnimation, _scaleAnimation, _colorAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value * _scaleAnimation.value,
          child: Container(
            width: buttonWidth,
            height: buttonHeight,
            decoration: BoxDecoration(
              color: _colorAnimation.value ?? AppColors.primary,
              borderRadius: BorderRadius.circular(6.r),
              boxShadow: _isPressed ? [] : [
                BoxShadow(
                  color: (_colorAnimation.value ?? AppColors.primary).withValues(alpha: 0.3),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : _handleTap,
                onTapDown: widget.isLoading ? null : _handleTapDown,
                onTapUp: widget.isLoading ? null : _handleTapUp,
                onTapCancel: widget.isLoading ? null : _handleTapCancel,
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  alignment: Alignment.center,
                  child: widget.isLoading
                      ? SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isInCart ? widget.inCartText : widget.addText,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.isCompact ? 10.sp : 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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

  Widget _buildQuantityControls() {
    return Container(
      width: widget.buttonSize?.width, // Use custom width if provided
      height: widget.buttonSize?.height ?? (widget.isCompact ? 32.h : 36.h),
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(6.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.3),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: widget.onDecrease,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w), // Increased padding for wider button
            child: Text(
              widget.quantity.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.isCompact ? 12.sp : 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: widget.onIncrease,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            HapticFeedback.lightImpact();
            onTap();
          }
        },
        borderRadius: BorderRadius.circular(4.r),
        child: Container(
          width: widget.isCompact ? 28.w : 32.w,
          height: widget.buttonSize?.height ?? (widget.isCompact ? 32.h : 36.h),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: widget.isCompact ? 16.sp : 18.sp,
          ),
        ),
      ),
    );
  }
}
