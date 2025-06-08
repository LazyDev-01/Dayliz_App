import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/usecases/usecase.dart';
import '../../providers/location_providers.dart';
import '../../screens/location/location_search_screen.dart';

/// Mandatory bottom sheet for location setup after login
class LocationSetupBottomSheet extends ConsumerStatefulWidget {
  const LocationSetupBottomSheet({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationSetupBottomSheet> createState() => _LocationSetupBottomSheetState();

  /// Show the mandatory location setup bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false, // Cannot dismiss by tapping outside
      enableDrag: false, // Cannot dismiss by dragging down
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const LocationSetupBottomSheet(),
    );
  }
}

class _LocationSetupBottomSheetState extends ConsumerState<LocationSetupBottomSheet> {
  bool _isLoading = false;
  String? _errorMessage;

  /// Handle GPS location detection - silent background process
  Future<void> _handleUseCurrentLocation() async {
    // Disable button during processing
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Request location permission
      final requestPermissionUseCase = ref.read(requestLocationPermissionUseCaseProvider);
      final permissionResult = await requestPermissionUseCase(NoParams());

      await permissionResult.fold(
        (failure) async {
          setState(() {
            _errorMessage = failure.message;
            _isLoading = false;
          });
        },
        (permission) async {
          if (permission == PermissionStatus.granted) {
            // Step 2: Get location coordinates silently
            final getCurrentLocationUseCase = ref.read(getCurrentLocationUseCaseProvider);
            final locationResult = await getCurrentLocationUseCase(NoParams());

            locationResult.fold(
              (failure) {
                setState(() {
                  _errorMessage = failure.message;
                  _isLoading = false;
                });
              },
              (coordinates) {
                // Success: Mark setup as completed and close bottom sheet immediately
                final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
                markCompletedUseCase(NoParams());

                // Close bottom sheet immediately without any success message
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            );
          } else if (permission == PermissionStatus.denied) {
            setState(() {
              _errorMessage = 'Location permission is required to use Dayliz';
              _isLoading = false;
            });
          } else if (permission == PermissionStatus.permanentlyDenied) {
            setState(() {
              _errorMessage = 'Please enable location permission in settings';
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Handle manual location search
  void _handleSearchLocation() {
    // DON'T close bottom sheet - keep it open
    // Navigate to search while keeping bottom sheet in background
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LocationSearchScreen(),
      ),
    );
  }

  /// Handle opening app settings for permissions
  void _handleOpenSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.6, // Maximum 60% of screen height
          minHeight: 200, // Minimum height
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dynamic top section that uses full space (NO HANDLE!)
            _buildDynamicTopSection(),

            // Main content area
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + keyboardHeight),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error Messages (only show errors, no loading or success messages)
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Main Action Buttons
                    Column(
                      children: [
                        // 1. Use Current Location Button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleUseCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 16),
                            label: Text(
                              _isLoading ? 'Getting location...' : 'Use current location',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Divider line
                        _buildDividerLine(),

                        const SizedBox(height: 16),

                        // 2. Search Your Location Button
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleSearchLocation,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.search, size: 16),
                            label: Text(
                              'Search your location',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Settings Button (if permission permanently denied)
                        if (_errorMessage?.contains('settings') == true) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _handleOpenSettings,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange,
                                side: const BorderSide(color: Colors.orange),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Open Settings',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build dynamic top section with user-friendly message and enable button
  Widget _buildDynamicTopSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.06),
            AppColors.primary.withValues(alpha: 0.02),
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
          child: Row(
            children: [
              // User-friendly message (no icon)
              Expanded(
                child: Text(
                  'Please enable location services for seamless delivery experience',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Enable button
              _buildEnableButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build enable button
  Widget _buildEnableButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleUseCurrentLocation,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              'Enable',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build divider line
  Widget _buildDividerLine() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey.shade300,
                  Colors.grey.shade300,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
