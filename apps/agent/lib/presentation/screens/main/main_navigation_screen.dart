import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../dashboard/agent_dashboard_screen.dart';
import '../orders/orders_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/agent_profile_screen.dart';

/// Main navigation screen that manages bottom navigation and displays appropriate content
/// This ensures consistent bottom navigation across all main app screens
class MainNavigationScreen extends StatefulWidget {
  /// The initial tab index to display
  final int initialIndex;
  
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  // List of main app screens
  final List<Widget> _screens = const [
    AgentDashboardScreen(showBottomNav: false), // Dashboard without bottom nav
    OrdersScreen(showBottomNav: false),         // Orders without bottom nav
    EarningsScreen(showBottomNav: false),       // Earnings without bottom nav
    AgentProfileScreen(showBottomNav: false),   // Profile without bottom nav
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Handle back button manually
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavigation(),
      ),
    );
  }

  /// Handle device back button
  void _handleBackButton() {
    if (_currentIndex != 0) {
      // If not on dashboard, go to dashboard
      _navigateToTab(0);
    } else {
      // If on dashboard, show exit confirmation
      _showExitConfirmation();
    }
  }

  /// Show exit confirmation dialog
  void _showExitConfirmation() {
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

  /// Navigate to specific tab
  void _navigateToTab(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }



  /// Build bottom navigation bar
  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF2E7D32),
      unselectedItemColor: Colors.grey,
      currentIndex: _currentIndex,
      onTap: _navigateToTab,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.currency_rupee),
          label: 'Earnings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}


