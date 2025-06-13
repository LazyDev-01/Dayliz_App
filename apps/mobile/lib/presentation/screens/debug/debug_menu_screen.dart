import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'supabase_connection_test_screen.dart';
import 'supabase_auth_test_screen.dart';
import 'google_maps_diagnostic_screen.dart';
import 'simple_google_maps_test.dart';
import 'google_maps_api_test.dart';
import '../profile/clean_address_form_screen.dart';
import '../order/order_summary_screen.dart';
import '../categories/optimized_categories_screen.dart';

import '../dev/cart_sync_test_screen.dart';
import '../../../navigation/routes.dart';
import '../../widgets/common/unified_app_bar.dart';

class DebugMenuScreen extends ConsumerWidget {
  const DebugMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: UnifiedAppBars.simple(
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
            title: 'Cart Sync Diagnostics',
            subtitle: 'Test cart database synchronization and authentication',
            icon: Icons.sync,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartSyncTestScreen(),
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
            title: 'Google Maps API Test',
            subtitle: 'Test API key and network connectivity',
            icon: Icons.api,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoogleMapsApiTest(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Simple Google Maps Test',
            subtitle: 'Basic test to check if Google Maps loads',
            icon: Icons.map_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SimpleGoogleMapsTest(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Google Maps Diagnostic',
            subtitle: 'Diagnose Google Maps loading issues',
            icon: Icons.bug_report,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GoogleMapsDiagnosticScreen(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Google Maps Integration Test',
            subtitle: 'Test Google Maps integration with rich POI data',
            icon: Icons.map,
            onTap: () {
              context.push('/test-google-maps');
            },
          ),
          _buildDebugTile(
            context,
            title: 'Modern Cart Screen',
            subtitle: 'Test the new modern cart UI design (UI-only)',
            icon: Icons.shopping_cart,
            onTap: () {
              context.push('/modern-cart');
            },
          ),
          _buildDebugTile(
            context,
            title: 'Payment Selection Screen',
            subtitle: 'Test the payment method selection for checkout flow (UI-only)',
            icon: Icons.payment,
            onTap: () {
              context.push('/payment-selection');
            },
          ),
          _buildDebugTile(
            context,
            title: 'Order Summary Screen',
            subtitle: 'Test the order summary page after order placement (UI-only)',
            icon: Icons.receipt_long,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrderSummaryScreen(
                    orderId: 'DEBUG_ORDER_123',
                  ),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Optimized Categories Screen',
            subtitle: 'High-performance categories with staggered grid (Performance Test)',
            icon: Icons.speed,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OptimizedCategoriesScreen(),
                ),
              );
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
