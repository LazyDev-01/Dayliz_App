import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../common/dayliz_button.dart';
import '../../providers/location_gating_provider.dart';
import '../../../core/constants/app_colors.dart';

/// Button type for UseCurrentLocationButton
enum UseCurrentLocationButtonType {
  primary,   // Blue/green primary button
  secondary, // Light grey bordered button
}

/// Reusable "Use Current Location" button component
/// Can be used across different location-related screens
class UseCurrentLocationButton extends ConsumerWidget {
  final String? customText;
  final VoidCallback? onLocationDetected;
  final bool isFullWidth;
  final bool showIcon;
  final UseCurrentLocationButtonType buttonType;

  const UseCurrentLocationButton({
    Key? key,
    this.customText,
    this.onLocationDetected,
    this.isFullWidth = true,
    this.showIcon = true,
    this.buttonType = UseCurrentLocationButtonType.primary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationGatingProvider);
    
    // Check if currently detecting location
    final isDetecting = locationState.status == LocationGatingStatus.permissionRequesting ||
                       locationState.status == LocationGatingStatus.locationDetecting ||
                       locationState.status == LocationGatingStatus.zoneValidating;

    return DaylizButton(
      label: _getButtonText(locationState),
      onPressed: isDetecting ? null : () => _handleLocationRequest(ref),
      type: buttonType == UseCurrentLocationButtonType.primary
          ? DaylizButtonType.primary
          : DaylizButtonType.secondary,
      isFullWidth: isFullWidth,
      isLoading: isDetecting,
      leadingIcon: showIcon && !isDetecting ? Icons.my_location : null,
    );
  }

  String _getButtonText(LocationGatingState locationState) {
    if (customText != null && !_isLoading(locationState)) {
      return customText!;
    }

    switch (locationState.status) {
      case LocationGatingStatus.permissionRequesting:
        return 'Requesting Permission...';
      case LocationGatingStatus.locationDetecting:
        return 'Detecting Location...';
      case LocationGatingStatus.zoneValidating:
        return 'Detecting Location...';
      default:
        return customText ?? 'Enable location';
    }
  }

  bool _isLoading(LocationGatingState locationState) {
    return locationState.status == LocationGatingStatus.permissionRequesting ||
           locationState.status == LocationGatingStatus.locationDetecting ||
           locationState.status == LocationGatingStatus.zoneValidating;
  }

  void _handleLocationRequest(WidgetRef ref) async {
    debugPrint('🔘 UseCurrentLocationButton: Button clicked, starting location request...');

    try {
      // Always use the permission dialog approach
      await ref.read(locationGatingProvider.notifier).requestLocationPermissionWithDialog();

      debugPrint('🔘 UseCurrentLocationButton: Location request completed');

      // Call callback if provided
      if (onLocationDetected != null) {
        onLocationDetected!();
      }
    } catch (e) {
      debugPrint('❌ UseCurrentLocationButton: Error during location request - $e');
    }
  }
}

/// Compact version for use in lists or smaller spaces
class UseCurrentLocationButtonCompact extends ConsumerWidget {
  final VoidCallback? onLocationDetected;

  const UseCurrentLocationButtonCompact({
    Key? key,
    this.onLocationDetected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationGatingProvider);
    
    final isDetecting = locationState.status == LocationGatingStatus.permissionRequesting ||
                       locationState.status == LocationGatingStatus.locationDetecting ||
                       locationState.status == LocationGatingStatus.zoneValidating;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (isDetecting)
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          else
            Icon(
              Icons.my_location,
              color: AppColors.primary,
              size: 20.sp,
            ),
          
          SizedBox(width: 12.w),
          
          Expanded(
            child: Text(
              isDetecting ? 'Detecting location...' : 'Use current location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          if (!isDetecting)
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primary,
              size: 16.sp,
            ),
        ],
      ),
    );
  }
}
