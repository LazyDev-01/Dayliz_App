import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/constants/animation_constants.dart';

/// A reusable Lottie animation widget with built-in performance optimizations
/// and consistent behavior across the app
class LottieAnimationWidget extends StatefulWidget {
  /// Path to the Lottie animation file
  final String animationPath;
  
  /// Width of the animation
  final double? width;
  
  /// Height of the animation
  final double? height;
  
  /// Whether the animation should repeat
  final bool repeat;
  
  /// Whether the animation should reverse after completion
  final bool reverse;
  
  /// Whether the animation should auto-start
  final bool autoStart;
  
  /// Animation speed multiplier (1.0 = normal speed)
  final double speed;
  
  /// Callback when animation completes
  final VoidCallback? onCompleted;
  
  /// Callback when animation starts
  final VoidCallback? onStarted;
  
  /// Custom animation controller for external control
  final AnimationController? controller;
  
  /// Fit behavior for the animation
  final BoxFit fit;
  
  /// Alignment of the animation within its bounds
  final Alignment alignment;
  
  /// Whether to show a fallback widget if animation fails to load
  final Widget? fallback;
  
  /// Whether to preload the animation for better performance
  final bool preload;

  const LottieAnimationWidget({
    Key? key,
    required this.animationPath,
    this.width,
    this.height,
    this.repeat = false,
    this.reverse = false,
    this.autoStart = true,
    this.speed = 1.0,
    this.onCompleted,
    this.onStarted,
    this.controller,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallback,
    this.preload = false,
  }) : super(key: key);

  @override
  State<LottieAnimationWidget> createState() => _LottieAnimationWidgetState();
}

class _LottieAnimationWidgetState extends State<LottieAnimationWidget>
    with TickerProviderStateMixin {
  AnimationController? _internalController;
  AnimationController get _controller => widget.controller ?? _internalController!;
  
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    
    // Create internal controller if none provided
    if (widget.controller == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: AnimationConstants.medium,
      );
    }
    
    // Set up animation listeners
    _controller.addStatusListener(_onAnimationStatusChanged);
    
    // Auto-start if enabled
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimation();
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    _internalController?.dispose();
    super.dispose();
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.forward:
        widget.onStarted?.call();
        break;
      case AnimationStatus.completed:
        widget.onCompleted?.call();
        if (widget.repeat) {
          if (widget.reverse) {
            _controller.reverse();
          } else {
            _controller.reset();
            _controller.forward();
          }
        }
        break;
      case AnimationStatus.dismissed:
        if (widget.repeat && widget.reverse) {
          _controller.forward();
        }
        break;
      case AnimationStatus.reverse:
        break;
    }
  }

  void _startAnimation() {
    if (!_hasError && mounted) {
      _controller.forward();
    }
  }

  void _onAnimationError() {
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show fallback if there's an error
    if (_hasError && widget.fallback != null) {
      return widget.fallback!;
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Lottie.asset(
        widget.animationPath,
        controller: _controller,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        repeat: widget.repeat && !widget.reverse,
        reverse: widget.reverse,
        animate: widget.autoStart,
        onLoaded: (composition) {
          // Update controller duration based on animation
          if (widget.controller == null) {
            _internalController?.duration = composition.duration;
          }
          
          // Apply speed multiplier
          _controller.duration = Duration(
            milliseconds: (composition.duration.inMilliseconds / widget.speed).round(),
          );
          
          if (widget.autoStart) {
            _startAnimation();
          }
        },
        errorBuilder: (context, error, stackTrace) {
          _onAnimationError();
          return widget.fallback ?? 
            Icon(
              Icons.animation,
              size: widget.width ?? widget.height ?? AnimationConstants.mediumSize,
              color: Colors.grey,
            );
        },
      ),
    );
  }
}

/// Predefined Lottie animations for common use cases
class DaylizLottieAnimations {
  /// Loading animation for splash screen
  static Widget splashLogo({
    double? size,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      animationPath: AnimationConstants.splashLogo,
      width: size,
      height: size,
      autoStart: true,
      repeat: false,
      onCompleted: onCompleted,
      fallback: const Icon(Icons.shopping_bag, size: 100),
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    double? size,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      animationPath: AnimationConstants.successCheckmark,
      width: size ?? AnimationConstants.largeSize,
      height: size ?? AnimationConstants.largeSize,
      autoStart: true,
      repeat: false,
      speed: 1.2,
      onCompleted: onCompleted,
      fallback: const Icon(Icons.check_circle, color: Colors.green, size: 96),
    );
  }

  /// Add to cart animation
  static Widget addToCart({
    double? size,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      animationPath: AnimationConstants.addToCart,
      width: size ?? AnimationConstants.mediumSize,
      height: size ?? AnimationConstants.mediumSize,
      autoStart: true,
      repeat: false,
      speed: 1.5,
      onCompleted: onCompleted,
      fallback: const Icon(Icons.add_shopping_cart, size: 48),
    );
  }

  /// Heart like animation
  static Widget heartLike({
    double? size,
    bool isLiked = false,
    VoidCallback? onCompleted,
  }) {
    return LottieAnimationWidget(
      animationPath: AnimationConstants.heartLike,
      width: size ?? AnimationConstants.smallSize,
      height: size ?? AnimationConstants.smallSize,
      autoStart: isLiked,
      repeat: false,
      onCompleted: onCompleted,
      fallback: Icon(
        isLiked ? Icons.favorite : Icons.favorite_border,
        color: isLiked ? Colors.red : Colors.grey,
        size: size ?? AnimationConstants.smallSize,
      ),
    );
  }

  /// Empty cart animation
  static Widget emptyCart({
    double? size,
  }) {
    return LottieAnimationWidget(
      animationPath: AnimationConstants.emptyCart,
      width: size ?? AnimationConstants.extraLargeSize,
      height: size ?? AnimationConstants.extraLargeSize,
      autoStart: true,
      repeat: true,
      speed: 0.8,
      fallback: const Icon(Icons.shopping_cart_outlined, size: 150, color: Colors.grey),
    );
  }

  /// Loading animation
  static Widget loading({
    double? size,
  }) {
    return LottieAnimationWidget(
      animationPath: AnimationConstants.searchLoading,
      width: size ?? AnimationConstants.mediumSize,
      height: size ?? AnimationConstants.mediumSize,
      autoStart: true,
      repeat: true,
      fallback: const CircularProgressIndicator(),
    );
  }
}
