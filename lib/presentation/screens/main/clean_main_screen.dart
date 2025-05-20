import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/clean_home_screen.dart';
import '../categories/clean_categories_screen.dart';
import '../cart/clean_cart_screen.dart';
import '../orders/clean_order_list_screen.dart';
import '../../widgets/common/common_bottom_nav_bar.dart';
import '../../widgets/common/common_drawer.dart';
import '../../providers/cart_providers.dart';

/// A clean architecture implementation of the main screen with bottom navigation
class CleanMainScreen extends ConsumerWidget {
  /// The initial tab index to display
  final int initialIndex;

  const CleanMainScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current bottom nav index
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // Watch cart item count for badge
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      drawer: const CommonDrawer(),
      body: _buildScreenForIndex(currentIndex),
      bottomNavigationBar: CommonBottomNavBar(
        currentIndex: currentIndex,
        cartItemCount: cartItemCount,
      ),
    );
  }

  Widget _buildScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const CleanHomeScreen();
      case 1:
        return const CleanCategoriesScreen();
      case 2:
        return const CleanCartScreen();
      case 3:
        return const CleanOrderListScreen();
      default:
        return const CleanHomeScreen();
    }
  }
}
