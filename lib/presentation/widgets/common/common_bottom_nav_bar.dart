import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider for the current bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// A common bottom navigation bar widget that can be used throughout the app
class CommonBottomNavBar extends ConsumerWidget {
  /// The current index of the selected tab
  final int currentIndex;

  /// Callback when a tab is tapped
  final Function(int)? onTap;

  /// The number of items in the cart (for badge)
  final int cartItemCount;

  /// Creates a common bottom navigation bar with consistent styling
  const CommonBottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
    this.cartItemCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        // Update the state
        ref.read(bottomNavIndexProvider.notifier).state = index;

        // Call the onTap callback if provided
        if (onTap != null) {
          onTap!(index);
        } else {
          // Default navigation behavior
          _handleNavigation(context, index);
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: theme.primaryColor,
      unselectedItemColor: theme.textTheme.bodyMedium?.color?.withAlpha(153), // Using withAlpha instead of withOpacity
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.category_outlined),
          activeIcon: Icon(Icons.category),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: cartItemCount > 0,
            label: Text(
              cartItemCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
          activeIcon: Badge(
            isLabelVisible: cartItemCount > 0,
            label: Text(
              cartItemCount.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_outlined),
          activeIcon: Icon(Icons.receipt),
          label: 'Orders',
        ),
      ],
    );
  }

  /// Handles navigation based on the selected tab index
  void _handleNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Use replace instead of go to avoid animation for home
        context.replace('/clean-home');
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
        context.replace('/clean/orders');
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
    required int cartItemCount,
  }) {
    return CommonBottomNavBar(
      currentIndex: currentIndex,
      onTap: onTap,
      cartItemCount: cartItemCount,
    );
  }
}
