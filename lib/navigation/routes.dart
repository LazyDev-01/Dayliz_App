import 'package:flutter/material.dart';
import '../domain/entities/category.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/address.dart';
import '../presentation/screens/product/clean_product_listing_screen.dart';
import '../presentation/screens/product/clean_product_details_screen.dart';
import '../presentation/screens/product/clean_subcategory_product_screen.dart';
import '../presentation/screens/auth/clean_login_screen.dart';
import '../presentation/screens/auth/clean_forgot_password_screen.dart';
import '../presentation/screens/auth/clean_register_screen.dart';
import '../presentation/screens/cart/clean_cart_screen.dart';
import '../presentation/screens/checkout/clean_checkout_screen.dart';
import '../presentation/screens/checkout/payment_methods_screen.dart';
import '../presentation/screens/category/clean_category_screen.dart';
import '../presentation/screens/category/clean_subcategory_screen.dart';
import '../presentation/screens/categories/clean_categories_screen.dart';
import '../presentation/screens/categories/clean_subcategory_products_screen.dart';
import '../presentation/screens/profile/clean_user_profile_screen.dart';
import '../presentation/screens/profile/clean_address_list_screen.dart';
import '../presentation/screens/profile/clean_preferences_screen.dart';
import '../presentation/screens/orders/clean_order_list_screen.dart';
import '../presentation/screens/orders/clean_order_detail_screen.dart';
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
      
      case 'categories-old':
        // Legacy clean categories screen (keeping for backward compatibility)
        return MaterialPageRoute(
          builder: (_) => const CleanCategoryScreen(),
          settings: settings,
        );
      
      case 'category':
        // Category subcategories screen
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => CleanSubcategoryScreen(
              categoryId: args,
              categoryName: '', // Will be loaded from the category data
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);
      
      case 'subcategory':
        // Subcategory product listing (legacy version)
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CleanSubcategoryProductScreen(
              subcategoryId: args['subcategoryId'] as String,
              subcategoryName: args['subcategoryName'] as String,
            ),
            settings: settings,
          );
        }
        return _errorRoute(settings);
      
      case 'subcategory-products':
        // Clean subcategory product listing with Riverpod implementation
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CleanSubcategoryProductsScreen(
              subcategoryId: args['subcategoryId'] as String,
              subcategoryName: args['subcategoryName'] as String,
            ),
            settings: settings,
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
        // Clean cart screen
        return MaterialPageRoute(
          builder: (_) => const CleanCartScreen(),
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
          builder: (_) => const CleanAddressListScreen(),
          settings: settings,
        );
        
      case 'address/edit':
        // Edit existing address - this would typically include an ID parameter
        // For now, we'll route to the address list until we implement an address form
        if (args is Address) {
          return MaterialPageRoute(
            builder: (_) => const CleanAddressListScreen(),
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
        
      case 'orders/detail':
        // Order detail screen
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => CleanOrderDetailScreen(orderId: args),
            settings: settings,
          );
        }
        return _errorRoute(settings);
        
      default:
        // Check if the path is like 'address/edit/{id}'
        if (cleanPath.startsWith('address/edit/')) {
          final addressId = cleanPath.substring('address/edit/'.length);
          // This would typically use the addressId to edit the specific address
          // For now, we'll route to the address list until we implement an address form
          return MaterialPageRoute(
            builder: (_) => const CleanAddressListScreen(),
            settings: settings,
          );
        }
        
        return _errorRoute(settings);
    }
  }

  // Demo navigation method for clean login
  static void navigateToCleanLogin(BuildContext context) {
    GoRouter.of(context).push('/clean/login');
  }
  
  // Demo navigation method for clean register
  static void navigateToCleanRegister(BuildContext context) {
    GoRouter.of(context).push('/clean/register');
  }
  
  // Demo navigation method for clean forgot password
  static void navigateToCleanForgotPassword(BuildContext context) {
    GoRouter.of(context).push('/clean/forgot-password');
  }

  // Demo navigation method for categories
  static void navigateToCategories(BuildContext context) {
    GoRouter.of(context).push('/clean/categories');
  }

  // Demo navigation method for subcategory
  static void navigateToSubcategoryProducts(BuildContext context, SubCategory subcategory) {
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
  
  // Demo navigation method for user profile
  static void navigateToUserProfile(BuildContext context) {
    GoRouter.of(context).push('/clean/profile');
  }
  
  // Demo navigation method for addresses
  static void navigateToAddresses(BuildContext context) {
    GoRouter.of(context).push('/clean/addresses');
  }
  
  // Demo navigation method for preferences
  static void navigateToPreferences(BuildContext context) {
    GoRouter.of(context).push('/clean/preferences');
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