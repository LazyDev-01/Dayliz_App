import 'package:flutter/material.dart';
import '../../navigation/routes.dart';
import 'package:go_router/go_router.dart';

class CleanDemoScreen extends StatelessWidget {
  const CleanDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Authentication'),
            _buildFeatureCard(
              context,
              icon: Icons.login,
              title: 'Login',
              description: 'Clean architecture implementation of the login screen',
              onTap: () => CleanRoutes.navigateToCleanLogin(context),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.app_registration,
              title: 'Register',
              description: 'Clean architecture implementation of the registration screen',
              onTap: () => CleanRoutes.navigateToCleanRegister(context),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.lock_reset,
              title: 'Forgot Password',
              description: 'Clean architecture implementation of the forgot password screen',
              onTap: () => CleanRoutes.navigateToCleanForgotPassword(context),
            ),

            const Divider(height: 32),
            const _SectionTitle(title: 'User Profile'),
            _buildFeatureCard(
              context,
              icon: Icons.account_circle,
              title: 'User Profile',
              description: 'Clean architecture implementation of the user profile screen',
              onTap: () => CleanRoutes.navigateToUserProfile(context),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.location_on,
              title: 'Address Management',
              description: 'Manage your delivery addresses with clean architecture',
              onTap: () => CleanRoutes.navigateToAddresses(context),
            ),

            const Divider(height: 32),
            const _SectionTitle(title: 'Shopping Experience'),
            _buildFeatureCard(
              context,
              icon: Icons.home,
              title: 'Home Screen',
              description: 'Clean architecture implementation of the home screen',
              onTap: () => context.go('/clean-home'),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.category,
              title: 'Categories',
              description: 'Clean architecture implementation of categories with Riverpod',
              onTap: () => CleanRoutes.navigateToCategories(context),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.grid_view,
              title: 'Product Listing',
              description: 'Clean architecture implementation of the product listing screen',
              onTap: () => GoRouter.of(context).push('/clean/products'),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.shopping_cart,
              title: 'Shopping Cart',
              description: 'Clean architecture implementation of the cart screen',
              onTap: () => CleanRoutes.navigateToCart(context),
            ),

            const Divider(height: 32),
            const _SectionTitle(title: 'Checkout Process'),
            _buildFeatureCard(
              context,
              icon: Icons.credit_card,
              title: 'Payment Methods',
              description: 'Manage payment methods with clean architecture',
              onTap: () => CleanRoutes.navigateToPaymentMethods(context),
            ),
            _buildFeatureCard(
              context,
              icon: Icons.shopping_bag,
              title: 'Checkout',
              description: 'Complete checkout process with clean architecture',
              onTap: () => CleanRoutes.navigateToCheckout(context),
            ),

            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Clean Architecture Migration Plan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'This demo showcases the progressive migration to clean architecture. '
                'Some features are still in development.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}