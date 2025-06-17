import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'svg_icon.dart';

/// A modern icon button that uses SVG icons with enhanced interactions
class SvgIconButton extends StatefulWidget {
  final DaylizIcons icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? color;
  final Color? backgroundColor;
  final Color? splashColor;
  final Color? highlightColor;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool enableHapticFeedback;
  final bool enableScaleAnimation;
  final Duration animationDuration;

  const SvgIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.size,
    this.color,
    this.backgroundColor,
    this.splashColor,
    this.highlightColor,
    this.tooltip,
    this.padding,
    this.borderRadius,
    this.enableHapticFeedback = true,
    this.enableScaleAnimation = true,
    this.animationDuration = const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  State<SvgIconButton> createState() => _SvgIconButtonState();
}

class _SvgIconButtonState extends State<SvgIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableScaleAnimation && widget.onPressed != null) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableScaleAnimation) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableScaleAnimation) {
      setState(() => _isPressed = false);
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = widget.size ?? 24.0;
    final effectivePadding = widget.padding ?? const EdgeInsets.all(8.0);
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(8.0);

    Widget iconWidget = SvgIcon(
      widget.icon,
      size: iconSize,
      color: widget.color ?? theme.iconTheme.color,
    );

    if (widget.enableScaleAnimation) {
      iconWidget = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    Widget button = Material(
      color: widget.backgroundColor ?? Colors.transparent,
      borderRadius: effectiveBorderRadius,
      child: InkWell(
        onTap: widget.onPressed != null ? _handleTap : null,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        borderRadius: effectiveBorderRadius,
        splashColor: widget.splashColor ?? theme.splashColor,
        highlightColor: widget.highlightColor ?? theme.highlightColor,
        child: Padding(
          padding: effectivePadding,
          child: iconWidget,
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Predefined SVG icon button styles for common use cases
class SvgIconButtons {
  /// Navigation back button
  static Widget back({
    VoidCallback? onPressed,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) => IconButton(
        onPressed: onPressed ?? () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Color(0xFF374151), // Explicit dark grey color
        ),
        tooltip: tooltip ?? 'Back',
      ),
    );
  }

  /// Search button
  static Widget search({
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    // Temporarily use Material icon to avoid SVG loading issues on web
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(
        Icons.search,
        color: Color(0xFF374151), // Explicit dark grey color
      ),
      tooltip: tooltip ?? 'Search',
    );
  }

  /// Cart button with optional badge
  static Widget cart({
    required VoidCallback onPressed,
    int? badgeCount,
    String? tooltip,
  }) {
    Widget button = SvgIconButton(
      icon: DaylizIcons.cart,
      onPressed: onPressed,
      color: const Color(0xFF374151), // Explicit dark grey color
      tooltip: tooltip ?? 'Shopping Cart',
    );

    if (badgeCount != null && badgeCount > 0) {
      button = Stack(
        children: [
          button,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badgeCount > 99 ? '99+' : badgeCount.toString(),
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
      );
    }

    return button;
  }

  /// Menu/hamburger button
  static Widget menu({
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return SvgIconButton(
      icon: DaylizIcons.menu,
      onPressed: onPressed,
      color: const Color(0xFF374151), // Explicit dark grey color
      tooltip: tooltip ?? 'Menu',
    );
  }

  /// Primary action button with app's primary color
  static Widget primary({
    required DaylizIcons icon,
    required VoidCallback onPressed,
    double? size,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) => SvgIconButton(
        icon: icon,
        onPressed: onPressed,
        size: size,
        color: Theme.of(context).colorScheme.primary,
        tooltip: tooltip,
      ),
    );
  }

  /// Secondary action button with muted colors
  static Widget secondary({
    required DaylizIcons icon,
    required VoidCallback onPressed,
    double? size,
    String? tooltip,
  }) {
    return SvgIconButton(
      icon: icon,
      onPressed: onPressed,
      size: size,
      color: const Color(0xFF374151), // Explicit dark grey color
      tooltip: tooltip,
    );
  }

  /// Filled button with background color
  static Widget filled({
    required DaylizIcons icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double? size,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) => SvgIconButton(
        icon: icon,
        onPressed: onPressed,
        size: size,
        color: iconColor ?? Theme.of(context).colorScheme.onPrimary,
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        tooltip: tooltip,
      ),
    );
  }

  /// Outlined button with border
  static Widget outlined({
    required DaylizIcons icon,
    required VoidCallback onPressed,
    Color? borderColor,
    Color? iconColor,
    double? size,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.outline,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgIconButton(
          icon: icon,
          onPressed: onPressed,
          size: size,
          color: iconColor ?? Theme.of(context).colorScheme.primary,
          tooltip: tooltip,
        ),
      ),
    );
  }

  /// Floating action button style
  static Widget fab({
    required DaylizIcons icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double? size,
    String? tooltip,
  }) {
    return Builder(
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SvgIconButton(
          icon: icon,
          onPressed: onPressed,
          size: size ?? 24,
          color: iconColor ?? Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.all(16),
          tooltip: tooltip,
        ),
      ),
    );
  }
}
