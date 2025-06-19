import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider for the current bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// A common bottom navigation bar widget that can be used throughout the app
class CommonBottomNavBar extends ConsumerStatefulWidget {
  /// The current index of the selected tab
  final int currentIndex;

  /// Callback when a tab is tapped
  final Function(int)? onTap;

  /// Whether to use custom navigation handling (default: false)
  final bool useCustomNavigation;

  /// Creates a common bottom navigation bar with consistent styling
  const CommonBottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
    this.useCustomNavigation = false,
  }) : super(key: key);

  @override
  ConsumerState<CommonBottomNavBar> createState() => _CommonBottomNavBarState();

}

class _CommonBottomNavBarState extends ConsumerState<CommonBottomNavBar> with SingleTickerProviderStateMixin {
  // Animation controller for icon animations
  late AnimationController _animationController;
  int _previousIndex = 0;
  bool _isAnimating = false;

  // Debounce functionality
  DateTime _lastTapTime = DateTime.now();
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150), // Reduced for better performance
    );
    _animationController.value = 1.0; // Start at full scale
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommonBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && !_isAnimating) {
      _previousIndex = oldWidget.currentIndex;
      _triggerAnimation();
    }
  }

  /// Optimized animation trigger to prevent multiple simultaneous animations
  void _triggerAnimation() {
    if (_isAnimating) return;

    _isAnimating = true;
    _animationController.reset();
    _animationController.forward().then((_) {
      if (mounted) {
        _isAnimating = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Animation for scaling effect
    final Animation<double> scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: (index) => _handleTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode
            ? theme.bottomNavigationBarTheme.backgroundColor ?? const Color(0xFF1E1E1E)
            : theme.bottomNavigationBarTheme.backgroundColor ?? Colors.white,
        selectedItemColor: theme.primaryColor,
        unselectedItemColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        items: _buildAnimatedItems(scaleAnimation),
        elevation: 0, // Remove default elevation as we're using custom shadow
        // Accessibility improvements
        selectedFontSize: 12,
        unselectedFontSize: 10,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }

  /// Optimized tap handling with debounce and haptic feedback
  void _handleTap(BuildContext context, int index) {
    final now = DateTime.now();

    // Debounce: Prevent rapid tapping
    if (now.difference(_lastTapTime) < _debounceDuration) {
      return;
    }
    _lastTapTime = now;

    // Prevent tapping during animation
    if (_isAnimating) return;

    // Haptic feedback for better user experience
    HapticFeedback.lightImpact();

    // Only update provider state if not using custom navigation
    if (!widget.useCustomNavigation) {
      ref.read(bottomNavIndexProvider.notifier).state = index;
    }

    // Call custom callback or default navigation
    if (widget.onTap != null) {
      widget.onTap!(index);
    } else {
      _handleNavigation(context, index);
    }
  }

  // Build animated navigation items
  List<BottomNavigationBarItem> _buildAnimatedItems(Animation<double> animation) {
    return [
      _buildAnimatedItem(
        index: 0,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
        semanticLabel: 'Navigate to Home',
        animation: animation,
      ),
      _buildAnimatedItem(
        index: 1,
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Categories',
        semanticLabel: 'Navigate to Categories',
        animation: animation,
      ),
      _buildCartItem(
        index: 2,
        animation: animation,
      ),
      _buildAnimatedItem(
        index: 3,
        icon: Icons.receipt_outlined,
        activeIcon: Icons.receipt,
        label: 'Orders',
        semanticLabel: 'Navigate to Orders',
        animation: animation,
      ),
    ];
  }

  // Build animated navigation item
  BottomNavigationBarItem _buildAnimatedItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String semanticLabel,
    required Animation<double> animation,
  }) {
    final isSelected = widget.currentIndex == index;
    final wasSelected = _previousIndex == index;

    // Only animate the item that is being selected or deselected
    final shouldAnimate = isSelected || wasSelected;

    Widget buildIcon(IconData iconData, bool isActive) {
      final iconWidget = Icon(
        iconData,
        semanticLabel: semanticLabel,
      );

      if (!shouldAnimate) return iconWidget;

      return ScaleTransition(
        scale: isSelected
            ? Tween<double>(begin: 0.8, end: 1.0).animate(animation)
            : Tween<double>(begin: 1.0, end: 0.8).animate(animation),
        child: iconWidget,
      );
    }

    return BottomNavigationBarItem(
      icon: buildIcon(icon, false),
      activeIcon: buildIcon(activeIcon, true),
      label: label,
      tooltip: semanticLabel, // Additional accessibility support
    );
  }

  // Build cart item with badge - optimized to reduce widget duplication
  BottomNavigationBarItem _buildCartItem({
    required int index,
    required Animation<double> animation,
  }) {
    final isSelected = widget.currentIndex == index;
    final wasSelected = _previousIndex == index;
    final shouldAnimate = isSelected || wasSelected;

    // Create simple icon widget without badge
    Widget buildIcon(IconData iconData) {
      final icon = Icon(
        iconData,
        semanticLabel: 'Cart',
      );

      if (!shouldAnimate) return icon;

      return ScaleTransition(
        scale: isSelected
            ? Tween<double>(begin: 0.8, end: 1.0).animate(animation)
            : Tween<double>(begin: 1.0, end: 0.8).animate(animation),
        child: icon,
      );
    }

    return BottomNavigationBarItem(
      icon: buildIcon(Icons.shopping_cart_outlined),
      activeIcon: buildIcon(Icons.shopping_cart),
      label: 'Cart',
      tooltip: 'Cart', // Removed cart count from tooltip
    );
  }

  /// Handles navigation based on the selected tab index - FIXED route paths
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // FIXED: Use correct home route path
        context.replace('/home');
        break;
      case 1:
        // Use replace instead of go to avoid animation for categories
        context.replace('/clean/categories');
        break;
      case 2:
        // Use replace instead of go to avoid animation for cart
        context.replace('/clean/cart');
        break;
      case 3:
        // Use replace instead of go to avoid animation for orders
        context.replace('/orders');
        break;
    }
  }
}

/// Factory methods for creating common bottom navigation bar configurations
class CommonBottomNavBars {
  /// Creates a standard bottom navigation bar
  static CommonBottomNavBar standard({
    required int currentIndex,
    Function(int)? onTap,
    bool useCustomNavigation = false,
  }) {
    return CommonBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      useCustomNavigation: useCustomNavigation,
    );
  }

  /// Creates a bottom navigation bar for main screen usage
  static CommonBottomNavBar forMainScreen({
    required int currentIndex,
  }) {
    return CommonBottomNavBar(
      currentIndex: currentIndex,
      useCustomNavigation: false, // Use default navigation
    );
  }

  /// Creates a bottom navigation bar with custom navigation handling
  static CommonBottomNavBar withCustomNavigation({
    required int currentIndex,
    required Function(int) onTap,
  }) {
    return CommonBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      useCustomNavigation: true,
    );
  }
}