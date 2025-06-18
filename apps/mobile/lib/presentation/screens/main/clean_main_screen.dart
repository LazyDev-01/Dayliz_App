import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../home/clean_home_screen.dart';
import '../categories/clean_categories_screen.dart';
import '../cart/modern_cart_screen.dart';
import '../orders/clean_order_list_screen.dart';
import '../location/optimal_location_setup_modal.dart';
import '../../widgets/common/common_bottom_nav_bar.dart';
import '../../widgets/common/common_drawer.dart';

import '../../providers/location_providers.dart';
import '../../providers/geofencing_providers.dart';
import '../../../core/usecases/usecase.dart';
import '../../../core/models/location_check_result.dart';
import '../../../domain/entities/geofencing/delivery_zone.dart';

/// A clean architecture implementation of the main screen with bottom navigation
class CleanMainScreen extends ConsumerStatefulWidget {
  /// The initial tab index to display
  final int initialIndex;

  const CleanMainScreen({
    Key? key,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  ConsumerState<CleanMainScreen> createState() => _CleanMainScreenState();
}

class _CleanMainScreenState extends ConsumerState<CleanMainScreen> {
  bool _hasShownLocationSetup = false;

  @override
  void initState() {
    super.initState();
    // Perform smart location detection after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performSmartLocationCheck();
    });
  }

  /// Perform smart location detection - check GPS status and validate zone automatically
  Future<void> _performSmartLocationCheck() async {
    if (_hasShownLocationSetup) {
      debugPrint('🔄 [SmartLocation] Already processed location setup, skipping');
      return;
    }

    debugPrint('🚀 [SmartLocation] Starting smart location detection...');

    try {
      // First check if location setup was already completed in a previous session
      final isLocationSetupCompleted = ref.read(isLocationSetupCompletedUseCaseProvider);
      final setupResult = await isLocationSetupCompleted(NoParams());

      final isAlreadyCompleted = setupResult.fold(
        (failure) => false,
        (isCompleted) => isCompleted,
      );

      if (isAlreadyCompleted) {
        debugPrint('✅ [SmartLocation] Location setup already completed in previous session');
        return;
      }

      // Perform background location check
      final locationResult = await _performBackgroundLocationCheck();
      debugPrint('📍 [SmartLocation] Background check result: $locationResult');

      switch (locationResult.status) {
        case LocationStatus.success:
          // Silently mark setup as completed and continue to home
          debugPrint('✅ [SmartLocation] User in delivery zone - marking setup complete');
          final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
          markCompletedUseCase(NoParams());
          // No UI shown - seamless experience
          break;

        case LocationStatus.outsideZone:
          // Show setup screen directly in error state
          debugPrint('❌ [SmartLocation] User outside zone - showing error state');
          _showLocationSetupModalWithError('outside_zone');
          break;

        case LocationStatus.gpsDisabled:
        case LocationStatus.permissionDenied:
        case LocationStatus.lowAccuracy:
        case LocationStatus.timeout:
        case LocationStatus.error:
          // Show setup screen in initial state
          debugPrint('⚠️ [SmartLocation] ${locationResult.status} - showing setup screen');
          _showLocationSetupModal();
          break;
      }
    } catch (e) {
      debugPrint('❌ [SmartLocation] Exception during smart location check: $e');
      _showLocationSetupModal();
    }
  }

  /// Show the optimal location setup modal (NEW HALF-PAGE IMPLEMENTATION)
  void _showOptimalLocationSetup() {
    if (!mounted || _hasShownLocationSetup) return;

    setState(() {
      _hasShownLocationSetup = true;
    });

    // Show half-page modal instead of full screen navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showLocationSetupModal();
      }
    });
  }

  /// Show the location setup as a half-page modal
  void _showLocationSetupModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Mandatory setup - can't dismiss
      enableDrag: false, // Prevent accidental dismissal
      backgroundColor: Colors.transparent,
      builder: (context) => OptimalLocationSetupModal(
        onLocationSetupComplete: () {
          // Reset flag and navigate to home when setup is complete
          setState(() {
            _hasShownLocationSetup = false;
          });
          Navigator.of(context).pop(); // Close modal
          // Home content will now be accessible
        },
      ),
    );
  }

  /// Show location setup modal with specific error state
  void _showLocationSetupModalWithError(String errorType) {
    if (!mounted || _hasShownLocationSetup) return;

    setState(() {
      _hasShownLocationSetup = true;
    });

    // Show modal with error state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: Colors.transparent,
          builder: (context) => OptimalLocationSetupModal(
            initialError: errorType,
            onLocationSetupComplete: () {
              setState(() {
                _hasShownLocationSetup = false;
              });
              Navigator.of(context).pop();
            },
          ),
        );
      }
    });
  }

  /// Perform background location check without showing UI
  Future<LocationCheckResult> _performBackgroundLocationCheck() async {
    try {
      // Check if GPS is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationCheckResult.gpsDisabled();
      }

      // Check permissions
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return LocationCheckResult.permissionDenied();
      }

      // Get coordinates with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Check accuracy
      if (position.accuracy > 100) { // meters
        return LocationCheckResult.lowAccuracy(
          LatLng(position.latitude, position.longitude),
          position.accuracy,
        );
      }

      // Validate zone
      final coordinates = LatLng(position.latitude, position.longitude);
      final detectionResult = await ref.read(zoneDetectionProvider(coordinates).future);

      if (detectionResult.isInZone) {
        return LocationCheckResult.success(coordinates, detectionResult.zone, accuracy: position.accuracy);
      } else {
        return LocationCheckResult.outsideZone(coordinates, accuracy: position.accuracy);
      }

    } on TimeoutException {
      return LocationCheckResult.timeout();
    } catch (e) {
      return LocationCheckResult.error(e.toString());
    }
  }

  // DISABLED: Old bottom sheet implementation
  // void _showLocationSetupBottomSheet() {
  //   if (!mounted || _hasShownLocationSetup) return;
  //
  //   setState(() {
  //     _hasShownLocationSetup = true;
  //   });
  //
  //   // Show the bottom sheet after a brief delay to ensure the screen is fully loaded
  //   Future.delayed(const Duration(milliseconds: 500), () {
  //     if (mounted) {
  //       LocationSetupBottomSheet.show(context).then((_) {
  //         // Reset flag when bottom sheet is dismissed (location setup completed)
  //         setState(() {
  //           _hasShownLocationSetup = false;
  //         });
  //       });
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Watch the current bottom nav index
    final currentIndex = ref.watch(bottomNavIndexProvider);



    return Scaffold(
      drawer: const CommonDrawer(),
      body: _buildScreenForIndex(currentIndex),
      bottomNavigationBar: CommonBottomNavBars.forMainScreen(
        currentIndex: currentIndex,
      ),
    );
  }

  Widget _buildScreenForIndex(int index) {
    switch (index) {
      case 0:
        return const CleanHomeScreen();
      case 1:
        return const CleanCategoriesScreen();
      case 2:
        return const ModernCartScreen(); // Phase 3: Updated to use Modern Cart Screen
      case 3:
        return const CleanOrderListScreen();
      default:
        return const CleanHomeScreen();
    }
  }
}
