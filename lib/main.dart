import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dayliz_app/screens/splash_screen.dart';
import 'package:dayliz_app/screens/auth/login_screen.dart';
import 'package:dayliz_app/screens/auth/signup_screen.dart';
import 'package:dayliz_app/screens/home/main_screen.dart';
import 'package:dayliz_app/screens/home/address_list_screen.dart';
import 'package:dayliz_app/screens/home/address_form_screen.dart';
import 'package:dayliz_app/screens/cart_screen.dart';
import 'package:dayliz_app/screens/checkout/checkout_screen.dart';
import 'package:dayliz_app/screens/order_confirmation_screen.dart';
import 'package:dayliz_app/theme/app_theme.dart';
import 'package:dayliz_app/providers/theme_provider.dart';
import 'package:dayliz_app/providers/auth_provider.dart';
import 'package:dayliz_app/services/auth_service.dart' hide AuthState;
import 'package:dayliz_app/models/address.dart';
import 'package:dayliz_app/services/address_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dayliz_app/screens/auth/reset_password_screen.dart';
import 'package:dayliz_app/screens/auth/update_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize services
  await AuthService.instance.initialize();
  
  // Test database connections
  await _testDatabaseConnections();
  
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

/// Router provider for navigation
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Get the current auth state
      final isAuthenticated = authState.maybeWhen(
        data: (state) => state == AuthState.authenticated,
        orElse: () => false,
      );
      
      // Check if the user is on the splash screen
      final isSplashScreen = state.uri.path == '/';
      
      // Check if the user is on an auth screen
      final isAuthScreen = 
          state.uri.path == '/login' || 
          state.uri.path == '/signup' ||
          state.uri.path == '/reset-password' ||
          state.uri.path.startsWith('/update-password');
      
      // If the user is authenticated but on an auth screen, redirect to home
      if (isAuthenticated && isAuthScreen) {
        return '/home';
      }
      
      // If the user is not authenticated and not on an auth screen or splash screen,
      // redirect to login
      if (!isAuthenticated && !isAuthScreen && !isSplashScreen) {
        return '/login';
      }
      
      // No redirect needed
      return null;
    },
    
    // Setup observers for deep linking
    observers: [
      NavigatorObserver(),
    ],
    
    // Enable deep link debugging
    debugLogDiagnostics: true,
    
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
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
        path: '/signup',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SignupScreen(),
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
        path: '/reset-password',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ResetPasswordScreen(),
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
        path: '/update-password',
        pageBuilder: (context, state) {
          final accessToken = state.uri.queryParameters['accessToken'];
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: UpdatePasswordScreen(accessToken: accessToken),
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
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const MainScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/cart',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CartScreen(),
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
      GoRoute(
        path: '/checkout',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const CheckoutScreen(),
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
      GoRoute(
        path: '/order-confirmation/:orderId',
        pageBuilder: (context, state) {
          // Extract the order ID from the state parameters
          final orderId = state.pathParameters['orderId']!;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: OrderConfirmationScreen(orderId: orderId),
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
          final isSelectable = state.uri.queryParameters['selectable'] == 'true';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: AddressListScreen(isSelectable: isSelectable),
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
          // Extract the address from the state parameters for editing
          final address = state.extra as Address?;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: AddressFormScreen(address: address),
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
            child: const AddressFormScreen(),
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
        path: '/address/edit/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          // Try to get the address from extra data first
          final address = state.extra as Address?;
          
          // The component will use the ID to fetch the address if not provided
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: AddressFormScreen(address: address, addressId: id),
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

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    
    // Force authNotifierProvider to initialize
    ref.watch(authNotifierProvider);
    
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
