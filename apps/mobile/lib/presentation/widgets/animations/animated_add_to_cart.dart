import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lottie_animation_widget.dart';
import '../../../core/constants/animation_constants.dart';

/// An animated add-to-cart button that provides visual feedback
/// when products are added to the cart
class AnimatedAddToCartButton extends StatefulWidget {
  /// Callback when the add to cart button is pressed
  final VoidCallback onAddToCart;
  
  /// Whether the button is currently loading
  final bool isLoading;
  
  /// Whether the button is disabled
  final bool isDisabled;
  
  /// Custom button text (default: "Add to Cart")
  final String? buttonText;
  
  /// Button size
  final Size? size;
  
  /// Button colors
  final Color? backgroundColor;
  final Color? textColor;
  
  /// Whether to show the Lottie animation on tap
  final bool showAnimation;
  
  /// Duration to show the animation overlay
  final Duration animationDuration;

  const AnimatedAddToCartButton({
    Key? key,
    required this.onAddToCart,
    this.isLoading = false,
    this.isDisabled = false,
    this.buttonText,
    this.size,
    this.backgroundColor,
    this.textColor,
    this.showAnimation = true,
    this.animationDuration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<AnimatedAddToCartButton> createState() => _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState extends State<AnimatedAddToCartButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _overlayController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _overlayAnimation;
  
  bool _showAnimationOverlay = false;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for button press feedback
    _scaleController = AnimationController(
      duration: AnimationConstants.veryFast,
      vsync: this,
    );
    
    // Overlay animation for Lottie animation
    _overlayController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: AnimationConstants.emphasizedCurve,
    ));
    
    _overlayAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayController,
      curve: AnimationConstants.standardCurve,
    ));
    
    _overlayController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showAnimationOverlay = false;
        });
        _overlayController.reset();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isDisabled || widget.isLoading) return;
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Scale animation
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    // Show Lottie animation overlay
    if (widget.showAnimation) {
      setState(() {
        _showAnimationOverlay = true;
      });
      _overlayController.forward();
    }
    
    // Call the callback
    widget.onAddToCart();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = widget.size ?? const Size(120, 40);
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main button
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: widget.isDisabled 
                    ? Colors.grey.shade300
                    : widget.backgroundColor ?? theme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: widget.isDisabled ? null : [
                    BoxShadow(
                      color: (widget.backgroundColor ?? theme.primaryColor).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Center(
                      child: widget.isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.textColor ?? Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            widget.buttonText ?? 'Add to Cart',
                            style: TextStyle(
                              color: widget.textColor ?? Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        // Lottie animation overlay
        if (_showAnimationOverlay)
          AnimatedBuilder(
            animation: _overlayAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _overlayAnimation.value,
                child: Transform.scale(
                  scale: _overlayAnimation.value,
                  child: DaylizLottieAnimations.addToCart(
                    size: size.height * 1.5,
                    onCompleted: () {
                      // Animation completed, overlay will be hidden automatically
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A floating add-to-cart button with animation
class FloatingAddToCartButton extends StatefulWidget {
  /// Callback when the button is pressed
  final VoidCallback onPressed;
  
  /// Whether the button is visible
  final bool isVisible;
  
  /// Cart item count to display
  final int itemCount;
  
  /// Whether the button is loading
  final bool isLoading;

  const FloatingAddToCartButton({
    Key? key,
    required this.onPressed,
    this.isVisible = true,
    this.itemCount = 0,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<FloatingAddToCartButton> createState() => _FloatingAddToCartButtonState();
}

class _FloatingAddToCartButtonState extends State<FloatingAddToCartButton>
    with TickerProviderStateMixin {
  late AnimationController _visibilityController;
  late AnimationController _bounceController;
  late Animation<double> _slideAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _visibilityController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: AnimationConstants.fast,
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _visibilityController,
      curve: AnimationConstants.emphasizedCurve,
    ));
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: AnimationConstants.bounceCurve,
    ));
    
    if (widget.isVisible) {
      _visibilityController.forward();
    }
  }

  @override
  void didUpdateWidget(FloatingAddToCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _visibilityController.forward();
      } else {
        _visibilityController.reverse();
      }
    }
    
    if (widget.itemCount != oldWidget.itemCount && widget.itemCount > oldWidget.itemCount) {
      _bounceController.forward().then((_) {
        _bounceController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _visibilityController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 100 * _slideAnimation.value),
          child: AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bounceAnimation.value,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: FloatingActionButton.extended(
                    onPressed: widget.isLoading ? null : widget.onPressed,
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    icon: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Stack(
                          children: [
                            const Icon(Icons.shopping_cart),
                            if (widget.itemCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${widget.itemCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                    label: Text(
                      widget.itemCount > 0 
                        ? 'View Cart (${widget.itemCount})'
                        : 'View Cart',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
