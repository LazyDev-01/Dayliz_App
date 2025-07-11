import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../providers/auth_providers.dart';

/// TEMPORARILY DISABLED - Original splash screen with location detection
/// Simple splash screen with loading indicator
/// Shows app branding and loading state during app initialization
/// Now includes GPS checking for location-first workflow
class SplashScreenOriginal extends ConsumerStatefulWidget {
  const SplashScreenOriginal({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreenOriginal> createState() => _SplashScreenOriginalState();
}

class _SplashScreenOriginalState extends ConsumerState<SplashScreenOriginal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Exit animation controller and animation
  AnimationController? _exitController;
  Animation<double>? _exitAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar style for white background splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for white background
        statusBarBrightness: Brightness.light, // Light status bar for white background
      ),
    );

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 3000), // Extended to 3 seconds
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut), // Extended to 0.8 for longer visibility
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut), // Extended to 0.8 for longer visibility
    ));

    // Start animations
    _animationController.forward();

    // Navigate to main app after splash duration
    _navigateToMainApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _exitController?.dispose();
    super.dispose();
  }

  /// Navigate to main app after initialization
  Future<void> _navigateToMainApp() async {
    // Minimum display time for smooth animation completion - extended to 3 seconds
    const minDisplayTime = Duration(milliseconds: 3000);
    final startTime = DateTime.now();

    try {
      // Wait for essential services to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        // Try to initialize auth notifier safely
        try {
          final authState = ref.read(authNotifierProvider);

          // Wait for auth state to be ready with timeout
          if (authState.isLoading) {
            await Future.any([
              _waitForAuthState(),
              Future.delayed(const Duration(seconds: 5)), // 5 second timeout
            ]);
          }

          // Ensure minimum display time for smooth UX
          final elapsedTime = DateTime.now().difference(startTime);
          if (elapsedTime < minDisplayTime) {
            await Future.delayed(minDisplayTime - elapsedTime);
          }

          if (mounted) {
            final finalAuthState = ref.read(authNotifierProvider);

            // Add smooth fade-out transition before navigation
            await _performSmoothExit();

            if (mounted) {
              if (finalAuthState.isAuthenticated && finalAuthState.user != null) {
                context.go('/home');
              } else {
                context.go('/auth');
              }
            }
          }
        } catch (e) {
          debugPrint('Auth initialization error in splash: $e');
          // Fallback: go to auth screen if there's an error
          await Future.delayed(minDisplayTime);
          if (mounted) {
            await _performSmoothExit();
            if (mounted) {
              context.go('/auth');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Splash navigation error: $e');
      // Ultimate fallback
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  /// Wait for auth state to be ready
  Future<void> _waitForAuthState() async {
    await for (final state in ref.read(authNotifierProvider.notifier).stream) {
      if (!state.isLoading) break;
    }
  }

  /// Perform smooth fade-out transition before navigation
  Future<void> _performSmoothExit() async {
    if (!mounted) return;

    // Create a reverse animation for smooth exit
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 600), // Increased duration for smoother exit
      vsync: this,
    );

    _exitAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController!,
      curve: Curves.easeInOut,
    ));

    // Trigger UI rebuild with exit animation
    setState(() {});

    // Start the exit animation and wait for completion
    await _exitController!.forward().orCancel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Apply exit animation if it exists
          Widget content = Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Lottie.asset(
                  'assets/animations/loaction_detection.json',
                  width: 230, // Increased from 200 to 230
                  height: 230, // Increased from 200 to 230
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to a simple loading indicator if Lottie fails
                    debugPrint('Lottie animation failed to load: $error');
                    return const SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    );
                  },
                ),
              ),
            ),
          );

          // Apply exit animation if it exists
          if (_exitAnimation != null) {
            content = FadeTransition(
              opacity: _exitAnimation!,
              child: content,
            );
          }

          return content;
        },
      ),
    );
  }
}
