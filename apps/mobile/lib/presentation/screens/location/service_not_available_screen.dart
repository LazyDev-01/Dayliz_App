import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/location_gating_provider.dart';
import '../../widgets/common/dayliz_button.dart';
import '../../../core/constants/app_colors.dart';

/// Service not available screen for areas outside delivery zones
class ServiceNotAvailableScreen extends ConsumerStatefulWidget {
  const ServiceNotAvailableScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ServiceNotAvailableScreen> createState() => _ServiceNotAvailableScreenState();
}

class _ServiceNotAvailableScreenState extends ConsumerState<ServiceNotAvailableScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

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
      duration: const Duration(milliseconds: 1200),
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationGatingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Main content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Animation
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: _buildServiceNotAvailableAnimation(),
                          ),
                          
                          SizedBox(height: 40.h),
                          
                          // Content
                          SlideTransition(
                            position: _slideAnimation,
                            child: _buildContent(locationState),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Action buttons
                  SlideTransition(
                    position: _slideAnimation,
                    child: _buildActionButtons(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildServiceNotAvailableAnimation() {
    return Container(
      width: 250.w,
      height: 250.h,
      child: Lottie.asset(
        'assets/animations/service_not_available.json',
        fit: BoxFit.contain,
        repeat: true,
        animate: true,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to a custom illustration
          return Container(
            width: 250.w,
            height: 250.h,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 80.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 16.h),
                Icon(
                  Icons.delivery_dining,
                  size: 60.sp,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(LocationGatingState locationState) {
    return Column(
      children: [
        // Title
        Text(
          'Service Not Available',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 16.h),

        // Subtitle
        Text(
          'We don\'t deliver to your area yet',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: DaylizButton(
        label: 'Change Location',
        onPressed: () {
          // Navigate to location search screen instead of location access
          context.push('/location-search');
        },
        type: DaylizButtonType.primary,
        isFullWidth: true,
        // Removed GPS icon as requested
      ),
    );
  }


}
