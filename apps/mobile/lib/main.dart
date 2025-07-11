import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/core/config/app_config.dart';
import 'package:dayliz_app/core/services/supabase_service.dart';
import 'package:dayliz_app/core/services/firebase_notification_service.dart';
import 'package:dayliz_app/core/services/conditional_firebase_service.dart';
import 'package:dayliz_app/core/utils/image_preloader.dart';
import 'package:dayliz_app/core/storage/hive_config.dart';
// Clean architecture imports
import 'package:dayliz_app/presentation/providers/auth_providers.dart' as clean_auth;
import 'package:dayliz_app/presentation/providers/theme_providers.dart';
import 'package:dayliz_app/presentation/screens/dev/clean_settings_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/supabase_connection_test_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/debug_menu_screen.dart';
import 'package:dayliz_app/presentation/screens/debug/clean_google_sign_in_debug_screen.dart';
// Location gating imports
import 'package:dayliz_app/presentation/screens/location/location_access_screen.dart';
import 'package:dayliz_app/presentation/screens/location/location_selection_screen.dart';
import 'package:dayliz_app/presentation/screens/location/service_not_available_screen.dart';
import 'package:dayliz_app/presentation/providers/location_gating_provider.dart';
// Connectivity imports
import 'core/services/connectivity_checker.dart';
import 'network_error_app.dart';

import 'package:dayliz_app/presentation/screens/debug/cart_dependency_test_screen.dart';
import 'package:dayliz_app/theme/app_theme.dart';
// Clean architecture imports
// Clean architecture imports for database operations
import 'package:dayliz_app/data/datasources/clean_database_seeder.dart';
import 'package:dayliz_app/data/datasources/clean_database_migrations.dart';
import 'package:dayliz_app/domain/usecases/is_authenticated_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_cart_items_usecase.dart';
import 'package:dayliz_app/domain/usecases/add_to_cart_usecase.dart';
import 'package:dayliz_app/domain/usecases/remove_from_cart_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_wishlist_products_usecase.dart';

import 'package:dayliz_app/presentation/screens/dev/clean_database_seeder_screen.dart';
import 'di/dependency_injection.dart' show sl;
// Clean architecture screens
import 'package:dayliz_app/presentation/screens/product/clean_product_listing_screen.dart';
import 'package:dayliz_app/presentation/screens/product/clean_product_details_screen.dart';

import 'package:dayliz_app/presentation/screens/wishlist/clean_wishlist_screen.dart';
import 'package:dayliz_app/presentation/screens/main/clean_main_screen.dart';
import 'package:dayliz_app/presentation/widgets/common/common_bottom_nav_bar.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_list_screen.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_confirmation_screen.dart';
// Import for clean architecture initialization
import 'di/dependency_injection.dart' as di;
import 'di/product_dependency_injection.dart' as product_di;

import 'presentation/screens/auth/clean_login_screen.dart';
import 'presentation/screens/auth/premium_auth_landing_screen.dart';
import 'presentation/screens/auth/phone_auth_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
import 'presentation/screens/splash/splash_screen.dart'; // Original (temporarily disabled)
import 'presentation/screens/splash/loading_animation_splash_screen.dart'; // New loading animation splash
import 'presentation/screens/debug/direct_auth_test_screen.dart';
import 'presentation/screens/auth/clean_register_screen.dart';
import 'presentation/screens/auth/clean_forgot_password_screen.dart';
import 'presentation/screens/auth/clean_update_password_screen.dart';

import 'presentation/screens/cart/modern_cart_screen.dart';
import 'presentation/screens/cart/payment_selection_screen.dart';
import 'presentation/screens/checkout/clean_checkout_screen.dart';
import 'presentation/screens/checkout/payment_methods_screen.dart';

import 'presentation/screens/categories/clean_categories_screen.dart';

import 'presentation/screens/profile/clean_address_list_screen.dart';
import 'presentation/screens/profile/clean_address_form_screen.dart';
import 'presentation/screens/profile/clean_user_profile_screen.dart';
import 'presentation/screens/profile/clean_preferences_screen.dart';
import 'presentation/screens/search/enhanced_search_screen.dart';

import 'presentation/screens/notifications/notifications_screen.dart';
import 'presentation/screens/notifications/notification_settings_screen.dart';
import 'presentation/screens/coupons/coupons_screen.dart';

// Splash screen temporarily disabled
// import 'presentation/screens/splash/clean_splash_screen.dart';
import 'presentation/screens/auth/clean_verify_token_handler.dart';
import 'presentation/screens/legal/privacy_policy_screen.dart';
import 'presentation/screens/legal/terms_of_service_screen.dart';
import 'presentation/screens/legal/consent_preferences_screen.dart';
import 'presentation/screens/legal/data_rights_screen.dart';

// Monitoring services
import 'core/services/app_monitoring_integration.dart';

// Define auth states for router redirection
enum AppAuthState { authenticated, unauthenticated, emailVerificationRequired }

Future<void> main() async {
  final appStartTime = DateTime.now();
  debugPrint('🚀 App startup initiated at: ${appStartTime.toIso8601String()}');

  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: IMMEDIATE CONNECTIVITY CHECK (HIGHEST PRIORITY)
  debugPrint('🌐 Checking internet connectivity...');
  final connectivityStartTime = DateTime.now();

  final connectivityResult = await ConnectivityChecker.checkConnectivityDetailed();
  final connectivityDuration = DateTime.now().difference(connectivityStartTime);

  debugPrint('🌐 Connectivity check completed in: ${connectivityDuration.inMilliseconds}ms');
  debugPrint('🌐 Connection status: ${connectivityResult.hasConnection ? "✅ CONNECTED" : "❌ NO INTERNET"}');

  // If no internet, show network error app immediately
  if (!connectivityResult.hasConnection) {
    debugPrint('❌ No internet detected - launching NetworkErrorApp');
    runApp(const NetworkErrorApp());
    return; // Exit early, don't load main app
  }

  debugPrint('✅ Internet available - proceeding with main app initialization');

  // Load environment variables
  final envStartTime = DateTime.now();
  await dotenv.load(fileName: '.env');
  debugPrint('✅ Environment loaded in: ${DateTime.now().difference(envStartTime).inMilliseconds}ms');

  // Initialize app configuration
  final configStartTime = DateTime.now();
  await AppConfig.init();
  debugPrint('✅ App config loaded in: ${DateTime.now().difference(configStartTime).inMilliseconds}ms');

  // Initialize high-performance local storage
  final hiveStartTime = DateTime.now();
  await HiveConfig.initialize();
  debugPrint('✅ Hive storage initialized in: ${DateTime.now().difference(hiveStartTime).inMilliseconds}ms');

  // Initialize Firebase with conditional modules (saves ~3-5MB)
  try {
    final firebaseService = ConditionalFirebaseService();
    await firebaseService.initializeFirebase();
    debugPrint('✅ Conditional Firebase initialized successfully');

    // Initialize Firebase notification service
    final notificationService = FirebaseNotificationService.instance;
    await notificationService.initialize();
    debugPrint('Firebase notification service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  // Initialize only essential services synchronously
  await _initializeEssentialServices();

  // Move heavy operations to background after app starts
  _initializeBackgroundOperations();

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

  final totalStartupTime = DateTime.now().difference(appStartTime);
  debugPrint('🎉 App startup completed in: ${totalStartupTime.inMilliseconds}ms');
  debugPrint('📊 Target: <2000ms | Actual: ${totalStartupTime.inMilliseconds}ms | Status: ${totalStartupTime.inMilliseconds < 2000 ? "✅ FAST" : "⚠️ SLOW"}');

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

    // Initialize auth notifier after essential services are ready
    // This is moved to after dependency injection is complete

    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 11 Pro design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'Dayliz',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        );
      },
    );
  }
}

/// Initialize only essential services that are needed for app startup
/// This keeps the main thread responsive and fast
Future<void> _initializeEssentialServices() async {
  try {
    debugPrint('🚀 Initializing essential services...');

    // Register SharedPreferences first (required by auth)
    if (!sl.isRegistered<SharedPreferences>()) {
      final sharedPreferences = await SharedPreferences.getInstance();
      sl.registerLazySingleton(() => sharedPreferences);
      debugPrint('✅ SharedPreferences registered');
    }

    // Register NetworkInfo (required by auth)
    if (!sl.isRegistered<NetworkInfo>()) {
      if (kIsWeb) {
        sl.registerLazySingleton<NetworkInfo>(() => WebNetworkInfoImpl());
      } else {
        // Register InternetConnectionChecker first for non-web platforms
        if (!sl.isRegistered<InternetConnectionChecker>()) {
          sl.registerLazySingleton(() => InternetConnectionChecker());
        }
        sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
      }
      debugPrint('✅ NetworkInfo registered');
    }

    // Initialize Supabase service (essential for auth)
    final supabaseService = SupabaseService.instance;
    await supabaseService.initialize();
    debugPrint('✅ SupabaseService initialized');

    // Initialize basic authentication components
    await di.initAuthentication();
    debugPrint('✅ Authentication components initialized');

    debugPrint('✅ Essential services initialization completed');
  } catch (e) {
    debugPrint('❌ Error initializing essential services: $e');
    // Continue with app startup even if some services fail
  }
}

/// Initialize heavy operations in background after app starts
/// This prevents blocking the main thread during startup
void _initializeBackgroundOperations() {
  // Run in background without blocking app startup
  Future.microtask(() async {
    try {
      debugPrint('🔄 Starting background initialization...');

      // Initialize monitoring system (non-essential)
      try {
        await AppMonitoringIntegration().initialize();
        debugPrint('✅ Monitoring system initialized');
      } catch (e) {
        debugPrint('❌ Monitoring system failed: $e');
      }

      // Initialize clean architecture components
      try {
        await di.initCleanArchitecture();
        debugPrint('✅ Clean architecture initialized');

        // Initialize product dependencies
        try {
          await product_di.initProductDependencies();
          debugPrint('✅ Product dependencies initialized');
        } catch (e) {
          debugPrint('❌ Product dependencies failed: $e');
        }
      } catch (e) {
        debugPrint('❌ Clean architecture failed: $e');
      }

      // Test database connections
      await _testDatabaseConnections();

      // Verify dependencies are registered
      _verifyCartDependencies();
      _verifyWishlistDependencies();

      // Run database migrations (only if authenticated)
      try {
        final isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
        final isAuthenticated = await isAuthenticatedUseCase.call();

        if (isAuthenticated) {
          debugPrint('🔄 Running database migrations...');
          await CleanDatabaseMigrations.instance.runMigrations();
          debugPrint('✅ Database migrations completed');
        } else {
          debugPrint('⏭️ Skipping database migrations: Not authenticated');
        }
      } catch (e) {
        debugPrint('❌ Error running database migrations: $e');
      }

      // Seed database with test data (debug mode only)
      if (kDebugMode) {
        try {
          final isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
          final isAuthenticated = await isAuthenticatedUseCase.call();

          if (isAuthenticated) {
            debugPrint('🔄 Seeding database with test data...');
            await CleanDatabaseSeeder.instance.seedDatabase();
            debugPrint('✅ Database seeding completed');
          } else {
            debugPrint('⏭️ Skipping database seeding: Not authenticated');
          }
        } catch (e) {
          debugPrint('❌ Error seeding database: $e');
        }
      }

      debugPrint('✅ Background initialization completed');
    } catch (e) {
      debugPrint('❌ Background initialization error: $e');
    }
  });
}

Future<void> _testDatabaseConnections() async {
  try {
    // Test database connection using clean architecture
    debugPrint('Testing database connections...');
    // We'll use the dependency injection container to get the repository
    // This will be handled by the clean architecture initialization
    debugPrint('✅ Database connection will be tested by clean architecture initialization');
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

/// Verify that wishlist dependencies are properly registered
void _verifyWishlistDependencies() {
  try {
    final sl = GetIt.instance;

    // Check if wishlist dependencies are registered
    final isGetWishlistProductsRegistered = sl.isRegistered<GetWishlistProductsUseCase>();

    debugPrint('Wishlist dependencies check:');
    debugPrint('- GetWishlistProductsUseCase registered: $isGetWishlistProductsRegistered');

    if (!isGetWishlistProductsRegistered) {
      debugPrint('⚠️ WARNING: GetWishlistProductsUseCase is not registered properly!');
    } else {
      debugPrint('✅ Wishlist dependencies are registered properly');
    }
  } catch (e) {
    debugPrint('Error verifying wishlist dependencies: $e');
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

/// Router provider for navigation - FIXED to prevent auth state rebuilds
final routerProvider = Provider<GoRouter>((ref) {
  // CRITICAL FIX: Don't watch auth state here - it causes router rebuilds on every auth change
  // Instead, read auth state only when needed in redirect logic

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
    // Set splash screen as initial location
    initialLocation: '/splash',
    debugLogDiagnostics: true, // Enable debug logging to track deep link issues

    // CRITICAL FIX: Simplified redirect logic that reads auth state when needed
    redirect: (context, state) async {
      // Only try to read auth state if dependencies are initialized
      try {
        final authState = ref.read(clean_auth.authNotifierProvider);
        final isAuthenticated = authState.isAuthenticated && authState.user != null;
        final isLoading = authState.isLoading;

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

        // NEW: Simplified routing for authenticated users
        if (isAuthenticated) {
          debugPrint('ROUTER: User authenticated, redirecting to home');
          return '/home';
        }

        return '/login'; // Keep original flow for now, test via debug menu
      }

      // CRITICAL FIX: Never auto-redirect from auth screens
      // Let them handle their own navigation after success/error
      if (state.uri.path == '/auth' ||
          state.uri.path == '/login' ||
          state.uri.path == '/signup' ||
          state.uri.path == '/reset-password' ||
          state.uri.path == '/phone-auth' ||
          state.uri.path == '/otp-verification') {
        debugPrint('ROUTER: On auth screen, allowing manual navigation control');
        return null;
      }



      // GUEST MODE: Define guest-accessible routes (browsing without authentication)
      final guestAccessibleRoutes = [
        '/auth',            // NEW: Premium auth landing screen
        '/login',
        '/signup',
        '/reset-password',
        '/phone-auth',      // NEW: Phone authentication
        '/otp-verification', // NEW: OTP verification

        '/privacy-policy',  // NEW: Privacy Policy screen
        '/terms-of-service', // NEW: Terms of Service screen

        // Location gating routes (accessible without auth)
        '/location-access',
        '/location-selection',
        '/service-not-available',
      ];

      // Check if current path is guest-accessible
      final isGuestAccessible = guestAccessibleRoutes.any((route) =>
        state.uri.path == route || state.uri.path.startsWith(route));

      // LOCATION GATING: Check if location access is required for main app routes
      final mainAppRoutes = ['/home', '/categories', '/cart', '/profile', '/orders'];
      final isMainAppRoute = mainAppRoutes.any((route) => state.uri.path.startsWith(route));

      if (isMainAppRoute) {
        try {
          // Location checking is now handled in splash screen
          // Only check if location gating was completed in current session
          final locationState = ref.read(locationGatingProvider);
          debugPrint('🎯 ROUTER: Location gating check - ${locationState.toString()}');

          // If location gating is required and not completed, redirect to location access
          if (locationState.isLocationRequired && !locationState.hasCompletedInSession) {
            debugPrint('🎯 ROUTER: Location gating required, redirecting to location-access');
            return '/location-access';
          }
        } catch (e) {
          debugPrint('🎯 ROUTER: Location gating provider not ready: $e');
          // If location provider is not ready, allow navigation (fail-safe)
        }
      }

      // Allow authenticated users to access all routes

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
        return '/login'; // Keep original flow for now, test via debug menu
      }

      return null;
      } catch (e) {
        // If auth notifier is not ready yet, allow navigation to splash
        debugPrint('ROUTER: Auth notifier not ready yet, allowing navigation: $e');
        if (state.uri.path == '/splash' || state.uri.path == '/auth') {
          return null;
        }
        return '/splash';
      }
    },

    // Setup observers for deep linking and index tracking
    observers: [
      NavigatorObserver(),
      indexObserver,
    ],

    // Deep link debugging disabled to reduce noise

    routes: [
      // Splash Screen Route - App Entry Point (NEW LOADING ANIMATION)
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoadingAnimationSplashScreen(), // Using new loading animation splash
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // CRITICAL FIX: Root path now handled by redirect logic only
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          // This should never be reached due to redirect logic
          // But provide a fallback just in case
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const CleanLoginScreen(), // Keep original for now
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
      // Premium Auth Landing Screen (New Entry Point)
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PremiumAuthLandingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Location Access Screen (Smart Location Gating)
      GoRoute(
        path: '/location-access',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LocationAccessScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      // Location Selection Screen (Manual Address Entry)
      GoRoute(
        path: '/location-selection',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LocationSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return child; // No transition animation
          },
        ),
      ),

      // Service Not Available Screen
      GoRoute(
        path: '/service-not-available',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ServiceNotAvailableScreen(),
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

      // Phone Authentication Route
      GoRoute(
        path: '/phone-auth',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PhoneAuthScreen(),
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

      // OTP Verification Route
      GoRoute(
        path: '/otp-verification',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final phoneNumber = extra?['phoneNumber'] as String? ?? '';
          final countryCode = extra?['countryCode'] as String? ?? '+1';

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: OtpVerificationScreen(
              phoneNumber: phoneNumber,
              countryCode: countryCode,
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

      // DIRECT TESTING ROUTES (Remove after testing)
      GoRoute(
        path: '/test-premium-auth',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PremiumAuthLandingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      GoRoute(
        path: '/test-phone-auth',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PhoneAuthScreen(),
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

      GoRoute(
        path: '/test-otp',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const OtpVerificationScreen(
            phoneNumber: '+1 (555) 123-4567',
            countryCode: '+1',
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
      // Cart route (Phase 3: Updated to use Modern Cart Screen)
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const ModernCartScreen(),
        ),
      ),
      // Modern Cart route (new UI design)
      GoRoute(
        path: '/modern-cart',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ModernCartScreen(),
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
      // Debug menu screen (alternative route)
      GoRoute(
        path: '/clean/debug',
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

      // DIRECT ACCESS ROUTES FOR TESTING (REMOVE AFTER TESTING)
      GoRoute(
        path: '/direct-auth-test',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const DirectAuthTestScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      GoRoute(
        path: '/test-premium-auth',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PremiumAuthLandingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),

      GoRoute(
        path: '/test-phone-auth',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PhoneAuthScreen(),
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

      GoRoute(
        path: '/test-otp',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const OtpVerificationScreen(
            phoneNumber: '+1 (555) 123-4567',
            countryCode: '+1',
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


      // Orders route
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: state.pageKey,
          child: const CleanOrderListScreen(),
        ),
      ),

      // Search Route - Enhanced Search with Context Support
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) {
          // Extract context parameters from query parameters
          final contextSubcategoryId = state.uri.queryParameters['subcategoryId'];
          final contextCategoryId = state.uri.queryParameters['categoryId'];
          final contextName = state.uri.queryParameters['contextName'];
          final initialQuery = state.uri.queryParameters['q'];

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: EnhancedSearchScreen(
              contextSubcategoryId: contextSubcategoryId,
              contextCategoryId: contextCategoryId,
              contextName: contextName,
              initialQuery: initialQuery,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          );
        },
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

      // Coupons Route
      GoRoute(
        path: '/coupons',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CouponsScreen(),
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

      // Payment Selection Route (for cart checkout flow)
      GoRoute(
        path: '/payment-selection',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PaymentSelectionScreen(),
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
          child: const ModernCartScreen(),
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
      // Clean architecture product details route
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


      // Notifications routes
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NotificationsScreen(),
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
      GoRoute(
        path: '/notifications/settings',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const NotificationSettingsScreen(),
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

      // Legal screens routes
      GoRoute(
        path: '/privacy-policy',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/terms-of-service',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const TermsOfServiceScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/consent-preferences',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ConsentPreferencesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),

      GoRoute(
        path: '/data-rights',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const DataRightsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
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
      // FIXED: Standardized route handling with proper mapping
      switch (routeName) {
        case '/home':
        case '/clean-home': // Legacy support
          ref.read(bottomNavIndexProvider.notifier).state = 0;
          break;
        case '/categories':
        case '/clean/categories':
          ref.read(bottomNavIndexProvider.notifier).state = 1;
          break;
        case '/cart':
        case '/clean/cart':
          ref.read(bottomNavIndexProvider.notifier).state = 2;
          break;
        case '/orders':
          ref.read(bottomNavIndexProvider.notifier).state = 3;
          break;
        case '/profile':
          // Profile is now in the top app bar, not in bottom navigation
          break;
        default:
          // Don't update index for other routes to maintain current state
          break;
      }
    }
  }
}

/// Global function to restart the app when connectivity is restored
void restartApp() {
  debugPrint('🔄 Restarting app due to connectivity restoration...');

  // Re-run main function to restart the app
  main();
}
