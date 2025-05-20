import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dayliz_app/core/config/app_config.dart';
// Legacy screens removed
import 'package:dayliz_app/presentation/providers/auth_providers.dart' as clean_auth;
import 'package:dayliz_app/screens/dev/settings_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/supabase_connection_test_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/debug_menu_screen.dart';
import 'package:dayliz_app/screens/debug/google_sign_in_debug_screen.dart';
import 'package:dayliz_app/presentation/screens/test/product_card_test_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/cart_dependency_test_screen.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/providers/theme_provider.dart';
import 'package:dayliz_app/models/address.dart' as models;
import 'package:dayliz_app/domain/entities/address.dart' as domain;
import 'package:dayliz_app/adapters/address_adapter.dart';
import 'package:dayliz_app/services/address_service.dart';
import 'package:flutter/foundation.dart';
// Clean architecture imports for database operations
import 'package:dayliz_app/data/datasources/clean_database_seeder.dart';
import 'package:dayliz_app/data/datasources/clean_database_migrations.dart';
import 'package:dayliz_app/domain/usecases/is_authenticated_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_cart_items_usecase.dart';
import 'package:dayliz_app/domain/usecases/add_to_cart_usecase.dart';
import 'package:dayliz_app/domain/usecases/remove_from_cart_usecase.dart';
import 'package:dayliz_app/presentation/screens/dev/clean_database_seeder_screen.dart';
import 'package:get_it/get_it.dart';
import 'di/dependency_injection.dart' show sl;
// Clean up unused imports
// Clean architecture screens
import 'package:dayliz_app/presentation/screens/product/clean_product_listing_screen.dart';
import 'package:dayliz_app/presentation/screens/product/clean_product_details_screen.dart';
import 'package:dayliz_app/presentation/screens/product/product_feature_testing_screen.dart';
import 'package:dayliz_app/presentation/screens/wishlist/clean_wishlist_screen.dart';
import 'package:dayliz_app/presentation/screens/main/clean_main_screen.dart';
import 'package:dayliz_app/presentation/widgets/common/common_bottom_nav_bar.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_list_screen.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_detail_screen.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_confirmation_screen.dart';
// Import for clean architecture initialization
import 'di/dependency_injection.dart' as di;
import 'navigation/routes.dart';
import 'presentation/screens/auth/clean_login_screen.dart';
import 'presentation/screens/auth/clean_register_screen.dart';
import 'presentation/screens/auth/clean_forgot_password_screen.dart';
import 'presentation/screens/auth/clean_update_password_screen.dart';
import 'presentation/screens/cart/clean_cart_screen.dart';
import 'presentation/screens/checkout/clean_checkout_screen.dart';
import 'presentation/screens/checkout/payment_methods_screen.dart';
import 'presentation/screens/categories/clean_categories_screen.dart';
import 'presentation/screens/clean_demo_screen.dart';
import 'presentation/screens/profile/clean_address_list_screen.dart';
import 'presentation/screens/profile/clean_address_form_screen.dart';
import 'presentation/screens/profile/clean_user_profile_screen.dart';
import 'presentation/screens/profile/clean_preferences_screen.dart';
import 'presentation/screens/search/clean_search_screen.dart';
import 'presentation/screens/search/search_test_screen.dart';
import 'presentation/screens/splash/clean_splash_screen.dart';
import 'presentation/screens/auth/clean_verify_token_handler.dart';

// Define auth states for router redirection
enum AppAuthState { authenticated, unauthenticated, emailVerificationRequired }

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize app configuration
  await AppConfig.init();

  // Initialize authentication components (also initializes cart components)
  try {
    await di.initAuthentication();
    debugPrint('Authentication and cart components initialized successfully');
  } catch (e) {
    debugPrint('Error initializing authentication and cart components: $e');
  }

  // Gracefully initialize clean architecture components
  try {
    await di.initCleanArchitecture();
    debugPrint('Clean architecture initialization successful');

    // TODO: Update repository implementations to use new database features
    // Temporarily disabled due to compatibility issues
    // await di_updated.updateDependencies();
    debugPrint('Clean architecture initialization completed');
  } catch (e) {
    debugPrint('Clean architecture initialization failed: $e');
    // Continue with the app even if clean architecture init fails
  }

  // Test database connections
  await _testDatabaseConnections();

  // Verify cart dependencies are registered
  _verifyCartDependencies();

  // Run database migrations
  try {
    final isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
    final isAuthenticated = await isAuthenticatedUseCase.call();

    if (isAuthenticated) {
      await CleanDatabaseMigrations.instance.runMigrations();
    } else {
      debugPrint('Skipping database migrations: Not authenticated');
    }
  } catch (e) {
    debugPrint('Error running database migrations: $e');
  }

  // Seed database with test data
  if (kDebugMode) {
    try {
      final isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
      final isAuthenticated = await isAuthenticatedUseCase.call();

      if (isAuthenticated) {
        await CleanDatabaseSeeder.instance.seedDatabase();
      } else {
        debugPrint('Skipping database seeding: Not authenticated');
      }
    } catch (e) {
      debugPrint('Error seeding database: $e');
      // Continue with app startup even if seeding fails
    }
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

    // Force clean auth notifier to initialize
    ref.watch(clean_auth.authNotifierProvider);

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

Future<void> _testDatabaseConnections() async {
  try {
    // Test address database connection
    debugPrint('Testing database connections...');
    final addressTableExists = await AddressService.instance.testDatabaseConnection();

    if (addressTableExists) {
      debugPrint('✅ Address table connection successful');
    } else {
      debugPrint('❌ Address table connection failed - check table name and permissions');
    }
  } catch (e) {
    debugPrint('Error testing database connections: $e');
  }
}

/// Verify that cart dependencies are properly registered
void _verifyCartDependencies() {
  try {
    final sl = GetIt.instance;

    // Check if dependencies are registered by name instead of by type
    final isCartItemsRegistered = sl.isRegistered(instanceName: 'GetCartItemsUseCase') ||
                                 sl.isRegistered<GetCartItemsUseCase>();
    final isAddToCartRegistered = sl.isRegistered(instanceName: 'AddToCartUseCase') ||
                                sl.isRegistered<AddToCartUseCase>();
    final isRemoveFromCartRegistered = sl.isRegistered(instanceName: 'RemoveFromCartUseCase') ||
                                     sl.isRegistered<RemoveFromCartUseCase>();

    debugPrint('Cart dependencies check:');
    debugPrint('- GetCartItemsUseCase registered: $isCartItemsRegistered');
    debugPrint('- AddToCartUseCase registered: $isAddToCartRegistered');
    debugPrint('- RemoveFromCartUseCase registered: $isRemoveFromCartRegistered');

    if (!isCartItemsRegistered || !isAddToCartRegistered || !isRemoveFromCartRegistered) {
      debugPrint('⚠️ WARNING: Some cart dependencies are not registered properly!');
    } else {
      debugPrint('✅ All cart dependencies are registered properly');
    }
  } catch (e) {
    debugPrint('Error verifying cart dependencies: $e');
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

/// Router provider for navigation
final routerProvider = Provider<GoRouter>((ref) {
  // Use clean architecture auth state
  final cleanAuthState = ref.watch(clean_auth.authNotifierProvider);

  // Create a navigator observer to handle index updates
  final indexObserver = IndexObserver(ref);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Get the clean architecture auth state
      final isAuthenticated = cleanAuthState.isAuthenticated && cleanAuthState.user != null;

      // Check if the user is on the splash screen
      final isSplashScreen = state.uri.path == '/';

      // Check if the user is on an auth screen or verification screen
      final isAuthScreen =
          state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/reset-password' ||
          state.uri.path.startsWith('/update-password') ||
          state.uri.path == '/clean/login' ||
          state.uri.path == '/clean/register' ||
          state.uri.path == '/clean/forgot-password';

      final isVerificationScreen =
          state.uri.path == '/verify-email' ||
          state.uri.path == '/auth/verify';

      // Don't redirect if handling a verification token
      if (state.uri.path == '/auth/verify') {
        return null;
      }

      // If the user is authenticated but on an auth screen, redirect to clean home
      if (isAuthenticated && isAuthScreen) {
        debugPrint('User is authenticated and on auth screen, redirecting to clean home');
        return '/home';
      }

      // If the user is not authenticated and not on an auth screen or splash screen,
      // redirect to the login screen
      if (!isAuthenticated && !isVerificationScreen && !isAuthScreen && !isSplashScreen) {
        return '/login';
      }

      // No redirect needed
      return null;
    },

    // Setup observers for deep linking and index tracking
    observers: [
      NavigatorObserver(),
      indexObserver,
    ],

    // Enable deep link debugging
    debugLogDiagnostics: true,

    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanSplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
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
      // Redirect legacy home route to clean home
      GoRoute(
        path: '/home-legacy',
        redirect: (_, __) => '/home',
      ),
      // Redirect legacy categories route to clean categories
      GoRoute(
        path: '/categories',
        redirect: (_, __) => '/clean/categories',
      ),
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
      // Redirect legacy cart route to clean cart
      GoRoute(
        path: '/cart',
        redirect: (_, __) => '/clean/cart',
      ),
      // Redirect legacy checkout route to clean checkout
      GoRoute(
        path: '/checkout',
        redirect: (_, __) => '/clean/checkout',
      ),
      // Redirect legacy order confirmation to clean version
      GoRoute(
        path: '/order-confirmation/:orderId',
        redirect: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return '/clean/order-confirmation/$orderId';
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
          // Convert legacy Address to clean architecture Address if needed
          final legacyAddress = state.extra as models.Address?;
          domain.Address? cleanAddress;

          if (legacyAddress != null) {
            cleanAddress = AddressAdapter.toDomain(legacyAddress);
          }

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanAddressFormScreen(address: cleanAddress),
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
            child: const GoogleSignInDebugScreen(),
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
      // Redirect legacy category route to clean category
      GoRoute(
        path: '/category/:id',
        redirect: (context, state) {
          final categoryId = state.pathParameters['id']!;
          return '/clean/category/$categoryId';
        },
      ),
      // Redirect legacy product route to clean product details
      GoRoute(
        path: '/product/:id',
        redirect: (context, state) {
          final productId = state.pathParameters['id']!;
          return '/clean/product/$productId';
        },
      ),
      // Clean Architecture Routes
      GoRoute(
        path: '/clean/category/:id',
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
      GoRoute(
        path: '/clean/product/:id',
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
      GoRoute(
        path: '/dev/settings',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SettingsScreen(),
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
      // Redirect clean-home to root path
      GoRoute(
        path: '/clean-home',
        redirect: (_, __) => '/',
      ),
      // Route handler for clean architecture sub-routes
      GoRoute(
        path: '/clean/:path',
        pageBuilder: (context, state) {
          final path = state.pathParameters['path'] ?? '';
          final args = state.extra;
          final route = '/clean/$path';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: Builder(
              builder: (context) {
                final routeResult = CleanRoutes.generateRoute(
                  RouteSettings(name: route, arguments: args)
                );
                // Get the child from the MaterialPageRoute instead of using builder
                return (routeResult as MaterialPageRoute).builder(context);
              },
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
      // Redirect old clean architecture routes to new standard routes
      GoRoute(
        path: '/clean/login',
        redirect: (_, __) => '/login',
      ),
      GoRoute(
        path: '/clean/register',
        redirect: (_, __) => '/signup',
      ),
      GoRoute(
        path: '/clean/forgot-password',
        redirect: (_, __) => '/reset-password',
      ),
      GoRoute(
        path: '/clean/profile',
        redirect: (_, __) => '/profile',
      ),
      GoRoute(
        path: '/clean/preferences',
        redirect: (_, __) => '/preferences',
      ),
      GoRoute(
        path: '/clean/addresses',
        redirect: (_, __) => '/addresses',
      ),
      // Clean Cart Route - No transition animation
      GoRoute(
        path: '/clean/cart',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCartScreen(),
        ),
      ),
      // Clean Orders Route - No transition animation
      GoRoute(
        path: '/clean/orders',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanOrderListScreen(),
        ),
      ),
      // Clean Checkout Route
      GoRoute(
        path: '/clean/checkout',
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
      // Redirect legacy orders route to clean orders
      GoRoute(
        path: '/orders',
        redirect: (_, __) => '/clean/orders',
      ),
      // Redirect legacy search route to clean search
      GoRoute(
        path: '/search-legacy',
        redirect: (_, __) => '/search',
      ),
      // Redirect legacy search screen to clean search
      GoRoute(
        path: '/search-screen',
        redirect: (_, __) => '/search',
      ),
      // Redirect legacy wishlist routes to clean wishlist
      GoRoute(
        path: '/wishlist-legacy',
        redirect: (_, __) => '/wishlist',
      ),
      // Redirect legacy verify token handler to clean verify token handler
      GoRoute(
        path: '/auth/verify-legacy',
        redirect: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final type = state.uri.queryParameters['type'] ?? 'verify_email';
          return '/verify-email?token=$token&type=$type';
        },
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
      // Search Test Route
      GoRoute(
        path: '/search-test',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SearchTestScreen(),
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
      // Clean Wishlist Route
      GoRoute(
        path: '/clean-wishlist',
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
      // Payment Methods Route
      GoRoute(
        path: '/clean/payment-methods',
        builder: (context, state) {
          // Check if we're coming from checkout
          final isCheckout = state.uri.queryParameters['checkout'] == 'true';
          return PaymentMethodsScreen(isCheckout: isCheckout);
        },
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
      // Main Payment Methods Route
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
      // Clean Categories Screen Route - No transition animation
      GoRoute(
        path: '/clean/categories',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanCategoriesScreen(),
        ),
      ),
      // Product Card Test Screen Route
      GoRoute(
        path: '/clean/test/product-card',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ProductCardTestScreen(),
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
      // Order Confirmation Route
      GoRoute(
        path: '/clean/order-confirmation/:orderId',
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
