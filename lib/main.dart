import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dayliz_app/core/config/app_config.dart';
import 'package:dayliz_app/core/services/supabase_service.dart';
import 'package:dayliz_app/core/utils/image_preloader.dart';
// Clean architecture imports
import 'package:dayliz_app/presentation/providers/auth_providers.dart' as clean_auth;
import 'package:dayliz_app/presentation/providers/theme_providers.dart';
import 'package:dayliz_app/presentation/screens/dev/clean_settings_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/supabase_connection_test_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/debug_menu_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/clean_google_sign_in_debug_screen.dart';
import 'debug_google_signin.dart';

import 'package:dayliz_app/presentation/screens/debug/cart_dependency_test_screen.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/presentation/screens/dev/clean_database_seeder_screen.dart';
// Clean architecture screens
import 'package:dayliz_app/presentation/screens/product/clean_product_listing_screen.dart';
import 'package:dayliz_app/presentation/screens/product/clean_product_details_screen.dart';
import 'package:dayliz_app/presentation/screens/product/product_feature_testing_screen.dart';
import 'package:dayliz_app/presentation/screens/wishlist/clean_wishlist_screen.dart';
import 'package:dayliz_app/presentation/screens/main/clean_main_screen.dart';
import 'package:dayliz_app/presentation/widgets/common/common_bottom_nav_bar.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_list_screen.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_confirmation_screen.dart';
// Import for clean architecture initialization
import 'di/dependency_injection.dart' as di;
import 'di/product_dependency_injection.dart' as product_di;

import 'presentation/screens/auth/clean_login_screen.dart';
import 'presentation/screens/auth/clean_register_screen.dart';
import 'presentation/screens/auth/clean_forgot_password_screen.dart';
import 'presentation/screens/auth/clean_update_password_screen.dart';
import 'presentation/screens/cart/clean_cart_screen.dart';
import 'presentation/screens/checkout/clean_checkout_screen.dart';
import 'presentation/screens/checkout/payment_methods_screen.dart';
import 'presentation/screens/payment/payment_options_screen.dart';
import 'presentation/screens/categories/clean_categories_screen.dart';
import 'presentation/screens/clean_demo_screen.dart';
import 'presentation/screens/profile/clean_address_list_screen.dart';
import 'presentation/screens/profile/clean_address_form_screen.dart';
import 'presentation/screens/profile/clean_user_profile_screen.dart';
import 'presentation/screens/profile/clean_preferences_screen.dart';
import 'presentation/screens/search/clean_search_screen.dart';

// Splash screen temporarily disabled
// import 'presentation/screens/splash/clean_splash_screen.dart';
import 'presentation/screens/auth/clean_verify_token_handler.dart';

// Define auth states for router redirection
enum AppAuthState { authenticated, unauthenticated, emailVerificationRequired }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize app configuration
  await AppConfig.init();

  // Initialize Supabase service first
  try {
    final supabaseService = SupabaseService.instance;
    await supabaseService.initialize();
    debugPrint('SupabaseService initialized successfully');
  } catch (e) {
    debugPrint('Error initializing SupabaseService: $e');
  }

  // Initialize authentication components (also initializes cart components)
  try {
    await di.initAuthentication();
    debugPrint('Authentication and cart components initialized successfully');
  } catch (e) {
    debugPrint('Error initializing authentication and cart components: $e');
    // Continue with app startup even if auth init fails
  }

  // Gracefully initialize clean architecture components
  try {
    await di.initCleanArchitecture();
    debugPrint('Clean architecture initialization successful');

    // Initialize product dependencies with Supabase implementation
    try {
      await product_di.initProductDependencies();
      debugPrint('Product dependencies initialization successful');
    } catch (e) {
      debugPrint('Product dependencies initialization failed: $e');
      // Continue with the app even if product dependencies initialization fails
    }

    debugPrint('Clean architecture initialization completed');
  } catch (e) {
    debugPrint('Clean architecture initialization failed: $e');
    // Continue with the app even if clean architecture init fails
  }

  // Skip heavy initialization operations that might be causing the hang
  debugPrint('Skipping database migrations and seeding for faster startup');

  // Test database connections (simplified)
  try {
    debugPrint('Testing database connections...');
    debugPrint('✅ Database connection will be tested by clean architecture initialization');
  } catch (e) {
    debugPrint('Error testing database connections: $e');
  }

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// The main app widget
class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();

    // No need to manually register navigator key since it's now static mutable
    // NavigationService.navigatorKey is accessible from anywhere
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // CRITICAL FIX: Don't force auth notifier to initialize immediately
    // Let it initialize when actually needed by the router
    // ref.watch(clean_auth.authNotifierProvider); // Removed

    return MaterialApp.router(
      title: 'Dayliz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}



/// A page that doesn't apply any transition animation
class NoTransitionPage<T> extends Page<T> {
  final Widget child;

  const NoTransitionPage({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder<T>(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

/// Router provider for navigation - FIXED to prevent infinite loops
final routerProvider = Provider<GoRouter>((ref) {
  // CRITICAL FIX: Don't watch auth state here - it causes infinite router rebuilds
  // The router redirect logic will read auth state when needed

  // Create a navigator observer to handle index updates
  final indexObserver = IndexObserver(ref);

  // Preload images that would normally be loaded during splash screen
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // This will run after the first frame is rendered
    final context = WidgetsBinding.instance.rootElement;
    if (context != null) {
      ImagePreloader.instance.preloadKeyImages(context);
    }
  });

  // CRITICAL FIX: Create a stable router that doesn't rebuild on auth changes
  return GoRouter(
    // CRITICAL FIX: Don't set initialLocation to allow deep links to work properly
    // initialLocation: '/login', // Removed to allow deep links
    debugLogDiagnostics: true, // Enable debug logging to track deep link issues

    // CRITICAL FIX: Simplified redirect logic that reads auth state when needed
    redirect: (context, state) {
      // CRITICAL FIX: Read auth state to handle logout redirects properly
      bool isAuthenticated = false;
      bool isLoading = false;

      try {
        final authState = ref.read(clean_auth.authNotifierProvider);
        isAuthenticated = authState.isAuthenticated && authState.user != null;
        isLoading = authState.isLoading;

        debugPrint('🔄 ROUTER: Auth state - authenticated: $isAuthenticated, user: ${authState.user?.id}, loading: $isLoading');
      } catch (e) {
        debugPrint('🔄 ROUTER: Auth state not ready yet, treating as unauthenticated: $e');
        // If auth state is not ready, treat as unauthenticated and not loading
        isAuthenticated = false;
        isLoading = false;
      }

      debugPrint('🔄 ROUTER: Redirect called for ${state.uri.path}');
      debugPrint('🔄 ROUTER: Full URI: ${state.uri}');
      debugPrint('🔄 ROUTER: Query params: ${state.uri.queryParameters}');
      debugPrint('🔄 ROUTER: Auth: $isAuthenticated, Loading: $isLoading');

      // Don't redirect during loading states
      if (isLoading) {
        debugPrint('ROUTER: Skipping redirect during loading state');
        return null;
      }

      // Handle root path
      if (state.uri.path == '/') {
        // CRITICAL FIX: Check if this is a password reset deep link
        if (state.uri.queryParameters.containsKey('code') &&
            state.uri.queryParameters['type'] == 'reset_password') {
          debugPrint('🔄 ROUTER: Detected password reset deep link, redirecting to verify-email');
          final code = state.uri.queryParameters['code'];
          return '/verify-email?token=$code&type=reset_password';
        }

        return isAuthenticated ? '/home' : '/login';
      }

      // CRITICAL FIX: Never auto-redirect from auth screens
      // Let them handle their own navigation after success/error
      if (state.uri.path == '/login' || state.uri.path == '/signup' || state.uri.path == '/reset-password') {
        debugPrint('ROUTER: On auth screen, allowing manual navigation control');
        return null;
      }

      // GUEST MODE: Define guest-accessible routes (browsing without authentication)
      final guestAccessibleRoutes = [
        '/login',
        '/signup',
        '/reset-password',
        '/home',           // Main home screen
        '/categories',     // Browse categories
        '/products',       // Browse products
        '/clean/categories', // Clean architecture categories
        // NOTE: Cart routes are protected - guests will see auth prompts
      ];

      // Check if current path is guest-accessible
      final isGuestAccessible = guestAccessibleRoutes.any((route) =>
        state.uri.path == route || state.uri.path.startsWith(route));

      // Protect authenticated routes
      if (!isAuthenticated &&
          !isGuestAccessible &&
          !state.uri.path.startsWith('/auth/verify') &&
          !state.uri.path.startsWith('/verify-email')) {

        // CRITICAL FIX: Allow access to update-password with token (password reset)
        if (state.uri.path == '/update-password' && state.uri.queryParameters.containsKey('token')) {
          debugPrint('ROUTER: Allowing access to password reset screen with token');
          return null;
        }

        debugPrint('ROUTER: Redirecting unauthenticated user to login');
        return '/login';
      }

      return null;
    },

    // Setup observers for deep linking and index tracking
    observers: [
      NavigatorObserver(),
      indexObserver,
    ],

    // Deep link debugging disabled to reduce noise

    routes: [
      // CRITICAL FIX: Root path now handled by redirect logic only
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          // This should never be reached due to redirect logic
          // But provide a fallback just in case
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanLoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      // Main screen route (after splash)
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanMainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      // Login route now uses clean architecture implementation
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      // Signup route now uses clean architecture implementation
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanRegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      // Email verification route
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'verify_email';

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanVerifyTokenHandler(
              token: token,
              type: type,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/auth/verify',
        redirect: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'verify_email';
          return '/verify-email?token=$token&type=$type';
        },
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      // Clean architecture version of update password screen
      GoRoute(
        path: '/update-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'];
          final isReset = token != null;

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanUpdatePasswordScreen(
              token: token,
              isReset: isReset,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),

      // Profile route
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanUserProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      // Categories route
      GoRoute(
        path: '/categories',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCategoriesScreen(),
        ),
      ),
      // Cart route
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCartScreen(),
        ),
      ),
      // Checkout route
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCheckoutScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      // Order confirmation route
      GoRoute(
        path: '/order-confirmation/:orderId',
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanOrderConfirmationScreen(orderId: orderId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/addresses',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanAddressListScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/preferences',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanPreferencesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/address-form',
        pageBuilder: (context, state) {
          // We're ignoring any passed address to avoid type conflicts
          // We'll handle fetching the address in the form screen if needed

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanAddressFormScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/address/add',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanAddressFormScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      // Debug screen for Google Sign-In
      GoRoute(
        path: '/debug/google-sign-in',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanGoogleSignInDebugScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      // Debug screen for testing password reset deep links
      GoRoute(
        path: '/debug/password-reset-test',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: Scaffold(
              appBar: AppBar(title: const Text('Password Reset Deep Link Test')),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Test Password Reset Deep Links'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Test the verify-email route with reset_password type
                        context.go('/verify-email?type=reset_password&token=test123');
                      },
                      child: const Text('Test Verify Email Route'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Test the update-password route directly
                        context.go('/update-password?token=test123');
                      },
                      child: const Text('Test Update Password Route'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text('Back to Login'),
                    ),
                  ],
                ),
              ),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      // Debug screen for Cart Dependencies
      GoRoute(
        path: '/debug/cart-dependencies',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CartDependencyTestScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/address/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          // We'll fetch the address in the form screen using the ID
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanAddressFormScreen(addressId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      // Category route
      GoRoute(
        path: '/category/:id',
        pageBuilder: (context, state) {
          final categoryId = state.pathParameters['id']!;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanProductListingScreen(
              categoryId: categoryId,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),
      // Product details route
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id']!;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanProductDetailsScreen(productId: productId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
      ),

      // Testing screen for clean architecture product feature
      GoRoute(
        path: '/test/product-feature',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ProductFeatureTestingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      // Development tools routes
      GoRoute(
        path: '/dev/database-seeder',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanDatabaseSeederScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      // Supabase connection test screen
      GoRoute(
        path: '/clean/debug/supabase-test',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SupabaseConnectionTestScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      // Debug menu screen
      GoRoute(
        path: '/clean/debug/menu',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const DebugMenuScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      // Debug Google Sign-In screen
      GoRoute(
        path: '/debug/google-signin',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const DebugGoogleSignIn(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/dev/settings',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanSettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      // Wishlist screen route
      GoRoute(
        path: '/wishlist',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanWishlistScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      // Clean Architecture Demo Screen
      GoRoute(
        path: '/clean-demo',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanDemoScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
        ),
      ),

      // Orders route
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanOrderListScreen(),
        ),
      ),

      // Search Route
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanSearchScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      // Payment Methods Route
      GoRoute(
        path: '/payment-methods',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: PaymentMethodsScreen(
            isCheckout: state.uri.queryParameters['checkout'] == 'true',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),

      // Modern Payment Options Route
      GoRoute(
        path: '/payment-options',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PaymentOptionsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
      ),

      // Clean architecture routes that the app actually uses
      GoRoute(
        path: '/clean/categories',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCategoriesScreen(),
        ),
      ),
      GoRoute(
        path: '/clean/cart',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCartScreen(),
        ),
      ),
      GoRoute(
        path: '/clean/orders',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanOrderListScreen(),
        ),
      ),
      GoRoute(
        path: '/clean-home',
        redirect: (_, __) => '/home',
      ),
      GoRoute(
        path: '/clean/subcategory-products',
        pageBuilder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          if (args != null) {
            return CustomTransitionPage<void>(
              key: state.pageKey,
              child: CleanProductListingScreen(
                subcategoryId: args['subcategoryId'] as String,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          }
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const Scaffold(
              body: Center(child: Text('Invalid subcategory')),
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),

    ],

    // Add error handling for routes
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Page not found: ${state.uri.path}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    ),
  );
});

/// Navigator observer to update the current index based on routes
class IndexObserver extends NavigatorObserver {
  final Ref ref;

  IndexObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _updateIndexFromRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateIndexFromRoute(newRoute);
    }
  }

  void _updateIndexFromRoute(Route<dynamic> route) {
    final routeName = route.settings.name;
    if (routeName != null) {
      // Handle clean architecture routes
      if (routeName == '/home' || routeName == '/clean-home') {
        ref.read(bottomNavIndexProvider.notifier).state = 0;
      } else if (routeName == '/categories' || routeName == '/clean/categories') {
        ref.read(bottomNavIndexProvider.notifier).state = 1;
      } else if (routeName == '/cart' || routeName == '/clean/cart') {
        ref.read(bottomNavIndexProvider.notifier).state = 2;
      } else if (routeName == '/orders' || routeName == '/clean/orders') {
        ref.read(bottomNavIndexProvider.notifier).state = 3;
      } else if (routeName == '/profile') {
        // Profile is now in the top app bar, not in bottom navigation
      }
    }
  }
}
