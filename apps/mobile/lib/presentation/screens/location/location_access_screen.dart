import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/location_gating_provider.dart';
import '../../widgets/common/dayliz_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';

import '../../widgets/location/use_current_location_button.dart';

/// Location access screen for Smart Location Gating
class LocationAccessScreen extends ConsumerStatefulWidget {
  const LocationAccessScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends ConsumerState<LocationAccessScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _gpsMonitorTimer;

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

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Start animation
    _animationController.forward();

    // Add lifecycle observer for app state changes
    WidgetsBinding.instance.addObserver(this);

    // Initialize location gating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationGatingProvider.notifier).initialize();
      _startGPSMonitoring();
    });
  }



  /// Start monitoring GPS status for auto-detection with battery optimization
  void _startGPSMonitoring() {
    _gpsMonitorTimer?.cancel();

    // Use progressive intervals: start with 2s, then increase to 5s, then 10s
    int checkCount = 0;
    Duration getInterval() {
      if (checkCount < 3) return const Duration(seconds: 2);      // First 6 seconds: check every 2s
      if (checkCount < 8) return const Duration(seconds: 5);      // Next 25 seconds: check every 5s
      return const Duration(seconds: 10);                         // After 31 seconds: check every 10s
    }

    void scheduleNextCheck() {
      checkCount++;
      final interval = getInterval();

      _gpsMonitorTimer = Timer(interval, () async {
        try {
          final locationState = ref.read(locationGatingProvider);

          // Only monitor if we're in a state where GPS is needed
          if (locationState.status == LocationGatingStatus.gpsDisabled ||
              locationState.status == LocationGatingStatus.notStarted) {

            final locationService = LocationService();
            final isGPSEnabled = await locationService.isLocationServiceEnabled();

            if (isGPSEnabled) {
              // GPS is now enabled, start location detection automatically
              ref.read(locationGatingProvider.notifier).requestLocationPermissionWithDialog();
              return; // Stop monitoring
            }

            // Continue monitoring if GPS still disabled
            scheduleNextCheck();
          }
          // Stop monitoring if we're no longer in a GPS-waiting state
        } catch (e) {
          // Continue monitoring even on error, but with longer interval
          scheduleNextCheck();
        }
      });
    }

    // Start the monitoring
    scheduleNextCheck();
  }

  /// Stop GPS monitoring
  void _stopGPSMonitoring() {
    _gpsMonitorTimer?.cancel();
    _gpsMonitorTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, check GPS status
      _checkGPSStatusOnResume();
    }
  }

  /// Check GPS status when app resumes (user might have enabled GPS in settings)
  void _checkGPSStatusOnResume() async {
    try {
      final locationState = ref.read(locationGatingProvider);

      // Only check if we're waiting for GPS
      if (locationState.status == LocationGatingStatus.gpsDisabled) {
        final locationService = LocationService();
        final isGPSEnabled = await locationService.isLocationServiceEnabled();

        if (isGPSEnabled) {
          ref.read(locationGatingProvider.notifier).requestLocationPermissionWithDialog();
        }
      }
    } catch (e) {
      // Error checking GPS on resume - continue silently
    }
  }

  @override
  void dispose() {
    _stopGPSMonitoring();
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationGatingProvider);

    // Listen for state changes and handle navigation
    ref.listen<LocationGatingState>(locationGatingProvider, (previous, current) {
      if (previous?.status != current.status) {
        // Handle navigation when this screen is active (not when LocationSelection is on top)
        if (current.status == LocationGatingStatus.completed && current.canProceedToApp) {
          Future.microtask(() {
            if (mounted) {
              context.go('/home');
            }
          });
        } else if (current.status == LocationGatingStatus.viewingModeReady && current.canProceedToApp) {
          Future.microtask(() {
            if (mounted) {
              context.go('/home');
            }
          });
        } else if (current.status == LocationGatingStatus.serviceNotAvailable) {
          Future.microtask(() {
            if (mounted) {
              context.go('/service-not-available');
            }
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _buildContent(context, locationState),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LocationGatingState locationState) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
      child: Column(
        children: [
          // Header section
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Location animation
                _buildLocationAnimation(locationState),
                
                SizedBox(height: 32.h),
                
                // Title and description
                _buildHeaderText(locationState),
              ],
            ),
          ),
          
          // Action buttons section
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (locationState.isLoading)
                  _buildLoadingSection(locationState)
                else if (locationState.status == LocationGatingStatus.failed)
                  _buildErrorSection(locationState)
                else
                  _buildActionButtons(locationState),
                
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAnimation(LocationGatingState locationState) {
    // For failed state, show icon instead of animation
    if (locationState.status == LocationGatingStatus.failed) {
      return Container(
        width: 200.w,
        height: 200.h,
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.location_off,
          size: 80.sp,
          color: AppColors.textSecondary,
        ),
      );
    }

    // For other states, use animation
    String animationAsset;

    switch (locationState.status) {
      case LocationGatingStatus.permissionRequesting:
      case LocationGatingStatus.locationDetecting:
      case LocationGatingStatus.zoneValidating:
        animationAsset = 'assets/animations/loaction_detection.json';
        break;
      default:
        animationAsset = 'assets/animations/loaction_detection.json';
        break;
    }

    return SizedBox(
      width: 200.w,
      height: 200.h,
      child: Lottie.asset(
        animationAsset,
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200.w,
            height: 200.h,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on,
              size: 80.sp,
              color: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderText(LocationGatingState locationState) {
    String title;
    String description;
    
    switch (locationState.status) {
      case LocationGatingStatus.permissionRequesting:
        title = 'Location Permission Required';
        description = 'We need access to your location to check service availability in your area.';
        break;
      case LocationGatingStatus.locationDetecting:
        title = 'Detecting Your Location';
        description = 'Please wait while we detect your current location...';
        break;
      case LocationGatingStatus.zoneValidating:
        title = 'Detecting Your Location';
        description = 'Please wait while we detect your current location...';
        break;
      case LocationGatingStatus.failed:
        title = 'Location Access Failed';
        // Provide more helpful error messages based on specific error types
        String errorMsg = locationState.errorMessage ?? 'Unable to access your location.';
        if (errorMsg.contains('permanently denied') || errorMsg.contains('deniedForever')) {
          description = 'Location permission is permanently denied. Please go to Settings > Apps > Dayliz > Permissions and enable Location access.';
        } else if (errorMsg.contains('permission')) {
          description = 'Please allow location access and try again.';
        } else if (errorMsg.contains('Network connection required')) {
          description = 'Please connect to WiFi or mobile data and try again.';
        } else if (errorMsg.contains('GPS') || errorMsg.contains('disabled') || errorMsg.contains('Location services')) {
          description = 'Please enable GPS/Location services in your device settings and try again.';
        } else if (errorMsg.contains('timeout') || errorMsg.contains('timed out')) {
          description = 'Location detection is taking longer than usual. Please ensure you have a clear view of the sky and try again.';
        } else if (errorMsg.contains('accuracy') || errorMsg.contains('signal')) {
          description = 'GPS signal is weak. Please move to an open area with clear sky view and try again.';
        } else {
          description = 'Unable to detect your location. Please check your GPS signal and internet connection, then try again.';
        }
        break;
      default:
        title = 'Enable Location Access';
        description = 'To provide you with the best delivery experience, we need to know your location.';
        break;
    }

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 16.h),
        
        Text(
          description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingSection(LocationGatingState locationState) {
    return Column(
      children: [
        const LoadingWidget(color: AppColors.locationBlue),
        SizedBox(height: 16.h),
        Text(
          _getLoadingMessage(locationState.status),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getLoadingMessage(LocationGatingStatus status) {
    switch (status) {
      case LocationGatingStatus.permissionRequesting:
        return 'Requesting location permission...';
      case LocationGatingStatus.locationDetecting:
        return 'Getting your current location...';
      case LocationGatingStatus.zoneValidating:
        return 'Getting your current location...';
      default:
        return 'Please wait...';
    }
  }

  Widget _buildErrorSection(LocationGatingState locationState) {
    final errorMsg = locationState.errorMessage ?? '';
    final isPermanentlyDenied = errorMsg.contains('permanently denied') || errorMsg.contains('deniedForever');
    final isNetworkError = errorMsg.contains('Network connection required');
    final isGPSError = errorMsg.contains('GPS') || errorMsg.contains('Location services');

    return Column(
      children: [
        // Primary action button
        DaylizButton(
          label: isPermanentlyDenied ? 'Open App Settings' : 'Try Again',
          onPressed: () {
            if (isPermanentlyDenied) {
              ref.read(locationGatingProvider.notifier).openAppSettings();
            } else {
              ref.read(locationGatingProvider.notifier).retry();
            }
          },
          type: DaylizButtonType.primary,
          isFullWidth: true,
        ),

        SizedBox(height: 12.h),

        // Secondary action button based on error type
        if (!isPermanentlyDenied) ...[
          if (isNetworkError)
            DaylizButton(
              label: 'Check Network Settings',
              onPressed: () async {
                // Open network settings
                await ref.read(locationGatingProvider.notifier).openLocationSettings();
              },
              type: DaylizButtonType.secondary,
              isFullWidth: true,
              leadingIcon: Icons.wifi,
            )
          else if (isGPSError)
            DaylizButton(
              label: 'Open Location Settings',
              onPressed: () {
                ref.read(locationGatingProvider.notifier).openLocationSettings();
              },
              type: DaylizButtonType.secondary,
              isFullWidth: true,
              leadingIcon: Icons.location_on,
            )
          else if (errorMsg.contains('permission'))
            DaylizButton(
              label: 'Open App Settings',
              onPressed: () {
                ref.read(locationGatingProvider.notifier).openAppSettings();
              },
              type: DaylizButtonType.secondary,
              isFullWidth: true,
              leadingIcon: Icons.settings,
            ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(LocationGatingState locationState) {
    return Column(
      children: [
        // Use Current Location button (reusable component)
        UseCurrentLocationButton(
          customText: 'Enable location',
          onLocationDetected: () {
            // Location detection and navigation handled by the component and provider
          },
        ),

        SizedBox(height: 16.h),

        // Enter Address Manually button
        DaylizButton(
          label: 'Enter Address Manually',
          onPressed: () {
            context.push('/location-selection');
          },
          type: DaylizButtonType.secondary,
          isFullWidth: true,
          leadingIcon: Icons.search,
        ),
      ],
    );
  }


}
