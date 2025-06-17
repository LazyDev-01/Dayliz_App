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
import '../auth/premium_auth_landing_screen.dart';
import '../auth/phone_auth_screen.dart';
import '../auth/otp_verification_screen.dart';

import '../dev/cart_sync_test_screen.dart';
import '../../../navigation/routes.dart';
import '../../widgets/common/unified_app_bar.dart';

class DebugMenuScreen extends ConsumerWidget {
  const DebugMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: UnifiedAppBars.simple(
        title: '🚀 UPDATED DEBUG MENU 🚀',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // SUPER OBVIOUS TEST BUTTON
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.green.shade700],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('🎉 SUCCESS!'),
                    content: const Text('The debug menu has been successfully updated!\n\nYou can now see the new authentication testing options below.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Awesome!'),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🚀 DEBUG MENU UPDATED!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap here to confirm you can see this update!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Authentication Testing Section
          _buildSectionHeader('🔐 Authentication Testing'),
          _buildDebugTile(
            context,
            title: 'Premium Auth Landing Screen',
            subtitle: 'Test the new premium authentication landing screen with modern UI',
            icon: Icons.login,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumAuthLandingScreen(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'Phone Authentication Flow',
            subtitle: 'Test phone number input and OTP verification flow',
            icon: Icons.phone_android,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhoneAuthScreen(),
                ),
              );
            },
          ),
          _buildDebugTile(
            context,
            title: 'OTP Verification Screen',
            subtitle: 'Test OTP input screen with sample phone number',
            icon: Icons.sms,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtpVerificationScreen(
                    phoneNumber: '+1 (555) 123-4567',
                    countryCode: '+1',
                  ),
                ),
              );
            },
          ),

          // Backend Testing Section
          _buildSectionHeader('☁️ Backend Testing'),
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

          // Location & Maps Testing Section
          _buildSectionHeader('🗺️ Location & Maps Testing'),
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

          // UI/UX Testing Section
          _buildSectionHeader('🎨 UI/UX Testing'),
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



  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
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
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 24,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
