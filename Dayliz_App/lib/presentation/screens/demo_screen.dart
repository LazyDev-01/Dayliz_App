import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/category_providers.dart';
import '../../core/config/app_config.dart';
import '../screens/dev/backend_config_screen.dart';
import '../../test_gps_integration.dart';

class CleanArchitectureDemoScreen extends ConsumerWidget {
  const CleanArchitectureDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clean Architecture Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Authentication section
            _buildSectionTitle('Authentication'),
            const SizedBox(height: 8),
            _buildFeatureCard(
              context: context,
              title: 'Login',
              description: 'Clean architecture login screen with Riverpod state management.',
              icon: Icons.login,
              onTap: () => context.go('/clean/login'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              title: 'Register',
              description: 'User registration with validation and error handling.',
              icon: Icons.person_add,
              onTap: () => context.go('/signup'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              title: 'Forgot Password',
              description: 'Password recovery flow with email verification.',
              icon: Icons.lock_reset,
              onTap: () => context.go('/reset-password'),
            ),

            const SizedBox(height: 24),

            // Backend Configuration (developer-only)
            if (AppConfig.isDevelopment) ...[
              _buildSectionTitle('Developer Tools'),
              const SizedBox(height: 8),
              _buildFeatureCard(
                context: context,
                title: 'Backend Configuration',
                description: 'Switch between Supabase and FastAPI backends.',
                icon: Icons.settings_applications,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BackendConfigScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Current backend indicator
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppConfig.useFastAPI ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: AppConfig.useFastAPI ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Using ${AppConfig.useFastAPI ? "FastAPI" : "Supabase"} Backend',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConfig.useFastAPI ? Colors.orange[800] : Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Products section
            _buildSectionTitle('Products'),
            const SizedBox(height: 8),
            _buildFeatureCard(
              context: context,
              title: 'Product Feature Testing',
              description: 'Test all product-related features in one screen.',
              icon: Icons.science_outlined,
              onTap: () => context.go('/test/product-feature'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              title: 'Product Listing',
              description: 'Browse products with clean architecture.',
              icon: Icons.view_list,
              onTap: () => context.go('/clean/products'),
            ),

            const SizedBox(height: 24),

            // Categories section
            _buildSectionTitle('Categories'),
            const SizedBox(height: 8),

            _buildFeatureCard(
              context: context,
              title: 'Browse All Categories',
              description: 'View all categories with clean architecture implementation',
              icon: Icons.category,
              onTap: () => context.go('/clean/categories'),
            ),

            const SizedBox(height: 12),

            // Categories list with main provider
            Consumer(
              builder: (context, ref, child) {
                final categoriesAsync = ref.watch(categoriesProvider);

                return categoriesAsync.when(
                  data: (categories) {
                    if (categories.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text('No categories available'),
                      );
                    }

                    // Show max 5 categories
                    final displayCategories = categories.take(5).toList();
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayCategories.length,
                      itemBuilder: (context, index) {
                        final category = displayCategories[index];
                        return _buildFeatureCard(
                          context: context,
                          title: category.name,
                          description: 'Browse ${category.subCategories?.length ?? 0} subcategories',
                          icon: category.icon,
                          onTap: () {
                            // Navigate to categories screen
                            context.go('/categories');
                          },
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Error loading categories: $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Profile section
            _buildSectionTitle('User Profile'),
            const SizedBox(height: 8),
            _buildFeatureCard(
              context: context,
              title: 'My Profile',
              description: 'View and edit your user profile',
              icon: Icons.person_outline,
              onTap: () => context.go('/clean/profile'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              title: 'My Addresses',
              description: 'Manage your shipping addresses',
              icon: Icons.location_on_outlined,
              onTap: () => context.go('/clean/addresses'),
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              context: context,
              title: 'GPS Integration Test',
              description: 'Test real GPS location services and permissions',
              icon: Icons.gps_fixed,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TestGPSIntegrationScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}