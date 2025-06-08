import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart' as geo;

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

/// Location setup states for better state management
enum LocationSetupState {
  initial,           // Choose method screen
  validating,        // Checking delivery zones (first-time users only)
  searching,         // Manual search mode
  success,           // Location found and validated (first-time users only)
  error,             // Error occurred
}

/// Content widget for optimal location setup - can be used in modal or full screen
class OptimalLocationSetupContent extends ConsumerStatefulWidget {
  final bool isModal;
  final String? initialError;
  final VoidCallback onLocationSetupComplete;

  const OptimalLocationSetupContent({
    Key? key,
    this.isModal = false,
    this.initialError,
    required this.onLocationSetupComplete,
  }) : super(key: key);

  @override
  ConsumerState<OptimalLocationSetupContent> createState() => _OptimalLocationSetupContentState();
}

class _OptimalLocationSetupContentState extends ConsumerState<OptimalLocationSetupContent>
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

  // GPS monitoring
  StreamSubscription<geo.ServiceStatus>? _gpsStatusSubscription;
  Timer? _autoDetectionTimer;
  bool _isAutoDetecting = false;
  bool _hasGPSPermission = false;
  bool _isGPSEnabled = false;
  bool _isFirstTimeUser = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Set initial error state if provided
    if (widget.initialError != null) {
      _currentState = LocationSetupState.error;
      _errorMessage = widget.initialError;
    } else {
      // Start GPS monitoring for automatic detection
      _startGPSMonitoring();
    }

    // Load saved addresses and check user type after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedAddresses();
      _checkUserType();
    });
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
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated && authState.user != null && !_addressesLoaded) {
      try {
        // Use Future.microtask to ensure we're not in the build phase
        await Future.microtask(() async {
          await ref.read(userProfileNotifierProvider.notifier).loadAddresses(authState.user!.id);
        });

        if (mounted) {
          final profileState = ref.read(userProfileNotifierProvider);
          final realAddresses = profileState.addresses ?? [];

          // Add dummy test addresses for easier testing
          final testAddresses = _getDummyTestAddresses();

          setState(() {
            _savedAddresses = [...realAddresses, ...testAddresses];
            _addressesLoaded = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            // Even if loading fails, add dummy addresses for testing
            _savedAddresses = _getDummyTestAddresses();
            _addressesLoaded = true;
          });
        }
        debugPrint('Error loading saved addresses: $e');
      }
    } else {
      // For non-authenticated users, still show dummy addresses for testing
      setState(() {
        _savedAddresses = _getDummyTestAddresses();
        _addressesLoaded = true;
      });
    }
  }

  /// Check if user is first-time user (no saved addresses and no previous setup)
  void _checkUserType() {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated && authState.user != null) {
      // Check if user has completed location setup before
      final isLocationSetupCompleted = ref.read(isLocationSetupCompletedUseCaseProvider);
      isLocationSetupCompleted(NoParams()).then((result) {
        result.fold(
          (failure) {
            // If we can't determine, assume first-time user for better experience
            setState(() {
              _isFirstTimeUser = true;
            });
          },
          (isCompleted) {
            setState(() {
              // First-time user if setup was never completed AND no saved addresses
              _isFirstTimeUser = !isCompleted && _savedAddresses.isEmpty;
            });
            debugPrint('👤 [UserType] First-time user: $_isFirstTimeUser');
          },
        );
      });
    } else {
      // Guest user - treat as first-time
      setState(() {
        _isFirstTimeUser = true;
      });
    }
  }

  /// Get dummy test addresses for easier testing
  List<Address> _getDummyTestAddresses() {
    return [
      // Address INSIDE the zone (should work)
      Address(
        id: 'test-inside-zone',
        userId: 'test-user',
        addressLine1: 'Main Bazaar, Tura',
        addressLine2: 'Near Central Market',
        city: 'Tura',
        state: 'Meghalaya',
        postalCode: '794001',
        country: 'India',
        addressType: 'Test Inside Zone',
        latitude: 25.5140, // Inside zone coordinates
        longitude: 90.2100,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),

      // Address OUTSIDE the zone (should show "notify me")
      Address(
        id: 'test-outside-zone',
        userId: 'test-user',
        addressLine1: 'Shillong Road, Tura',
        addressLine2: 'Outside delivery area',
        city: 'Tura',
        state: 'Meghalaya',
        postalCode: '794002',
        country: 'India',
        addressType: 'Test Outside Zone',
        latitude: 25.5200, // Outside zone coordinates
        longitude: 90.2300,
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
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

  /// Get dynamic status message based on GPS/permission state
  String _getStatusMessage() {
    if (_isAutoDetecting) {
      return _statusMessage.isNotEmpty ? _statusMessage : 'Detecting your location...';
    }

    if (!_isGPSEnabled) {
      return 'Please enable location services for automatic detection';
    }

    if (!_hasGPSPermission) {
      return 'Please grant location permission for automatic detection';
    }

    if (_statusMessage.isNotEmpty) {
      return _statusMessage;
    }

    return ''; // No status message needed
  }

  /// Get status icon based on current state
  IconData _getStatusIcon() {
    if (!_isGPSEnabled) return Icons.location_disabled;
    if (!_hasGPSPermission) return Icons.location_off;
    if (_statusMessage.contains('failed')) return Icons.error_outline;
    if (_statusMessage.contains('accuracy')) return Icons.gps_not_fixed;
    return Icons.info_outline;
  }

  /// Get status color based on current state
  Color _getStatusColor() {
    if (!_isGPSEnabled || !_hasGPSPermission) return Colors.orange.shade600;
    if (_statusMessage.contains('failed')) return Colors.red.shade600;
    if (_statusMessage.contains('accuracy')) return Colors.orange.shade600;
    return Colors.grey.shade600;
  }

  /// Check if enable button should be shown
  bool _shouldShowEnableButton() {
    // Show enable button only when GPS is off or permission is denied
    // Don't show when auto-detecting or when everything is working
    return !_isAutoDetecting && (!_isGPSEnabled || !_hasGPSPermission);
  }

  /// Build compact enable button
  Widget _buildEnableButton() {
    final isGPSIssue = !_isGPSEnabled;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleEnableAction(),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.shade600,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGPSIssue ? Icons.location_on : Icons.security,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Enable',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle enable button action
  void _handleEnableAction() async {
    debugPrint('🔧 [EnableButton] User tapped enable button');

    if (!_isGPSEnabled) {
      // Show GPS settings dialog first
      final shouldOpenSettings = await _showGPSSettingsDialog();
      if (shouldOpenSettings) {
        debugPrint('🔧 [EnableButton] Opening location settings');
        await geo.Geolocator.openLocationSettings();
      }
    } else if (!_hasGPSPermission) {
      // Show permission consent dialog first
      final shouldRequestPermission = await _showLocationPermissionDialog();
      if (shouldRequestPermission) {
        debugPrint('🔧 [EnableButton] Requesting location permission');
        final permission = await geo.Geolocator.requestPermission();

        setState(() {
          _hasGPSPermission = permission == geo.LocationPermission.always ||
                             permission == geo.LocationPermission.whileInUse;
        });

        // If permission granted and GPS is on, start auto-detection
        if (_hasGPSPermission && _isGPSEnabled && !_isAutoDetecting) {
          debugPrint('🚀 [EnableButton] Permission granted - starting auto-detection');
          _startAutomaticGPSDetection();
        }
      }
    }
  }



  /// Validate location coordinates with smart loading states
  Future<void> _validateLocationSmart(LatLng coordinates, {bool isFromSavedAddress = false}) async {
    debugPrint('🧠 [SmartValidation] Starting validation - FirstTime: $_isFirstTimeUser, SavedAddress: $isFromSavedAddress');

    // For saved addresses: always instant (no loading states)
    if (isFromSavedAddress) {
      debugPrint('⚡ [SavedAddress] Direct validation - skipping loading states');
      await _performZoneValidation(coordinates, showLoadingStates: false);
      return;
    }

    // For GPS detection: show loading states only for first-time users
    if (_isFirstTimeUser) {
      debugPrint('👶 [FirstTime] Showing full loading experience');
      _changeState(LocationSetupState.validating, message: 'Checking delivery availability...');
      await _performZoneValidation(coordinates, showLoadingStates: true);
    } else {
      debugPrint('👤 [ReturningUser] Direct validation - minimal loading');
      await _performZoneValidation(coordinates, showLoadingStates: false);
    }
  }

  /// Perform the actual zone validation
  Future<void> _performZoneValidation(LatLng coordinates, {required bool showLoadingStates}) async {
    try {
      final detectionResult = await ref.read(zoneDetectionProvider(coordinates).future);

      debugPrint('✅ [ZoneValidation] Result: isInZone=${detectionResult.isInZone}');
      if (detectionResult.zone != null) {
        debugPrint('✅ [ZoneValidation] Found zone: ${detectionResult.zone!.name}');
      }

      if (detectionResult.isInZone) {
        // Success: Mark location setup as completed
        final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
        markCompletedUseCase(NoParams());

        if (showLoadingStates && _isFirstTimeUser) {
          // Show success animation for first-time users
          _changeState(LocationSetupState.success, message: 'Location confirmed! Redirecting...');
          Future.delayed(const Duration(milliseconds: 2000), () {
            if (mounted) {
              widget.onLocationSetupComplete();
            }
          });
        } else {
          // Instant completion for returning users and saved addresses
          if (mounted) {
            widget.onLocationSetupComplete();
          }
        }
      } else {
        debugPrint('❌ [ZoneValidation] Location outside delivery zones');
        _changeState(LocationSetupState.error);
        setState(() {
          _errorMessage = 'outside_zone'; // Special flag for outside zone error
        });
      }
    } catch (e) {
      debugPrint('❌ [ZoneValidation] Zone detection failed: $e');
      _changeState(LocationSetupState.error);
      setState(() {
        _errorMessage = 'Failed to check delivery availability. Please try again.\n\nError: $e';
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

  /// Handle saved address selection - direct validation without loading states
  void _handleSavedAddress(Address address) {
    final coordinates = LatLng(
      address.latitude ?? 25.5138, // Default to Tura coordinates if not available
      address.longitude ?? 90.2065,
    );

    debugPrint('📍 [SavedAddress] Selected: ${address.addressType} - ${address.addressLine1}');
    debugPrint('📍 [SavedAddress] Coordinates: ${coordinates.latitude}, ${coordinates.longitude}');

    // Direct validation without showing loading states
    _validateLocationSmart(coordinates, isFromSavedAddress: true);
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

  /// Handle notify me button for areas outside delivery zones
  void _handleNotifyMe() {
    // TODO: Implement notify me functionality
    // This could save the user's location/email for future notifications
    debugPrint('🔔 [NotifyMe] User requested notification for area expansion');

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Thanks! We\'ll notify you when we expand to your area.'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Start GPS monitoring for automatic detection
  void _startGPSMonitoring() {
    debugPrint('🚀 [AutoGPS] Starting GPS monitoring for automatic detection');

    // Check initial GPS and permission status
    _checkInitialGPSStatus();

    // Listen for GPS service status changes
    _gpsStatusSubscription = geo.Geolocator.getServiceStatusStream().listen((status) {
      debugPrint('📡 [AutoGPS] GPS status changed: $status');

      if (status == geo.ServiceStatus.enabled && !_isAutoDetecting) {
        debugPrint('✅ [AutoGPS] GPS enabled - starting automatic detection');
        _startAutomaticGPSDetection();
      } else if (status == geo.ServiceStatus.disabled) {
        debugPrint('❌ [AutoGPS] GPS disabled');
        setState(() {
          _isGPSEnabled = false;
          _isAutoDetecting = false;
        });
        _autoDetectionTimer?.cancel();
      }
    });
  }

  /// Check initial GPS and permission status
  Future<void> _checkInitialGPSStatus() async {
    try {
      final isGPSEnabled = await geo.Geolocator.isLocationServiceEnabled();
      final permission = await geo.Geolocator.checkPermission();

      setState(() {
        _isGPSEnabled = isGPSEnabled;
        _hasGPSPermission = permission == geo.LocationPermission.always ||
                           permission == geo.LocationPermission.whileInUse;
      });

      debugPrint('📍 [AutoGPS] Initial status - GPS: $isGPSEnabled, Permission: $_hasGPSPermission');

      // If both GPS and permission are available, start automatic detection
      if (isGPSEnabled && _hasGPSPermission && !_isAutoDetecting) {
        debugPrint('🚀 [AutoGPS] GPS and permission ready - starting automatic detection');
        _startAutomaticGPSDetection();
      }
    } catch (e) {
      debugPrint('❌ [AutoGPS] Error checking initial GPS status: $e');
    }
  }

  /// Start automatic GPS detection with 2-3 second delay for better accuracy
  void _startAutomaticGPSDetection() {
    if (_isAutoDetecting) {
      debugPrint('⚠️ [AutoGPS] Already detecting, skipping');
      return;
    }

    setState(() {
      _isAutoDetecting = true;
      _statusMessage = 'Detecting your location...';
    });

    debugPrint('⏱️ [AutoGPS] Waiting 2-3 seconds for better GPS accuracy');

    // Wait 2-3 seconds for better accuracy
    _autoDetectionTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isAutoDetecting) {
        _performAutomaticGPSDetection();
      }
    });
  }

  /// Perform the actual GPS detection
  Future<void> _performAutomaticGPSDetection() async {
    if (!mounted || !_isAutoDetecting) return;

    debugPrint('📍 [AutoGPS] Performing GPS detection...');

    try {
      // Check permission again
      final permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        debugPrint('🔐 [AutoGPS] Requesting location permission');
        final newPermission = await geo.Geolocator.requestPermission();
        if (newPermission == geo.LocationPermission.denied ||
            newPermission == geo.LocationPermission.deniedForever) {
          debugPrint('❌ [AutoGPS] Permission denied');
          setState(() {
            _isAutoDetecting = false;
            _statusMessage = 'Location permission required';
          });
          return;
        }
      }

      // Get current position
      final position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint('📍 [AutoGPS] Got position: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');

      // Check accuracy
      if (position.accuracy > 100) {
        debugPrint('⚠️ [AutoGPS] Low accuracy (${position.accuracy}m), showing manual options');
        setState(() {
          _isAutoDetecting = false;
          _statusMessage = 'GPS accuracy too low. Please use search option.';
        });
        return;
      }

      // Validate zone
      final coordinates = LatLng(position.latitude, position.longitude);
      await _validateLocationSmart(coordinates, isFromSavedAddress: false);

    } catch (e) {
      debugPrint('❌ [AutoGPS] Detection failed: $e');
      setState(() {
        _isAutoDetecting = false;
        _statusMessage = 'GPS detection failed. Please use search option.';
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _gpsStatusSubscription?.cancel();
    _autoDetectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildCurrentStateWidget(),
    );
  }

  /// Build widget based on current state
  Widget _buildCurrentStateWidget() {
    switch (_currentState) {
      case LocationSetupState.initial:
        return _buildInitialState();
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

  /// Build initial state with full-screen dynamic top container
  Widget _buildInitialState() {
    return Column(
      children: [
        // Dynamic top container that uses full screen space including status bar
        _buildDynamicTopContainer(),

        // Main content area
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isModal ? 20 : 24,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Manual Search Option (Compact size)
                _buildCompactSearchButton(),

                // Saved Addresses Section
                const SizedBox(height: 24),
                Text(
                  'Saved Addresses',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _savedAddresses.isNotEmpty
                      ? _buildSavedAddressesList()
                      : _buildEmptyAddressesState(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build dynamic top container that uses full screen space (including status bar)
  Widget _buildDynamicTopContainer() {
    final hasStatusMessage = _getStatusMessage().isNotEmpty;

    // Don't show container if no status message
    if (!hasStatusMessage) {
      return const SizedBox.shrink();
    }

    // Get the status bar height to extend container to the very top
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      // Extend container to include status bar area
      padding: EdgeInsets.only(top: statusBarHeight),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _isAutoDetecting
              ? [
                  Colors.blue.shade200,  // Darker at very top (status bar area)
                  Colors.blue.shade100,
                  Colors.blue.shade50,
                  Colors.white
                ]
              : [
                  Colors.grey.shade200,  // Darker at very top (status bar area)
                  Colors.grey.shade100,
                  Colors.grey.shade50,
                  Colors.white
                ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(widget.isModal ? 20 : 28),
          bottomRight: Radius.circular(widget.isModal ? 20 : 28),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.isModal ? 20 : 24,
          16, // Top padding after status bar
          widget.isModal ? 20 : 24,
          20, // Bottom padding
        ),
        child: Row(
          children: [
            // Status message (no icon, smaller font)
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

            // Smart Enable Button
            if (_shouldShowEnableButton()) ...[
              const SizedBox(width: 16),
              _buildEnhancedEnableButton(),
            ],
          ],
        ),
      ),
    );
  }

  /// Build enhanced enable button for the top container
  Widget _buildEnhancedEnableButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          onTap: _handleEnableAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isModal ? 12 : 16,
              vertical: widget.isModal ? 8 : 10,
            ),
            child: Text(
              'Enable',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: widget.isModal ? 13 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build compact search button
  Widget _buildCompactSearchButton() {
    return InkWell(
      onTap: _handleManualSearch,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isModal ? 14 : 16,
          vertical: widget.isModal ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Search Location',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: widget.isModal ? 14 : 15,
              ),
            ),
          ],
        ),
      ),
    );
  }



  /// Build saved addresses list (limited to 3 addresses)
  Widget _buildSavedAddressesList() {
    // Limit to 3 addresses for cleaner UI
    final displayAddresses = _savedAddresses.take(3).toList();
    final hasMoreAddresses = _savedAddresses.length > 3;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Address list
          ...displayAddresses.asMap().entries.map((entry) {
            final index = entry.key;
            final address = entry.value;
            final isLast = index == displayAddresses.length - 1 && !hasMoreAddresses;

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


        ],
      ),
    );
  }

  /// Build empty addresses state for main screen
  Widget _buildEmptyAddressesState() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Your saved addresses will appear here',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Add addresses for faster checkout',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }



  /// Build validating state
  Widget _buildValidatingState() {
    return _buildLoadingState(
      icon: Icons.location_searching,
      title: 'Checking delivery...',
      message: 'This will just take a moment',
      showCancel: false,
    );
  }

  /// Build success state
  Widget _buildSuccessState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.isModal ? 20 : 24),
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
              'Perfect!',
              style: AppTextStyles.headline2.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: widget.isModal ? 24 : 28,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We deliver to your area 🎉',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.grey[600],
                fontSize: widget.isModal ? 16 : 18,
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
    // Check if this is an "outside zone" error
    final isOutsideZone = _errorMessage == 'outside_zone';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(widget.isModal ? 20 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isOutsideZone ? Colors.orange.shade50 : Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOutsideZone ? Icons.location_off : Icons.error_outline,
                size: 64,
                color: isOutsideZone ? Colors.orange.shade400 : Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isOutsideZone
                  ? 'Oops! We\'re not in your neighborhood yet'
                  : 'Oops! Something went wrong',
              style: AppTextStyles.headline3.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: widget.isModal ? 20 : 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isOutsideZone
                  ? 'But we\'re working on it!'
                  : _errorMessage ?? 'Please try again',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.grey[600],
                fontSize: widget.isModal ? 14 : 15,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: widget.isModal ? 24 : 32),

            // Action buttons based on error type
            if (isOutsideZone) ...[
              // Notify Me button for outside zone
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleNotifyMe,
                  icon: Icon(
                    Icons.notifications_outlined,
                    size: 18,
                    color: Colors.orange.shade600,
                  ),
                  label: Text(
                    'Notify Me When Available',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.orange.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: widget.isModal ? 12 : 14,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We\'ll let you know as soon as we start delivering in your area',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Try Again button (smaller)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goBackToInitial,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: widget.isModal ? 10 : 12,
                    ),
                  ),
                  child: Text(
                    'Try Different Location',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Regular error buttons
              Row(
                children: [
                  if (_errorMessage?.contains('permission') == true) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openAppSettings,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
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
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
                setState(() {});
              },
            ),
          ),

          // Content area - Show search results or empty state
          Expanded(
            child: _buildEmptySearchState(),
          ),
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
            Icon(Icons.search_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for your location',
              style: AppTextStyles.headline3.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Type your area, landmark, or address above',
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
        padding: EdgeInsets.all(widget.isModal ? 20 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
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

  /// Show GPS settings consent dialog
  Future<bool> _showGPSSettingsDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text(
            'Dayliz needs access to your location to provide accurate delivery services. '
            'This will open your device settings where you can enable location services.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Show location permission consent dialog
  Future<bool> _showLocationPermissionDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
            'Dayliz would like to access your location to provide personalized delivery services. '
            'Your location data will only be used for delivery purposes and will not be shared with third parties.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        );
      },
    ) ?? false;
  }


}
