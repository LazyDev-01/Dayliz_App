import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_colors.dart';
import 'core/services/connectivity_checker.dart';
import 'presentation/screens/network/simple_network_error_screen.dart';
import 'main.dart' as main_app;

/// Minimal app shown when there's no internet connection
/// Lightweight and focused only on connectivity issues
class NetworkErrorApp extends StatelessWidget {
  const NetworkErrorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 12 Pro design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'Dayliz - Network Error',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          home: SimpleNetworkErrorScreen(
            onRetrySuccess: _onConnectionRestored,
          ),
        );
      },
    );
  }

  /// Called when internet connection is restored
  void _onConnectionRestored() {
    // Restart the main app
    main_app.restartApp();
  }

  /// Minimal theme for network error app
  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Inter',
      
      // Text theme
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
      ),
      
      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Snackbar theme
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }
}

/// Connectivity monitoring service for the network error app
class NetworkErrorAppConnectivityMonitor {
  static StreamSubscription<bool>? _connectivitySubscription;
  static VoidCallback? _onConnectionRestored;

  /// Start monitoring connectivity changes
  static void startMonitoring(VoidCallback onConnectionRestored) {
    _onConnectionRestored = onConnectionRestored;
    
    _connectivitySubscription = ConnectivityChecker.connectivityStream().listen(
      (hasConnection) {
        if (hasConnection && _onConnectionRestored != null) {
          // Connection restored, restart main app
          _onConnectionRestored!();
        }
      },
    );
  }

  /// Stop monitoring connectivity changes
  static void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _onConnectionRestored = null;
  }
}
