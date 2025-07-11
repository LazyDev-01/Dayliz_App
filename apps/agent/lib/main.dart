import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import 'core/services/dependency_injection.dart';
import 'presentation/screens/auth/auth_landing_screen.dart';
import 'presentation/screens/auth/agent_login_screen.dart';
import 'presentation/screens/auth/agent_registration_screen.dart';
import 'presentation/screens/main/main_navigation_screen.dart';
import 'presentation/screens/orders/order_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await setupDependencyInjection();

  runApp(const ProviderScope(child: DaylizAgentApp()));
}

class DaylizAgentApp extends StatelessWidget {
  const DaylizAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dayliz Agent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Dayliz green
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Light grey background
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      routerConfig: _router,
    );
  }
}

// Router configuration following the auth flow design
final GoRouter _router = GoRouter(
  initialLocation: '/auth',
  routes: [
    // Authentication Routes
    GoRoute(
      path: '/auth',
      name: 'auth-landing',
      builder: (context, state) => const AuthLandingScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'agent-login',
      builder: (context, state) => const AgentLoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'agent-registration',
      builder: (context, state) => const AgentRegistrationScreen(),
    ),

    // Main App Routes - Using MainNavigationScreen for consistent bottom nav
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/earnings',
      name: 'earnings',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const MainNavigationScreen(initialIndex: 3),
    ),

    // Detail screens that don't need bottom navigation
    GoRoute(
      path: '/order-details/:orderId',
      name: 'order-details',
      builder: (context, state) {
        final orderId = state.pathParameters['orderId']!;
        return OrderDetailsScreen(orderId: orderId);
      },
    ),
  ],
);
