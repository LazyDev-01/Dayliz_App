import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/cart_item.dart';

/// Production-ready smooth quantity controls widget
///
/// Prevents button shaking/bouncing with:
/// - Fixed width layout (no expansion/contraction)
/// - Debounced updates (300ms)
/// - Smooth animations with proper feedback
/// - Optimized rebuilds and performance
class SmoothQuantityControls extends StatefulWidget {
  final CartItem cartItem;
  final Function(CartItem, int) onQuantityChanged;
  final bool isUpdating;

  // Optional customization
  final EdgeInsets? padding;
  final double? buttonSize;
  final double? fontSize;

  const SmoothQuantityControls({
    super.key,
    required this.cartItem,
    required this.onQuantityChanged,
    this.isUpdating = false,
    this.padding,
    this.buttonSize,
    this.fontSize,
  });

  @override
  State<SmoothQuantityControls> createState() => _SmoothQuantityControlsState();
}

class _SmoothQuantityControlsState extends State<SmoothQuantityControls>
    with TickerProviderStateMixin {

  // Constants for consistent behavior
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static const Duration _animationDuration = Duration(milliseconds: 150);
  static const double _quantityDisplayWidth = 35.0;

  // Animation controllers for button press feedback
  late AnimationController _decreaseController;
  late AnimationController _increaseController;
  late Animation<double> _decreaseScale;
  late Animation<double> _increaseScale;

  // State management
  DateTime _lastTapTime = DateTime.now();
  int _displayQuantity = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _displayQuantity = widget.cartItem.quantity;
    _initializeAnimations();
  }

  /// Initialize animation controllers and animations
  void _initializeAnimations() {
    _decreaseController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );
    _increaseController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    // Create scale animations for button press feedback
    _decreaseScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _decreaseController,
      curve: Curves.easeInOut,
    ));

    _increaseScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _increaseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SmoothQuantityControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update display quantity when the actual cart item changes
    if (widget.cartItem.quantity != oldWidget.cartItem.quantity) {
      setState(() {
        _displayQuantity = widget.cartItem.quantity;
        _isProcessing = false;
      });
    }
    
    // Update processing state
    if (widget.isUpdating != oldWidget.isUpdating) {
      setState(() {
        _isProcessing = widget.isUpdating;
      });
    }
  }

  @override
  void dispose() {
    _decreaseController.dispose();
    _increaseController.dispose();
    super.dispose();
  }

  /// Handles quantity decrease with debouncing and smooth animation
  void _handleDecrease() {
    if (_isDebounced() || _isProcessing) return;
    
    // Immediate visual feedback
    HapticFeedback.lightImpact();
    _decreaseController.forward().then((_) {
      _decreaseController.reverse();
    });
    
    // Update display quantity immediately for smooth UX
    final newQuantity = _displayQuantity - 1;
    if (newQuantity >= 0) {
      setState(() {
        _displayQuantity = newQuantity;
        _isProcessing = true;
      });
      
      // Call the actual update function
      widget.onQuantityChanged(widget.cartItem, newQuantity);
    }
  }

  /// Handles quantity increase with debouncing and smooth animation
  void _handleIncrease() {
    if (_isDebounced() || _isProcessing) return;
    
    // Immediate visual feedback
    HapticFeedback.lightImpact();
    _increaseController.forward().then((_) {
      _increaseController.reverse();
    });
    
    // Update display quantity immediately for smooth UX
    final newQuantity = _displayQuantity + 1;
    setState(() {
      _displayQuantity = newQuantity;
      _isProcessing = true;
    });
    
    // Call the actual update function
    widget.onQuantityChanged(widget.cartItem, newQuantity);
  }

  /// Checks if the action should be debounced
  bool _isDebounced() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime) < _debounceDelay) {
      return true;
    }
    _lastTapTime = now;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Default dimensions - optimized for cart usage
    final buttonSize = widget.buttonSize ?? 26.0;  // 26x26 px buttons
    final fontSize = widget.fontSize ?? 13.0;      // 13px font size
    
    return Semantics(
      label: 'Quantity controls for ${widget.cartItem.product.name}',
      child: Container(
        width: buttonSize * 2 + _quantityDisplayWidth,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.success),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Decrease button
            _buildSmoothButton(
              icon: Icons.remove,
              onTap: _displayQuantity > 0 ? _handleDecrease : null,
              animation: _decreaseScale,
              semanticLabel: 'Decrease quantity',
              buttonSize: buttonSize,
            ),
            
            // Quantity display with smooth transitions
            _buildQuantityDisplay(fontSize),
            
            // Increase button
            _buildSmoothButton(
              icon: Icons.add,
              onTap: _handleIncrease,
              animation: _increaseScale,
              semanticLabel: 'Increase quantity',
              buttonSize: buttonSize,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the quantity display with smooth transitions and fixed width
  Widget _buildQuantityDisplay(double fontSize) {
    return Semantics(
      label: 'Current quantity: $_displayQuantity',
      child: Container(
        width: _quantityDisplayWidth,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: _isProcessing
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                )
              : Text(
                  key: ValueKey('quantity_$_displayQuantity'),
                  _displayQuantity.toString(),
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
        ),
      ),
    );
  }

  /// Builds a smooth animated button
  Widget _buildSmoothButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Animation<double> animation,
    required String semanticLabel,
    required double buttonSize,
  }) {
    final isDisabled = onTap == null;
    
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: !isDisabled,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Transform.scale(
            scale: animation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isDisabled ? null : onTap,
                borderRadius: BorderRadius.circular(4),
                splashColor: AppColors.success.withValues(alpha: 0.2),
                highlightColor: AppColors.success.withValues(alpha: 0.1),
                child: Container(
                  width: buttonSize,
                  height: buttonSize,
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 13,
                    color: isDisabled
                        ? AppColors.success.withValues(alpha: 0.5)
                        : AppColors.success,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
