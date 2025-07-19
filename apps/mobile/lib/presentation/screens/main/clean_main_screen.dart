import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/clean_home_screen.dart';
import '../categories/clean_categories_screen.dart';
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
  void initState() {
    super.initState();
    // Set the initial tab index when the screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return PopScope(
      canPop: false, // Handle back button manually
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton(context, ref, currentIndex);
        }
      },
      child: Scaffold(
        drawer: const CommonDrawer(),
        body: _buildScreenForIndex(currentIndex),
        bottomNavigationBar: CommonBottomNavBars.forMainScreen(
          currentIndex: currentIndex,
        ),
      ),
    );
  }

  /// Handle device back button
  void _handleBackButton(BuildContext context, WidgetRef ref, int currentIndex) {
    if (currentIndex != 0) {
      // If not on home, go to home
      ref.read(bottomNavIndexProvider.notifier).state = 0;
    } else {
      // If on home, show exit confirmation
      _showExitConfirmation(context);
    }
  }

  /// Show exit confirmation dialog
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              SystemNavigator.pop(); // Exit the app
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const CleanHomeScreen();
      case 1:
        return const CleanCategoriesScreen();
      default:
        return const CleanHomeScreen(); // Fallback to home for any other index
    }
  }
}
