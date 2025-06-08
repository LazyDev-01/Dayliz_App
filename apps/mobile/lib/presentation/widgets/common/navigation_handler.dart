import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'common_bottom_nav_bar.dart';

/// Centralized navigation handler for bottom navigation
/// Eliminates code duplication across screens and provides consistent navigation behavior
class NavigationHandler {
  /// Handle bottom navigation tap with proper route navigation
  ///
  /// This method provides consistent navigation behavior across all screens
  /// and eliminates the need for duplicate navigation code in each screen.
  static void handleBottomNavTap(
    BuildContext context,
    WidgetRef ref,
    int index, {
    int? currentScreenIndex,
  }) {
    // Prevent navigation to the same screen
    if (currentScreenIndex != null && currentScreenIndex == index) {
      return;
    }

    // Update the provider state for consistency
    ref.read(bottomNavIndexProvider.notifier).state = index;

    // Navigate to the appropriate route using context.go() for reliability
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/clean/categories');
        break;
      case 2:
        context.go('/clean/cart');
        break;
      case 3:
        context.go('/orders');
        break;
      default:
        // Fallback to home for unknown indices
        context.go('/home');
        break;
    }
  }

  /// Create a standardized bottom navigation bar for individual screens
  ///
  /// This factory method ensures consistent bottom navigation implementation
  /// across all screens while maintaining the app's design theme.
  static Widget createBottomNavBar({
    required BuildContext context,
    required WidgetRef ref,
    required int currentIndex,
  }) {
    return CommonBottomNavBars.standard(
      currentIndex: currentIndex,
      onTap: (index) => handleBottomNavTap(
        context,
        ref,
        index,
        currentScreenIndex: currentIndex,
      ),
      useCustomNavigation: true,
    );
  }
}

/// Extension on BuildContext for convenient navigation access
extension NavigationExtension on BuildContext {
  /// Navigate to home screen (main navigation structure)
  void goToHome() => go('/home');

  /// Navigate to categories screen
  void goToCategories() => go('/clean/categories');

  /// Navigate to cart screen
  void goToCart() => go('/clean/cart');

  /// Navigate to orders screen
  void goToOrders() => go('/clean/orders');

  /// Navigate to main home screen and set home tab active
  /// This is specifically for "Continue Shopping" scenarios from empty cart
  void goToMainHome() {
    // Use pushReplacement to replace current route with home
    // This ensures no back button and clean navigation to main screen
    pushReplacement('/home');
  }

  /// Navigate to main home screen with proper provider update
  /// This version ensures the bottom nav index is set correctly
  void goToMainHomeWithProvider(WidgetRef ref) {
    // First update the bottom nav index to home (0)
    ref.read(bottomNavIndexProvider.notifier).state = 0;
    // Then navigate to home
    pushReplacement('/home');
  }
}

/// Mixin for screens that need bottom navigation
/// Provides consistent navigation behavior and reduces boilerplate code
mixin BottomNavigationMixin {
  /// Get the current screen index for bottom navigation
  int get currentScreenIndex;

  /// Handle bottom navigation tap
  void handleBottomNavTap(BuildContext context, WidgetRef ref, int index) {
    NavigationHandler.handleBottomNavTap(
      context,
      ref,
      index,
      currentScreenIndex: currentScreenIndex,
    );
  }

  /// Create bottom navigation bar for this screen
  Widget createBottomNavBar(
    BuildContext context,
    WidgetRef ref,
  ) {
    return NavigationHandler.createBottomNavBar(
      context: context,
      ref: ref,
      currentIndex: currentScreenIndex,
    );
  }
}
