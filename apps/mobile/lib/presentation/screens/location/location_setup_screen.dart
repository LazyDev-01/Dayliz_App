import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/usecases/usecase.dart';
import '../../providers/location_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/common/loading_widget.dart';

/// Simplified screen for location setup with minimal UI
class LocationSetupScreen extends ConsumerStatefulWidget {
  const LocationSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationSetupScreen> createState() => _LocationSetupScreenState();
}

class _LocationSetupScreenState extends ConsumerState<LocationSetupScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String _statusMessage = '';
  List<String> _savedAddresses = []; // Mock saved addresses for now

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  /// Load saved addresses for authenticated users
  Future<void> _loadSavedAddresses() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated && authState.user != null) {
      // TODO: Load actual saved addresses from repository
      // For now, using mock data
      setState(() {
        _savedAddresses = [
          'Home - 123 Main Street, Tura',
          'Office - 456 Business Park, Tura',
        ];
      });
    }
  }

  /// Handle GPS location detection
  Future<void> _handleUseCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Getting your location...';
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
            // Step 2: Get location coordinates
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
                // Success: Mark setup as completed and navigate to home
                final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
                markCompletedUseCase(NoParams());

                setState(() {
                  _statusMessage = 'Location detected successfully!';
                });

                // Navigate to home after a brief delay
                Future.delayed(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    context.go('/home');
                  }
                });
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

  /// Handle manual location entry
  void _handleEnterLocationManually() {
    context.go('/location-search');
  }

  /// Handle saved address selection
  void _handleSavedAddress(String address) {
    // TODO: Implement saved address selection logic
    // For now, just mark location setup as completed and navigate to home
    final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
    markCompletedUseCase(NoParams());
    context.go('/home');
  }

  /// Handle opening app settings for permissions
  void _handleOpenSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),

              // Status and Error Messages
              if (_isLoading || _errorMessage != null || _statusMessage.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      if (_isLoading) ...[
                        const LoadingWidget(),
                        const SizedBox(height: 12),
                        Text(
                          _statusMessage,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        Container(
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
                      ],
                    ],
                  ),
                ),

              // Main Action Buttons
              Column(
                children: [
                  // 1. Use Current Location Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _handleUseCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.my_location, size: 20),
                      label: Text(
                        'Use current location',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Enter Location Manually Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleEnterLocationManually,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.search, size: 20),
                      label: Text(
                        'Enter location manually',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // 3. Saved Addresses (only if user has any)
                  if (_savedAddresses.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Saved addresses',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._savedAddresses.map((address) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _isLoading ? null : () => _handleSavedAddress(address),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  address,
                                  style: AppTextStyles.bodyMedium,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],

                  // Settings Button (if permission permanently denied)
                  if (_errorMessage?.contains('settings') == true) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
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
                          style: AppTextStyles.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

}
