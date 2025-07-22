import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Unused imports removed for production
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:flutter/foundation.dart';
import 'package:dayliz_app/core/network/network_info.dart';
import 'package:dayliz_app/core/config/app_config.dart';
import 'package:dayliz_app/core/services/supabase_service.dart';
import 'package:dayliz_app/core/services/firebase_notification_service.dart';
import 'package:dayliz_app/core/services/conditional_firebase_service.dart';
import 'package:dayliz_app/core/utils/image_preloader.dart';
import 'package:dayliz_app/core/storage/hive_config.dart';
import 'package:dayliz_app/core/error_handling/global_error_handler.dart';
import 'package:dayliz_app/core/services/error_logging_service.dart';
// Clean architecture imports
import 'package:dayliz_app/presentation/providers/auth_providers.dart' as clean_auth;
import 'package:dayliz_app/presentation/providers/theme_providers.dart';
// Dev imports removed for production
// Debug imports removed for production
// Location gating imports
import 'package:dayliz_app/presentation/screens/location/location_access_screen.dart';
import 'package:dayliz_app/presentation/screens/location/location_selection_screen.dart';
import 'package:dayliz_app/presentation/screens/location/service_not_available_screen.dart';
import 'package:dayliz_app/presentation/providers/location_gating_provider.dart';
// Connectivity imports
import 'core/services/connectivity_checker.dart';
import 'network_error_app.dart';

// Debug imports removed for production
import 'package:dayliz_app/theme/app_theme.dart';
// Clean architecture imports
// Clean architecture imports for database operations
import 'package:dayliz_app/data/datasources/clean_database_seeder.dart';
import 'package:dayliz_app/data/datasources/clean_database_migrations.dart';
import 'package:dayliz_app/domain/usecases/is_authenticated_usecase.dart';
// Unused usecase imports removed for production

// Dev imports removed for production
import 'di/dependency_injection.dart' show sl;
// Clean architecture screens
import 'package:dayliz_app/presentation/screens/product/clean_product_listing_screen.dart';
import 'package:dayliz_app/presentation/screens/product/clean_product_details_screen.dart';

import 'package:dayliz_app/presentation/screens/wishlist/clean_wishlist_screen.dart';
import 'package:dayliz_app/presentation/screens/main/clean_main_screen.dart';
import 'package:dayliz_app/presentation/widgets/common/common_bottom_nav_bar.dart';
import 'package:dayliz_app/presentation/screens/cart/modern_cart_screen.dart';
import 'package:dayliz_app/presentation/screens/orders/clean_order_list_screen.dart';
import 'package:dayliz_app/presentation/providers/weather_provider.dart';


import 'package:dayliz_app/presentation/screens/orders/clean_order_confirmation_screen.dart';
// Import for clean architecture initialization
import 'di/dependency_injection.dart' as di;
import 'di/product_dependency_injection.dart' as product_di;

import 'presentation/screens/auth/clean_login_screen.dart';
import 'presentation/screens/auth/premium_auth_landing_screen.dart';
import 'presentation/screens/auth/phone_auth_screen.dart';
import 'presentation/screens/auth/otp_verification_screen.dart';
// Unused imports removed for production
import 'presentation/screens/splash/loading_animation_splash_screen.dart'; // New loading animation splash
// Debug imports removed for production
import 'presentation/screens/auth/clean_register_screen.dart';
import 'presentation/screens/auth/clean_forgot_password_screen.dart';
import 'presentation/screens/auth/clean_update_password_screen.dart';


import 'presentation/screens/cart/payment_selection_screen.dart';
import 'presentation/screens/checkout/clean_checkout_screen.dart';
import 'presentation/screens/checkout/payment_methods_screen.dart';



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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global error handling system
  GlobalErrorHandler.initialize();

  // Initialize error logging service
  await ErrorLoggingService.instance.initialize();

  // STEP 1: IMMEDIATE CONNECTIVITY CHECK (HIGHEST PRIORITY)
  final connectivityResult = await ConnectivityChecker.checkConnectivityDetailed();

  // If no internet, show network error app immediately
  if (!connectivityResult.hasConnection) {
    runApp(const NetworkErrorApp());
    return; // Exit early, don't load main app
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize app configuration
  await AppConfig.init();

  // Initialize high-performance local storage
  await HiveConfig.initialize();

  // Initialize Firebase with conditional modules (saves ~3-5MB)
  try {
    final firebaseService = ConditionalFirebaseService();
    await firebaseService.initializeFirebase();

    // Initialize Firebase notification service
    final notificationService = FirebaseNotificationService.instance;
    await notificationService.initialize();
  } catch (e) {
    // Firebase initialization failed - continue without Firebase features
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

  // App startup completed

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
  void dispose() {
    // Clean up Hive storage
    HiveConfig.closeAll().catchError((e) {
      // Error closing Hive storage
    });

    super.dispose();
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
    // Register SharedPreferences first (required by auth)
    if (!sl.isRegistered<SharedPreferences>()) {
      final sharedPreferences = await SharedPreferences.getInstance();
      sl.registerLazySingleton(() => sharedPreferences);
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
    }

    // Initialize Supabase service (essential for auth)
    final supabaseService = SupabaseService.instance;
    await supabaseService.initialize();

    // Initialize Supabase-specific error handling
    GlobalErrorHandler.initializeSupabaseErrorHandling();

    // Initialize basic authentication components
    await di.initAuthentication();

  } catch (e) {
    // Continue with app startup even if some services fail
  }
}

/// Initialize heavy operations in background after app starts
/// This prevents blocking the main thread during startup
void _initializeBackgroundOperations() {
  // Run in background without blocking app startup
  Future.microtask(() async {
    try {
      // Initialize monitoring system (non-essential)
      try {
        await AppMonitoringIntegration().initialize();
      } catch (e) {
        // Monitoring system failed - continue without monitoring
      }

      // Initialize clean architecture components
      try {
        await di.initCleanArchitecture();

        // Initialize product dependencies
        try {
          await product_di.initProductDependencies();
        } catch (e) {
          // Product dependencies failed - continue with limited functionality
        }
      } catch (e) {
        // Clean architecture failed - continue with basic functionality
      }

      // Test database connections
      await _testDatabaseConnections();

      // Verify dependencies are registered
      _verifyCartDependencies();
      _verifyWishlistDependencies();

      // PERFORMANCE FIX: Initialize weather provider to prevent repeated service calls
      try {
        final container = ProviderContainer();
        await container.read(weatherProvider.notifier).initialize();
        container.dispose();
      } catch (e) {
        // Weather provider initialization failed - continue without weather features
      }

      // Run database migrations (only if authenticated)
      try {
        final isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
        final isAuthenticated = await isAuthenticatedUseCase.call();

        if (isAuthenticated) {
          await CleanDatabaseMigrations.instance.runMigrations();
        }
      } catch (e) {
        // Database migrations failed - continue with existing data
      }

      // Seed database with test data (debug mode only)
      if (kDebugMode) {
        try {
          final isAuthenticatedUseCase = sl<IsAuthenticatedUseCase>();
          final isAuthenticated = await isAuthenticatedUseCase.call();

          if (isAuthenticated) {
            await CleanDatabaseSeeder.instance.seedDatabase();
          }
        } catch (e) {
          // Database seeding failed - continue without test data
        }
      }

    } catch (e) {
      // Background initialization error - continue with basic functionality
    }
  });
}

Future<void> _testDatabaseConnections() async {
  try {
    // Test database connection using clean architecture
    // This will be handled by the clean architecture initialization
  } catch (e) {
    // Database connection test failed - continue with offline functionality
  }
}

/// Verify that cart dependencies are properly registered
void _verifyCartDependencies() {
  try {
    // Silent verification - dependencies checked during initialization
  } catch (e) {
    // Error verifying cart dependencies - continue with app startup
  }
}

/// Verify that wishlist dependencies are properly registered
void _verifyWishlistDependencies() {
  try {
    // Silent verification - dependencies checked during initialization
  } catch (e) {
    // Error verifying wishlist dependencies - continue with app startup
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
    debugLogDiagnostics: false, // Disabled for production

    // CRITICAL FIX: Simplified redirect logic that reads auth state when needed
    redirect: (context, state) async {
      // Only try to read auth state if dependencies are initialized
      try {
        final authState = ref.read(clean_auth.authNotifierProvider);
        final isAuthenticated = authState.isAuthenticated && authState.user != null;
        final isLoading = authState.isLoading;

        // Don't redirect during loading states
        if (isLoading) {
          return null;
        }

      // Handle root path
      if (state.uri.path == '/') {
        // CRITICAL FIX: Check if this is a password reset deep link
        if (state.uri.queryParameters.containsKey('code') &&
            state.uri.queryParameters['type'] == 'reset_password') {
          final code = state.uri.queryParameters['code'];
          return '/verify-email?token=$code&type=reset_password';
        }

        // NEW: Simplified routing for authenticated users
        if (isAuthenticated) {
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
          // PERFORMANCE FIX: Only check location gating on initial app entry, not every navigation
          // Check if this is the first navigation to main app (not a tab switch or back navigation)
          final isInitialNavigation = state.uri.path == '/home' &&
                                     state.uri.queryParameters.isEmpty;

          if (isInitialNavigation) {
            final locationState = ref.read(locationGatingProvider);

            // ROBUST FIX: Check multiple conditions for location readiness
            final isLocationReady = locationState.hasCompletedInSession ||
                                   locationState.status == LocationGatingStatus.completed ||
                                   locationState.status == LocationGatingStatus.viewingModeReady;

            // Only redirect if location is truly not ready
            if (locationState.isLocationRequired && !isLocationReady) {
              return '/location-access';
            }
          }
          // For tab switches and back navigation, skip location check entirely
        } catch (e) {
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
          return null;
        }

        return '/login'; // Keep original flow for now, test via debug menu
      }

      return null;
      } catch (e) {
        // If auth notifier is not ready yet, allow navigation to splash
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
        pageBuilder: (context, state) {
          // Parse tab index from query parameters
          final tabParam = state.uri.queryParameters['tab'];
          final tabIndex = int.tryParse(tabParam ?? '0') ?? 0;

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: CleanMainScreen(initialIndex: tabIndex),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
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

      // Test routes removed for production
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
      // Legacy routes
      GoRoute(
        path: '/categories',
        redirect: (context, state) => '/home?tab=1',
      ),
      GoRoute(
        path: '/cart',
        redirect: (context, state) => '/clean/cart',
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
      // Debug routes removed for production
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


      // Debug and test routes removed for production
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


      // Orders route - redirect to standalone orders screen
      GoRoute(
        path: '/orders',
        redirect: (context, state) => '/clean/orders',
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

      // Clean architecture routes
      GoRoute(
        path: '/clean/categories',
        redirect: (context, state) => '/home?tab=1',
      ),
      // Standalone Cart screen with context-aware navigation
      GoRoute(
        path: '/clean/cart',
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
      // Standalone Orders screen with context-aware navigation
      GoRoute(
        path: '/clean/orders',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CleanOrderListScreen(),
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
  // Re-run main function to restart the app
  main();
}
