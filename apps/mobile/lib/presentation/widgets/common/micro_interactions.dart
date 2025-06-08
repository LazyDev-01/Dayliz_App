import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Advanced micro-interactions for premium user experience
class MicroInteractions {
  
  /// Bouncy button with haptic feedback
  static Widget bouncyButton({
    required Widget child,
    required VoidCallback onPressed,
    Duration duration = const Duration(milliseconds: 150),
    double scaleDown = 0.95,
    bool enableHaptic = true,
  }) {
    return _BouncyButton(
      onPressed: onPressed,
      duration: duration,
      scaleDown: scaleDown,
      enableHaptic: enableHaptic,
      child: child,
    );
  }

  /// Animated add to cart button
  static Widget animatedAddToCartButton({
    required VoidCallback onPressed,
    bool isLoading = false,
    bool isAdded = false,
    String text = 'Add to Cart',
    String addedText = 'Added!',
  }) {
    return _AnimatedAddToCartButton(
      onPressed: onPressed,
      isLoading: isLoading,
      isAdded: isAdded,
      text: text,
      addedText: addedText,
    );
  }

  /// Floating action button with hero animation
  static Widget heroFAB({
    required VoidCallback onPressed,
    required IconData icon,
    String? heroTag,
    Color? backgroundColor,
  }) {
    return Hero(
      tag: heroTag ?? 'fab',
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        backgroundColor: backgroundColor,
        child: Icon(icon),
      ),
    );
  }

  /// Ripple effect container
  static Widget rippleContainer({
    required Widget child,
    required VoidCallback onTap,
    BorderRadius? borderRadius,
    Color? splashColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        splashColor: splashColor ?? Colors.grey.withOpacity(0.2),
        child: child,
      ),
    );
  }

  /// Animated counter for cart quantities
  static Widget animatedCounter({
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return _AnimatedCounter(
      count: count,
      onIncrement: onIncrement,
      onDecrement: onDecrement,
      duration: duration,
    );
  }
}

/// Bouncy button implementation
class _BouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;
  final double scaleDown;
  final bool enableHaptic;

  const _BouncyButton({
    required this.child,
    required this.onPressed,
    required this.duration,
    required this.scaleDown,
    required this.enableHaptic,
  });

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
        if (widget.enableHaptic) {
          HapticFeedback.lightImpact();
        }
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Animated add to cart button implementation
class _AnimatedAddToCartButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isAdded;
  final String text;
  final String addedText;

  const _AnimatedAddToCartButton({
    required this.onPressed,
    required this.isLoading,
    required this.isAdded,
    required this.text,
    required this.addedText,
  });

  @override
  State<_AnimatedAddToCartButton> createState() => _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState extends State<_AnimatedAddToCartButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.green[700],
    ).animate(_colorController);
  }

  @override
  void didUpdateWidget(_AnimatedAddToCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAdded && !oldWidget.isAdded) {
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
      _colorController.forward();
    } else if (!widget.isAdded && oldWidget.isAdded) {
      _colorController.reverse();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _colorAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: _colorAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.isAdded ? Icons.check : Icons.add_shopping_cart),
                      const SizedBox(width: 8),
                      Text(widget.isAdded ? widget.addedText : widget.text),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// Animated counter implementation
class _AnimatedCounter extends StatefulWidget {
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final Duration duration;

  const _AnimatedCounter({
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    required this.duration,
  });

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(_AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      _controller.forward().then((_) {
        _controller.reverse();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounterButton(
            icon: Icons.remove,
            onPressed: widget.onDecrement,
          ),
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          _buildCounterButton(
            icon: Icons.add,
            onPressed: widget.onIncrement,
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}
