import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../providers/auth_providers.dart';
import '../../providers/location_gating_provider.dart';
import '../../../core/services/early_location_checker.dart';

/// New splash screen with loading animation Lottie
/// Clean white background with your custom loading_animation.json
class LoadingAnimationSplashScreen extends ConsumerStatefulWidget {
  const LoadingAnimationSplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoadingAnimationSplashScreen> createState() => _LoadingAnimationSplashScreenState();
}

class _LoadingAnimationSplashScreenState extends ConsumerState<LoadingAnimationSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _exitController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _isDataReady = false;
  bool _minTimeReached = false;
  bool _isExiting = false;

  // Location checking state
  bool _isLocationCheckComplete = false;
  LocationReadinessResult? _locationResult;

  @override
  void initState() {
    super.initState();

    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    // Initialize fade-in animation (quick and smooth)
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Initialize exit fade animation (simple fade out)
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 300), // Quick fade out
      vsync: this,
    );

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: Curves.easeIn,
    ));

    // Start immediately
    _fadeController.forward();
    _initializeSplash();
  }

  /// Clean initialization flow with parallel location checking
  void _initializeSplash() {
    // Start all operations in parallel
    _loadAppData();           // Auth data loading
    _startLocationCheck();    // Location checking (NEW)
    _startMinimumTimer();     // Minimum splash duration
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  /// Start location checking in parallel
  void _startLocationCheck() async {
    try {
      _locationResult = await EarlyLocationChecker.checkLocationReadiness();

      if (mounted) {
        _isLocationCheckComplete = true;
        _checkIfReadyToNavigate();
      }
    } catch (e) {

      // Create error result for fallback
      _locationResult = LocationReadinessResult(
        status: LocationReadinessStatus.error,
        errorMessage: 'Location check failed: ${e.toString()}',
      );

      if (mounted) {
        _isLocationCheckComplete = true;
        _checkIfReadyToNavigate();
      }
    }
  }

  /// Start minimum time counter
  void _startMinimumTimer() async {
    await Future.delayed(const Duration(milliseconds: 2000)); // 2s minimum for smooth UX
    if (mounted) {
      _minTimeReached = true;
      _checkIfReadyToNavigate();
    }
  }

  /// Load app data in parallel
  void _loadAppData() async {
    try {
      final authState = ref.read(authNotifierProvider);

      if (authState.isLoading) {
        // Wait for auth with shorter timeout
        await Future.any([
          _waitForAuthState(),
          Future.delayed(const Duration(seconds: 2)),
        ]);
      }

      if (mounted) {
        _isDataReady = true;
        _checkIfReadyToNavigate();
      }
    } catch (e) {
      if (mounted) {
        _isDataReady = true;
        _checkIfReadyToNavigate();
      }
    }
  }

  /// Wait for auth state
  Future<void> _waitForAuthState() async {
    await for (final state in ref.read(authNotifierProvider.notifier).stream) {
      if (!state.isLoading) break;
    }
  }

  /// Check if ready to navigate (auth + location + timer)
  void _checkIfReadyToNavigate() {
    if (_isDataReady && _minTimeReached && _isLocationCheckComplete && !_isExiting && mounted) {
      _performSmoothExit();
    }
  }

  /// Perform smooth fade-out exit transition
  void _performSmoothExit() async {
    if (!mounted || _isExiting) return;

    _isExiting = true;

    try {
      // Quick fade out
      await _exitController.forward();

      // Navigate based on auth and location results
      if (mounted) {
        final authState = ref.read(authNotifierProvider);

        if (authState.isAuthenticated && authState.user != null) {
          // User is authenticated, navigate based on location check result
          _navigateBasedOnLocationResult();
        } else {
          // User not authenticated, go to auth
          context.go('/auth');
        }
      }
    } catch (e) {
      // Fallback navigation
      if (mounted) {
        final authState = ref.read(authNotifierProvider);
        if (authState.isAuthenticated && authState.user != null) {
          _navigateBasedOnLocationResult();
        } else {
          context.go('/auth');
        }
      }
    }
  }

  /// Navigate based on location check results
  void _navigateBasedOnLocationResult() {
    if (_locationResult == null) {
      context.go('/location-access');
      return;
    }

    switch (_locationResult!.status) {
      case LocationReadinessStatus.ready:
        // Update location gating provider to mark location as completed
        try {
          final locationGatingNotifier = ref.read(locationGatingProvider.notifier);
          locationGatingNotifier.markLocationAsCompleted(_locationResult!.locationData!);
        } catch (e) {
          // Continue navigation even if provider update fails
        }

        context.go('/home');
        break;
      case LocationReadinessStatus.outOfService:
        context.go('/service-not-available');
        break;
      case LocationReadinessStatus.needsSetup:
      case LocationReadinessStatus.error:
      case LocationReadinessStatus.timeout:
        context.go('/location-access');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_fadeController, _exitController]),
        builder: (context, child) {
          // Create the main content
          Widget content = Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Loading Animation - Optimized size
                Lottie.asset(
                  'assets/animations/loading_animation.json',
                  width: 260,
                  height: 260,
                  fit: BoxFit.contain,
                  repeat: true,
                  animate: true,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    );
                  },
                ),

                // Text positioned close to animation
                Transform.translate(
                  offset: const Offset(0, -50),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      'Your daily needs, delivered with care.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );

          // Apply fade-in animation
          content = FadeTransition(
            opacity: _fadeAnimation,
            child: content,
          );

          // Apply simple fade-out exit animation
          content = FadeTransition(
            opacity: _exitFadeAnimation,
            child: content,
          );

          return content;
        },
      ),
    );
  }
}
