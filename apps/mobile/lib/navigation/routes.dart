import 'package:flutter/material.dart';
import '../domain/entities/category.dart';
import '../domain/entities/address.dart';
import '../presentation/screens/product/clean_product_listing_screen.dart';
import '../presentation/screens/product/clean_product_details_screen.dart';
import '../presentation/screens/auth/clean_login_screen.dart';
import '../presentation/screens/auth/clean_forgot_password_screen.dart';
import '../presentation/screens/auth/clean_register_screen.dart';
import '../presentation/screens/cart/modern_cart_screen.dart';
import '../presentation/screens/checkout/clean_checkout_screen.dart';
// Debug imports removed for production
import '../presentation/screens/checkout/payment_methods_screen.dart';

import '../presentation/screens/categories/clean_categories_screen.dart';

import '../presentation/screens/profile/clean_user_profile_screen.dart';
import '../presentation/screens/profile/clean_address_list_screen.dart';
import '../presentation/screens/profile/clean_address_form_screen.dart';
import '../presentation/screens/profile/clean_preferences_screen.dart';
import '../presentation/screens/orders/clean_order_list_screen.dart';
import '../presentation/screens/orders/clean_order_detail_screen.dart';
import '../presentation/screens/search/enhanced_search_screen.dart';
import '../presentation/screens/wishlist/clean_wishlist_screen.dart';
// Debug imports removed for production
import '../presentation/screens/legal/privacy_policy_screen.dart';
import '../presentation/screens/legal/terms_of_service_screen.dart';
// Unused imports removed for production
// Debug imports removed for production
import 'package:go_router/go_router.dart';

/// Handles navigation routes for the clean architecture implementation
class CleanRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract route name and arguments
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path;
    final args = settings.arguments;

    // Parse the path to get the clean-specific route
    final cleanPath = path.replaceFirst('/clean/', '');

    // Parse route paths
    switch (cleanPath) {
      case 'login':
        // Clean login screen
        return MaterialPageRoute(
          builder: (_) => const CleanLoginScreen(),
          settings: settings,
        );

      case 'register':
        // Clean register screen
        return MaterialPageRoute(
          builder: (_) => const CleanRegisterScreen(),
          settings: settings,
        );

      case 'forgot-password':
        // Clean forgot password screen
        return MaterialPageRoute(
          builder: (_) => const CleanForgotPasswordScreen(),
          settings: settings,
        );

      case 'products':
        // Clean product listing screen
        return MaterialPageRoute(
          builder: (_) => const CleanProductListingScreen(),
          settings: settings,
        );

      case 'categories':
        // Clean categories screen with Riverpod implementation
        return MaterialPageRoute(
          builder: (_) => const CleanCategoriesScreen(),
          settings: settings,
        );

      // Removed 'categories-old' case as part of consolidation

      case 'category':
        // Redirect to categories screen
        return MaterialPageRoute(
          builder: (_) => const CleanCategoriesScreen(),
          settings: settings,
        );

      case 'subcategory':
        // Redirect to the consolidated product listing screen
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CleanProductListingScreen(
              subcategoryId: args['subcategoryId'] as String,
            ),
            // Pass the subcategory name as an argument to be used in the title
            settings: RouteSettings(
              name: settings.name,
              arguments: {
                'subcategoryName': args['subcategoryName'] as String,
              },
            ),
          );
        }
        return _errorRoute(settings);

      case 'subcategory-products':
        // Clean product listing with Riverpod implementation
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CleanProductListingScreen(
              subcategoryId: args['subcategoryId'] as String,
            ),
            // Pass the subcategory name as an argument to be used in the title
            settings: RouteSettings(
              name: settings.name,
              arguments: {
                'subcategoryName': args['subcategoryName'] as String,
              },
            ),
          );
        }
        return _errorRoute(settings);

      case 'product':
        // Product details
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => CleanProductDetailsScreen(productId: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case 'cart':
        // Modern cart screen (Phase 3: Replaced old cart with modern implementation)
        return MaterialPageRoute(
          builder: (_) => const ModernCartScreen(),
          settings: settings,
        );

      case 'checkout':
        // Clean checkout screen
        return MaterialPageRoute(
          builder: (_) => const CleanCheckoutScreen(),
          settings: settings,
        );

      case 'payment-methods':
        // Payment methods screen
        bool isCheckout = false;
        if (args is bool) {
          isCheckout = args;
        } else if (args is Map<String, dynamic> && args.containsKey('isCheckout')) {
          isCheckout = args['isCheckout'] as bool;
        }

        return MaterialPageRoute(
          builder: (_) => PaymentMethodsScreen(isCheckout: isCheckout),
          settings: settings,
        );

      case 'profile':
        // User profile screen
        return MaterialPageRoute(
          builder: (_) => const CleanUserProfileScreen(),
          settings: settings,
        );

      case 'addresses':
        // User addresses list screen
        return MaterialPageRoute(
          builder: (_) => const CleanAddressListScreen(),
          settings: settings,
        );

      case 'preferences':
        // User preferences screen
        return MaterialPageRoute(
          builder: (_) => const CleanPreferencesScreen(),
          settings: settings,
        );

      case 'address/add':
        // Add new address screen
        return MaterialPageRoute(
          builder: (_) => const CleanAddressFormScreen(),
          settings: settings,
        );

      case 'address/edit':
        // Edit existing address
        if (args is Address) {
          return MaterialPageRoute(
            builder: (_) => CleanAddressFormScreen(address: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      case 'orders':
        // Order list screen
        return MaterialPageRoute(
          builder: (_) => const CleanOrderListScreen(),
          settings: settings,
        );

      // Debug routes removed for production

      case 'privacy-policy':
        // Privacy Policy screen
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
          settings: settings,
        );

      case 'terms-of-service':
        // Terms of Service screen
        return MaterialPageRoute(
          builder: (_) => const TermsOfServiceScreen(),
          settings: settings,
        );

      case 'orders/detail':
        // Order detail screen
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => CleanOrderDetailScreen(orderId: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);

      // Debug routes removed for production

      case 'search':
        // Enhanced search screen (now the default search)
        return MaterialPageRoute(
          builder: (_) => const EnhancedSearchScreen(),
          settings: settings,
        );

      case 'enhanced-search':
        // Enhanced search screen with advanced features
        return MaterialPageRoute(
          builder: (_) => const EnhancedSearchScreen(),
          settings: settings,
        );

      case 'wishlist':
        // Wishlist screen
        return MaterialPageRoute(
          builder: (_) => const CleanWishlistScreen(),
          settings: settings,
        );

      // Test routes removed for production

      default:
        // Check if the path is like 'address/edit/{id}'
        if (cleanPath.startsWith('address/edit/')) {
          // Extract the address ID
          final addressId = cleanPath.substring('address/edit/'.length);
          // Use the addressId to edit the specific address
          return MaterialPageRoute(
            builder: (_) => CleanAddressFormScreen(addressId: addressId),
            settings: settings,
          );
        }

        return _errorRoute(settings);
    }
  }

  // Navigation method for login
  static void navigateToCleanLogin(BuildContext context) {
    GoRouter.of(context).push('/login');
  }

  // Navigation method for register
  static void navigateToCleanRegister(BuildContext context) {
    GoRouter.of(context).push('/signup');
  }

  // Navigation method for forgot password
  static void navigateToCleanForgotPassword(BuildContext context) {
    GoRouter.of(context).push('/reset-password');
  }

  // Demo navigation method for categories
  static void navigateToCategories(BuildContext context) {
    GoRouter.of(context).go('/home?tab=1');
  }

  // Demo navigation method for subcategory
  static void navigateToSubcategoryProducts(BuildContext context, SubCategory subcategory) {
    // Navigate to the consolidated product listing screen
    GoRouter.of(context).push(
      '/clean/subcategory-products',
      extra: {
        'subcategoryId': subcategory.id,
        'subcategoryName': subcategory.name,
      },
    );
  }

  // Demo navigation method for product details
  static void navigateToProductDetails(BuildContext context, String productId) {
    GoRouter.of(context).push(
      '/clean/product/$productId',
    );
  }

  // Demo navigation method for cart
  static void navigateToCart(BuildContext context) {
    GoRouter.of(context).push('/clean/cart');
  }

  // Demo navigation method for checkout
  static void navigateToCheckout(BuildContext context) {
    GoRouter.of(context).push('/clean/checkout');
  }

  // Demo navigation method for payment methods
  static void navigateToPaymentMethods(BuildContext context, {bool isCheckout = false}) {
    GoRouter.of(context).push(
      '/clean/payment-methods',
      extra: {'isCheckout': isCheckout},
    );
  }

  // Navigation method for user profile
  static void navigateToUserProfile(BuildContext context) {
    GoRouter.of(context).push('/profile');
  }

  // Navigation method for addresses
  static void navigateToAddresses(BuildContext context) {
    GoRouter.of(context).push('/addresses');
  }

  // Navigation method for preferences
  static void navigateToPreferences(BuildContext context) {
    GoRouter.of(context).push('/preferences');
  }

  // Debug navigation methods removed for production

  // Navigation method for search (global)
  static void navigateToSearch(BuildContext context, {String? initialQuery}) {
    final queryParams = initialQuery != null ? '?q=$initialQuery' : '';
    GoRouter.of(context).push('/search$queryParams');
  }

  // Navigation method for context-aware search
  static void navigateToContextSearch(
    BuildContext context, {
    String? subcategoryId,
    String? categoryId,
    String? contextName,
    String? initialQuery,
  }) {
    final params = <String, String>{};
    if (subcategoryId != null) params['subcategoryId'] = subcategoryId;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (contextName != null) params['contextName'] = contextName;
    if (initialQuery != null) params['q'] = initialQuery;

    final queryString = params.isNotEmpty
        ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
        : '';

    GoRouter.of(context).push('/search$queryString');
  }

  // Navigation method for wishlist
  static void navigateToWishlist(BuildContext context) {
    GoRouter.of(context).push('/wishlist');
  }

  // Error route for invalid routes
  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
          ),
          body: Center(
            child: Text('Route not found: ${settings.name}'),
          ),
        );
      },
      settings: settings,
    );
  }
}