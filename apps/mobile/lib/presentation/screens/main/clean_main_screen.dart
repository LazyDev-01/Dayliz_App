import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/clean_home_screen.dart';
import '../categories/clean_categories_screen.dart';
import '../cart/modern_cart_screen.dart';
import '../orders/clean_order_list_screen.dart';
import '../../widgets/common/common_bottom_nav_bar.dart';
import '../../widgets/common/common_drawer.dart';

/// A clean architecture implementation of the main screen with bottom navigation
class CleanMainScreen extends ConsumerStatefulWidget {
  /// The initial tab index to display
  final int initialIndex;

  const CleanMainScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<CleanMainScreen> createState() => _CleanMainScreenState();
}

class _CleanMainScreenState extends ConsumerState<CleanMainScreen> {
  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      drawer: const CommonDrawer(),
      body: _buildScreenForIndex(currentIndex),
      bottomNavigationBar: CommonBottomNavBars.forMainScreen(
        currentIndex: currentIndex,
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
        return const ModernCartScreen(); // Phase 3: Updated to use Modern Cart Screen
      case 3:
        return const CleanOrderListScreen();
      default:
        return const CleanHomeScreen();
    }
  }
}
