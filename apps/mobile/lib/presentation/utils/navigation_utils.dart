import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common/common_bottom_nav_bar.dart';

/// Utility class for handling navigation with proper state synchronization
class NavigationUtils {
  /// Handle back navigation with efficient bottom nav state sync
  static void handleBackNavigation(BuildContext context, WidgetRef ref) {
    debugPrint('🔙 NavigationUtils: Handling back navigation');

    if (Navigator.of(context).canPop()) {
      debugPrint('🔙 NavigationUtils: Popping to previous screen');
      
      // Pop first, then sync state efficiently
      Navigator.of(context).pop();
      
      // Use a more efficient approach to sync state
      _syncBottomNavStateEfficiently(context, ref);
    } else {
      debugPrint('🔙 NavigationUtils: Cannot pop - fallback to home');
      // Fallback to home if no previous screen
      context.go('/home?tab=0');
    }
  }

  /// Efficiently sync bottom navigation state without unnecessary operations
  static void _syncBottomNavStateEfficiently(BuildContext context, WidgetRef ref) {
    // Use a single frame callback to avoid accumulation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return; // Safety check

      try {
        final router = GoRouter.of(context);
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;

        debugPrint('🔄 NavigationUtils: Current location after pop: $currentLocation');

        // Only update if we're on the main screen to avoid unnecessary updates
        if (currentLocation.startsWith('/home')) {
          final uri = router.routerDelegate.currentConfiguration.uri;
          final tabParam = uri.queryParameters['tab'];
          final targetTabIndex = int.tryParse(tabParam ?? '0') ?? 0;

          // Only update if the tab index is different to avoid unnecessary rebuilds
          final currentTabIndex = ref.read(bottomNavIndexProvider);
          if (currentTabIndex != targetTabIndex) {
            ref.read(bottomNavIndexProvider.notifier).state = targetTabIndex;
            debugPrint('🔄 NavigationUtils: Updated bottom nav from $currentTabIndex to $targetTabIndex');
          } else {
            debugPrint('🔄 NavigationUtils: Bottom nav already at correct index: $targetTabIndex');
          }
        } else {
          // ROBUST FIX: If we're not on main screen, don't update bottom nav
          // This prevents wrong tab selection when returning to non-main screens
          debugPrint('🔄 NavigationUtils: Not on main screen, preserving bottom nav state');
        }
      } catch (e) {
        debugPrint('🔄 NavigationUtils: Error syncing state: $e');
        // Graceful fallback - don't crash the app
      }
    });
  }

  /// Check if a route represents the main screen with bottom navigation
  static bool isMainScreenRoute(String route) {
    return route.startsWith('/home');
  }

  /// Extract tab index from main screen route
  static int getTabIndexFromRoute(String route) {
    try {
      final uri = Uri.parse(route);
      final tabParam = uri.queryParameters['tab'];
      return int.tryParse(tabParam ?? '0') ?? 0;
    } catch (e) {
      debugPrint('NavigationUtils: Error parsing tab index from route: $e');
      return 0; // Default to home tab
    }
  }
}
