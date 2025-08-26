import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'svg_icon.dart';

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

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!, // Thin light grey line
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: widget.currentIndex,
        onTap: (index) => _handleTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode
            ? theme.bottomNavigationBarTheme.backgroundColor ?? const Color(0xFF1E1E1E)
            : theme.bottomNavigationBarTheme.backgroundColor ?? Colors.white,
        selectedItemColor: const Color(0xFF1C1C1C), // Updated to darker color
        unselectedItemColor: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        items: [
          BottomNavigationBarItem(
            icon: SvgIcon(
              DaylizIcons.homeOutline,
              size: 24,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            activeIcon: const SvgIcon(DaylizIcons.homeFilled, size: 24),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: SvgIcon(
              DaylizIcons.categoriesOutline,
              size: 24,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
            activeIcon: const SvgIcon(DaylizIcons.categoriesFilled, size: 24),
            label: 'Categories',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
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
      ),
    );
  }

  /// Simple tap handling
  void _handleTap(BuildContext context, int index) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Only update provider state for Home and Categories (indexes 0 and 1)
    // Cart and Orders use push navigation and shouldn't update the main screen index
    if (!widget.useCustomNavigation && (index == 0 || index == 1)) {
      ref.read(bottomNavIndexProvider.notifier).state = index;
    }

    // Call custom callback or default navigation
    if (widget.onTap != null) {
      widget.onTap!(index);
    } else {
      _handleNavigation(context, index);
    }
  }





  /// Handles navigation based on the selected tab index - Simple approach
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0: // Home
      case 1: // Categories
        // Use unified navigation for Home & Categories
        context.go('/home?tab=$index');
        break;

      case 2: // Cart
        // Use push navigation - natural back stack
        context.push('/clean/cart');
        break;

      case 3: // Orders
        // Use push navigation - natural back stack
        context.push('/clean/orders');
        break;

      default:
        // Fallback to home
        context.go('/home?tab=0');
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