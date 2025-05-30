import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../widgets/common/common_app_bar.dart';

/// A clean architecture development settings screen that allows toggling between
/// different implementations and feature flags
class CleanSettingsScreen extends ConsumerStatefulWidget {
  const CleanSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanSettingsScreen> createState() => _CleanSettingsScreenState();
}

class _CleanSettingsScreenState extends ConsumerState<CleanSettingsScreen> {
  bool _useFastAPI = AppConfig.useFastAPI;
  bool _useCleanArchitecture = true; // Always true now

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBars.withBackButton(
        title: 'Developer Settings',
        fallbackRoute: '/clean/debug/menu',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Architecture'),
          _buildArchitectureInfo(),
          const Divider(),
          _buildSectionHeader('Backend'),
          _buildBackendToggle(),
          const Divider(),
          _buildSectionHeader('Actions'),
          _buildActionButtons(),
          const Divider(),
          _buildSectionHeader('Debug Tools'),
          _buildDebugTools(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildArchitectureInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'App Architecture',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const ListTile(
              title: Text('Clean Architecture'),
              subtitle: Text('Using Clean Architecture Implementation'),
              trailing: Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend Implementation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Use FastAPI Backend'),
              subtitle: Text(_useFastAPI
                  ? 'Using FastAPI Backend'
                  : 'Using Supabase Backend'),
              value: _useFastAPI,
              onChanged: (value) async {
                await AppConfig.setUseFastAPI(value);
                setState(() {
                  _useFastAPI = value;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Switched to ${value ? 'FastAPI' : 'Supabase'} Backend',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                // Log out and navigate to login screen
                context.go('/');
              },
              child: const Text('Restart App Flow'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Navigate to login
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
              ),
              child: const Text('Go to Login Screen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugTools() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: const Text('Supabase Connection Test'),
              leading: const Icon(Icons.cloud),
              onTap: () => context.go('/clean/debug/supabase-test'),
            ),
            ListTile(
              title: const Text('Database Seeder'),
              leading: const Icon(Icons.storage),
              onTap: () => context.go('/dev/database-seeder'),
            ),
            ListTile(
              title: const Text('Google Sign-In Debug'),
              leading: const Icon(Icons.login),
              onTap: () => context.go('/clean/debug/google-sign-in'),
            ),
            ListTile(
              title: const Text('Cart Dependencies Test'),
              leading: const Icon(Icons.shopping_cart),
              onTap: () => context.go('/debug/cart-dependencies'),
            ),
          ],
        ),
      ),
    );
  }
}
