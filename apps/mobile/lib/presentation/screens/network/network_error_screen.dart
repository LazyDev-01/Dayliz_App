import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/connectivity_checker.dart';
import '../../widgets/common/dayliz_button.dart';

class NetworkErrorScreen extends StatefulWidget {
  final VoidCallback? onRetrySuccess;

  const NetworkErrorScreen({
    Key? key,
    this.onRetrySuccess,
  }) : super(key: key);

  @override
  State<NetworkErrorScreen> createState() => _NetworkErrorScreenState();
}

class _NetworkErrorScreenState extends State<NetworkErrorScreen>
    with TickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _retryConnection() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
    });

    HapticFeedback.lightImpact();

    try {
      // Check connectivity
      final result = await ConnectivityChecker.checkConnectivityDetailed();
      
      if (result.isConnected) {
        // Connection restored
        HapticFeedback.lightImpact();
        
        if (widget.onRetrySuccess != null) {
          widget.onRetrySuccess!();
        } else {
          // Restart the app
          _restartApp();
        }
      } else {
        // Still no connection
        HapticFeedback.heavyImpact();
        _showNoConnectionSnackBar();
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showErrorSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _restartApp() {
    // This will trigger app restart through main.dart
    SystemNavigator.pop(); // Close app - user will reopen
  }

  void _openNetworkSettings() {
    HapticFeedback.lightImpact();
    // Note: Opening network settings requires platform-specific implementation
    // For now, show guidance
    _showSettingsGuidance();
  }

  void _showNoConnectionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Still no internet connection. Please check your network settings.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: _openNetworkSettings,
        ),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to check connection. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSettingsGuidance() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Network Settings'),
        content: const Text(
          'To fix your internet connection:\n\n'
          '1. Check if WiFi is connected\n'
          '2. Try turning WiFi off and on\n'
          '3. Check mobile data if available\n'
          '4. Move to an area with better signal\n'
          '5. Restart your device if needed',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Network error animation
                    SizedBox(
                      width: 200.w,
                      height: 200.h,
                      child: Lottie.asset(
                        'assets/animations/network_error.json',
                        controller: _animationController,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.wifi_off_rounded,
                            size: 120.sp,
                            color: Colors.grey[400],
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Title
                    Text(
                      'No Internet Connection',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    // Description
                    Text(
                      'Please check your internet connection and try again. Dayliz needs internet to show you fresh products and delivery options.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Action buttons
              Column(
                children: [
                  DaylizButton(
                    label: _isRetrying ? 'Checking Connection...' : 'Try Again',
                    onPressed: _isRetrying ? null : _retryConnection,
                    type: DaylizButtonType.primary,
                    isFullWidth: true,
                    isLoading: _isRetrying,
                    leadingIcon: _isRetrying ? null : Icons.refresh,
                  ),

                  SizedBox(height: 12.h),

                  DaylizButton(
                    label: 'Network Settings',
                    onPressed: _openNetworkSettings,
                    type: DaylizButtonType.secondary,
                    isFullWidth: true,
                    leadingIcon: Icons.settings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
