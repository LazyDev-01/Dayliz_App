import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../services/image_preloader.dart';
import '../../providers/auth_providers.dart';

/// Clean architecture implementation of the splash screen
class CleanSplashScreen extends ConsumerStatefulWidget {
  const CleanSplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CleanSplashScreen> createState() => _CleanSplashScreenState();
}

class _CleanSplashScreenState extends ConsumerState<CleanSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    // Start preloading images as soon as splash screen appears
    // for better initial experience when user gets to home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      imagePreloader.preloadKeyImages(context);
    });

    // Start app initialization
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Simulate initialization delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      
      // Check auth state and navigate
      _checkAuthAndNavigate();
    }
  }

  void _checkAuthAndNavigate() {
    // Check authentication status using clean architecture auth provider
    final authState = ref.read(authNotifierProvider);
    final isAuthenticated = authState.isAuthenticated && authState.user != null;

    if (isAuthenticated) {
      // Navigate to home if authenticated
      context.go('/home');
    } else {
      // Navigate to login if not authenticated
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_grocery_store,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              
              // App name
              const Text(
                'Dayliz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              const Text(
                'Groceries delivered in minutes',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
