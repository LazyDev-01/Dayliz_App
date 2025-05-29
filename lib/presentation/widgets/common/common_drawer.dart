import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A common drawer widget that can be used throughout the app
class CommonDrawer extends ConsumerWidget {
  /// Creates a common drawer with consistent styling
  const CommonDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context),

          // Main Navigation
          _buildSectionHeader(context, 'Main Navigation'),
          _buildDrawerItem(
            context,
            icon: Icons.home_outlined,
            title: 'Home',
            onTap: () => _navigateTo(context, '/clean-home'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.category_outlined,
            title: 'Categories',
            onTap: () => _navigateTo(context, '/clean/categories'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.shopping_cart_outlined,
            title: 'Cart',
            onTap: () => _navigateTo(context, '/clean/cart'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.receipt_outlined,
            title: 'Orders',
            onTap: () => _navigateTo(context, '/clean/orders'),
          ),

          const Divider(),

          // User Account
          _buildSectionHeader(context, 'Your Account'),
          _buildDrawerItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () => _navigateTo(context, '/profile'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.favorite_border,
            title: 'Wishlist',
            onTap: () => _navigateTo(context, '/wishlist'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            onTap: () => _navigateTo(context, '/addresses'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.payment_outlined,
            title: 'Payment Options',
            onTap: () => _navigateTo(context, '/payment-options'),
          ),

          const Divider(),

          // Development & Testing
          _buildSectionHeader(context, 'Development & Testing'),
          _buildDrawerItem(
            context,
            icon: Icons.bug_report_outlined,
            title: 'Debug Menu',
            onTap: () => _navigateTo(context, '/clean/debug'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.shopping_bag_outlined,
            title: 'Product Card Test',
            onTap: () => _navigateTo(context, '/clean/test/product-card'),
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => _navigateTo(context, '/dev/settings'),
          ),

          const Divider(),

          // App Info
          _buildDrawerItem(
            context,
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              // Show about dialog
              showAboutDialog(
                context: context,
                applicationName: 'Dayliz App',
                applicationVersion: '1.0.0',
                applicationIcon: Image.asset(
                  'assets/images/logo.png',
                  width: 48,
                  height: 48,
                ),
                applicationLegalese: '© 2023 Dayliz App',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App logo
          Image.asset(
            'assets/images/logo.png',
            width: 64,
            height: 64,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if logo image is not found
              return Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Dayliz',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // App name
          const Text(
            'Dayliz App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          // Tagline
          const Text(
            'Quick Grocery Delivery',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      onTap: () {
        // Close the drawer first
        Navigator.pop(context);
        // Then navigate
        onTap();
      },
      selected: isSelected,
    );
  }

  void _navigateTo(BuildContext context, String route) {
    GoRouter.of(context).go(route);
  }
}

/// Factory methods for creating common drawer configurations
class CommonDrawers {
  /// Creates a standard drawer
  static CommonDrawer standard() {
    return const CommonDrawer();
  }
}
