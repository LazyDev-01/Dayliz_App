import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/geofencing/delivery_zone.dart';
import '../../providers/auth_providers.dart';
import '../../providers/geofencing_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/common/loading_widget.dart';

/// Optimal single-screen location setup with state management
class OptimalLocationSetupScreen extends ConsumerStatefulWidget {
  const OptimalLocationSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OptimalLocationSetupScreen> createState() => _OptimalLocationSetupScreenState();
}

/// Location setup states for better state management
enum LocationSetupState {
  initial,           // Choose method screen
  detectingGPS,      // GPS detection in progress
  searching,         // Manual search mode
  validating,        // Zone validation in progress
  success,           // Location found and validated
  error,             // Error occurred
}

class _OptimalLocationSetupScreenState extends ConsumerState<OptimalLocationSetupScreen>
    with TickerProviderStateMixin {

  // State management
  LocationSetupState _currentState = LocationSetupState.initial;
  String? _errorMessage;
  String _statusMessage = '';

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data
  List<Address> _savedAddresses = [];
  bool _addressesLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSavedAddresses();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(1.0, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
  }

  /// Load saved addresses for authenticated users
  Future<void> _loadSavedAddresses() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated && authState.user != null && !_addressesLoaded) {
      try {
        await ref.read(userProfileNotifierProvider.notifier).loadAddresses(authState.user!.id);
        final profileState = ref.read(userProfileNotifierProvider);
        setState(() {
          _savedAddresses = profileState.addresses ?? [];
          _addressesLoaded = true;
        });
      } catch (e) {
        setState(() {
          _addressesLoaded = true;
        });
      }
    }
  }

  /// Change state with animation
  void _changeState(LocationSetupState newState, {String? message}) {
    if (_currentState == newState) return;

    setState(() {
      _currentState = newState;
      _statusMessage = message ?? '';
      _errorMessage = null;
    });

    // Animate transition
    _fadeController.reset();
    _fadeController.forward();
  }

  /// Handle GPS location detection
  Future<void> _handleGPSDetection() async {
    _changeState(LocationSetupState.detectingGPS, message: 'Getting your location...');

    try {
      // Step 1: Request location permission
      final requestPermissionUseCase = ref.read(requestLocationPermissionUseCaseProvider);
      final permissionResult = await requestPermissionUseCase(NoParams());

      await permissionResult.fold(
        (failure) async {
          _changeState(LocationSetupState.error);
          setState(() {
            _errorMessage = failure.message;
          });
        },
        (permission) async {
          if (permission == PermissionStatus.granted) {
            // Step 2: Get location coordinates
            final getCurrentLocationUseCase = ref.read(getCurrentLocationUseCaseProvider);
            final locationResult = await getCurrentLocationUseCase(NoParams());

            locationResult.fold(
              (failure) {
                _changeState(LocationSetupState.error);
                setState(() {
                  _errorMessage = failure.message;
                });
              },
              (coordinates) {
                // Convert LocationCoordinates to LatLng
                final latLng = LatLng(coordinates.latitude, coordinates.longitude);
                _validateLocation(latLng);
              },
            );
          } else if (permission == PermissionStatus.denied) {
            _changeState(LocationSetupState.error);
            setState(() {
              _errorMessage = 'Location permission is required to use Dayliz';
            });
          } else if (permission == PermissionStatus.permanentlyDenied) {
            _changeState(LocationSetupState.error);
            setState(() {
              _errorMessage = 'Please enable location permission in settings';
            });
          }
        },
      );
    } catch (e) {
      _changeState(LocationSetupState.error);
      setState(() {
        _errorMessage = 'Something went wrong. Please try again.';
      });
    }
  }

  /// Validate location coordinates
  Future<void> _validateLocation(LatLng coordinates) async {
    _changeState(LocationSetupState.validating, message: 'Checking delivery availability...');

    try {
      final detectionResult = await ref.read(zoneDetectionProvider(coordinates).future);

      if (detectionResult.isInZone) {
        // Success: Mark location setup as completed
        final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
        markCompletedUseCase(NoParams());

        _changeState(LocationSetupState.success, message: 'Location confirmed! Redirecting...');

        // Navigate to home after brief delay
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            context.go('/home');
          }
        });
      } else {
        _changeState(LocationSetupState.error);
        setState(() {
          _errorMessage = 'We don\'t deliver to this area yet, but we\'re expanding soon!';
        });
      }
    } catch (e) {
      _changeState(LocationSetupState.error);
      setState(() {
        _errorMessage = 'Failed to check delivery availability. Please try again.';
      });
    }
  }

  /// Handle manual search
  void _handleManualSearch() {
    _changeState(LocationSetupState.searching);
    _slideController.forward();

    // Auto-focus search bar
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  /// Handle saved address selection
  void _handleSavedAddress(Address address) {
    final coordinates = LatLng(
      address.latitude ?? 25.5138, // Default to Tura coordinates if not available
      address.longitude ?? 90.2065,
    );
    _validateLocation(coordinates);
  }

  /// Go back to initial state
  void _goBackToInitial() {
    _searchController.clear();
    _searchResults.clear();
    _slideController.reset();
    _changeState(LocationSetupState.initial);
  }

  /// Handle app settings for permissions
  void _openAppSettings() {
    openAppSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Handle back navigation based on current state
        if (_currentState == LocationSetupState.searching) {
          _goBackToInitial();
          return false;
        } else if (_currentState == LocationSetupState.error) {
          _goBackToInitial();
          return false;
        } else {
          // For other states, prevent back navigation (location setup is mandatory)
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCurrentStateWidget(),
          ),
        ),
      ),
    );
  }

  /// Build widget based on current state
  Widget _buildCurrentStateWidget() {
    switch (_currentState) {
      case LocationSetupState.initial:
        return _buildInitialState();
      case LocationSetupState.detectingGPS:
        return _buildGPSDetectionState();
      case LocationSetupState.searching:
        return _buildSearchingState();
      case LocationSetupState.validating:
        return _buildValidatingState();
      case LocationSetupState.success:
        return _buildSuccessState();
      case LocationSetupState.error:
        return _buildErrorState();
    }
  }

  /// Build initial state - method selection
  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),

          // Header
          Text(
            'Set Your Location',
            style: AppTextStyles.headline1.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'We need your location to show nearby stores and delivery options',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 48),

          // GPS Option
          _buildOptionButton(
            icon: Icons.my_location,
            title: 'Use Current Location',
            subtitle: 'Automatically detect your location',
            onTap: _handleGPSDetection,
            isPrimary: true,
          ),

          const SizedBox(height: 16),

          // Manual Search Option
          _buildOptionButton(
            icon: Icons.search,
            title: 'Search Your Location',
            subtitle: 'Manually enter your address',
            onTap: _handleManualSearch,
            isPrimary: false,
          ),

          // Saved Addresses Section
          if (_savedAddresses.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Saved Addresses',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildSavedAddressesList(),
            ),
          ] else ...[
            const Spacer(),
          ],
        ],
      ),
    );
  }

  /// Build option button
  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isPrimary ? AppColors.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.white : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isPrimary ? AppColors.primary : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isPrimary ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isPrimary ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isPrimary ? Colors.white : Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Build saved addresses list
  Widget _buildSavedAddressesList() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _savedAddresses.asMap().entries.map((entry) {
          final index = entry.key;
          final address = entry.value;
          final isLast = index == _savedAddresses.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => _handleSavedAddress(address),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.addressType?.isNotEmpty == true
                                  ? '${address.addressType} - ${address.addressLine1}'
                                  : address.addressLine1,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (address.city.isNotEmpty)
                              Text(
                                '${address.city}, ${address.state}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade200,
                  indent: 48,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Build GPS detection state
  Widget _buildGPSDetectionState() {
    return _buildLoadingState(
      icon: Icons.my_location,
      title: 'Getting Your Location',
      message: _statusMessage,
      showCancel: true,
      onCancel: _goBackToInitial,
    );
  }

  /// Build validating state
  Widget _buildValidatingState() {
    return _buildLoadingState(
      icon: Icons.location_searching,
      title: 'Checking Delivery Area',
      message: _statusMessage,
      showCancel: false,
    );
  }

  /// Build success state
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 64,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Location Confirmed!',
              style: AppTextStyles.headline2.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Great! We deliver to your area.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Please try again',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                if (_errorMessage?.contains('permission') == true) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _openAppSettings,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Open Settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goBackToInitial,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build searching state (manual search)
  Widget _buildSearchingState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          // Header with back button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: _goBackToInitial,
                ),
                Expanded(
                  child: Text(
                    'Search Location',
                    style: AppTextStyles.headline3.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 48), // Balance the back button
              ],
            ),
          ),

          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search for your area, landmark, or address...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
                setState(() {});
              },
            ),
          ),

          // Content area
          Expanded(
            child: _savedAddresses.isNotEmpty
                ? _buildSavedAddressesInSearch()
                : _buildEmptySearchState(),
          ),
        ],
      ),
    );
  }

  /// Build saved addresses in search mode
  Widget _buildSavedAddressesInSearch() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saved addresses',
            style: AppTextStyles.bodyLarge.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildSavedAddressesList()),
        ],
      ),
    );
  }

  /// Build empty search state
  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No saved addresses',
              style: AppTextStyles.headline3.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Search for a location to get started',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading state widget
  Widget _buildLoadingState({
    required IconData icon,
    required String title,
    required String message,
    bool showCancel = false,
    VoidCallback? onCancel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.headline3.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const LoadingWidget(),
            if (showCancel && onCancel != null) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}