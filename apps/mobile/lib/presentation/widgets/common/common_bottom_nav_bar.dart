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

class _CommonBottomNavBarState extends ConsumerState<CommonBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) => _handleTap(context, index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDarkMode
          ? theme.bottomNavigationBarTheme.backgroundColor ?? const Color(0xFF1E1E1E)
          : theme.bottomNavigationBarTheme.backgroundColor ?? Colors.white,
      selectedItemColor: const Color(0xFF424242), // Dark grey instead of green
      unselectedItemColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          activeIcon: Icon(Icons.grid_view),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart_outlined),
          activeIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
      ],
      elevation: 8.0, // Add shadow/box effect
      selectedFontSize: 12, // Same size as unselected to remove animation
      unselectedFontSize: 12, // Same size as selected to remove animation
      showSelectedLabels: true,
      showUnselectedLabels: true,
    );
  }

  /// Simple tap handling
  void _handleTap(BuildContext context, int index) {
    // Haptic feedback
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





  /// Handles navigation based on the selected tab index - FIXED route paths
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // FIXED: Use context.go() to avoid recreating home screen widget
        context.go('/home');
        break;
      case 1:
        // Use go instead of replace to maintain consistent navigation
        context.go('/clean/categories');
        break;
      case 2:
        // Use go instead of replace to maintain consistent navigation
        context.go('/clean/cart');
        break;
      case 3:
        // Use go instead of replace to maintain consistent navigation
        context.go('/orders');
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