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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize auth service
  await AuthService.instance.initialize();
  
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
          state.uri.path == '/signup';
      
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
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/order-confirmation',
        builder: (context, state) {
          // Extract the order details from the state parameters
          final orderDetails = state.extra as Map<String, dynamic>?;
          return OrderConfirmationScreen(orderDetails: orderDetails ?? {});
        },
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) {
          final isSelectable = state.uri.queryParameters['selectable'] == 'true';
          return AddressListScreen(isSelectable: isSelectable);
        },
      ),
      GoRoute(
        path: '/address-form',
        builder: (context, state) {
          // Extract the address from the state parameters for editing
          final address = state.extra as Address?;
          return AddressFormScreen(address: address);
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
