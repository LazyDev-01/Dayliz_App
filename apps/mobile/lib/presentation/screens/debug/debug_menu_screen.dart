import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'supabase_connection_test_screen.dart';
import 'supabase_auth_test_screen.dart';
import '../profile/clean_address_form_screen.dart';
import '../../../navigation/routes.dart';
import '../../widgets/common/common_app_bar.dart';

class DebugMenuScreen extends ConsumerWidget {
  const DebugMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: CommonAppBars.simple(
        title: 'Debug Menu',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDebugTile(
            context,
            title: 'Supabase Connection Test',
            subtitle: 'Test connection to Supabase and basic operations',
            icon: Icons.cloud,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupabaseConnectionTestScreen(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Clean Address Form',
            subtitle: 'Test the clean architecture address form',
            icon: Icons.location_on,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CleanAddressFormScreen(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Supabase Auth & Address Test',
            subtitle: 'Test authentication and address operations with Supabase',
            icon: Icons.security,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupabaseAuthTestScreen(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Product Card Test',
            subtitle: 'Test the new product card design with real products from Supabase',
            icon: Icons.shopping_bag,
            onTap: () {
              CleanRoutes.navigateToProductCardTest(context);
            },
          ),
          _buildDebugTile(
            context,
            title: 'Search',
            subtitle: 'Test the clean search screen implementation',
            icon: Icons.search,
            onTap: () {
              CleanRoutes.navigateToSearch(context);
            },
          ),
          _buildDebugTile(
            context,
            title: 'GPS Integration Test',
            subtitle: 'Test real GPS functionality and mock GPS switching',
            icon: Icons.gps_fixed,
            onTap: () {
              context.push('/test-gps');
            },
          ),
          _buildDebugTile(
            context,
            title: 'Google Maps Test',
            subtitle: 'Test Google Maps integration with location picking',
            icon: Icons.map,
            onTap: () {
              context.push('/test-google-maps');
            },
          ),

        ],
      ),
    );
  }

  Widget _buildDebugTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
