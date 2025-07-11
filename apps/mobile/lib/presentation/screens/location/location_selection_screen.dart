import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../providers/location_gating_provider.dart';
import '../../widgets/location/use_current_location_button.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/google_places_service.dart';
import '../../../core/services/real_location_service.dart' show LocationData;
import '../../../core/utils/address_formatter.dart';

import '../../../domain/entities/address.dart';
import '../../../data/datasources/user_profile_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Location selection screen for manual location entry
/// Provides search, current location, and saved addresses options
class LocationSelectionScreen extends ConsumerStatefulWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends ConsumerState<LocationSelectionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Search functionality
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  // Simple address loading
  List<Address> _savedAddresses = [];
  bool _isLoadingAddresses = false;

  // Track if this is manual address selection vs GPS detection
  bool _isManualAddressSelection = false;

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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();

    // Load saved addresses directly
    _loadSavedAddresses();
  }



  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Load saved addresses directly from existing system
  Future<void> _loadSavedAddresses() async {
    setState(() {
      _isLoadingAddresses = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataSource = UserProfileLocalDataSource(sharedPreferences: prefs);

      // Get current user ID from Supabase
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final allAddresses = await dataSource.getUserAddresses(currentUser.id);

        // Remove duplicates based on coordinates and address line
        final uniqueAddresses = <Address>[];
        final seenAddresses = <String>{};

        for (final address in allAddresses) {
          // Create a unique key based on coordinates or address line
          final key = address.latitude != null && address.longitude != null
              ? '${address.latitude}_${address.longitude}'
              : '${address.addressLine1}_${address.city}';

          if (!seenAddresses.contains(key)) {
            seenAddresses.add(key);
            uniqueAddresses.add(address);
          }
        }

        if (mounted) {
          setState(() {
            _savedAddresses = uniqueAddresses;
            _isLoadingAddresses = false;
          });
        }

        debugPrint('📍 LocationSelection: Loaded ${allAddresses.length} total addresses, ${uniqueAddresses.length} unique addresses for user: ${currentUser.email}');

        // Debug: Print each unique address
        for (int i = 0; i < uniqueAddresses.length; i++) {
          final addr = uniqueAddresses[i];
          debugPrint('📍 Address $i: ${addr.addressType} - ${addr.addressLine1}, ${addr.city}');
        }
      } else {
        debugPrint('📍 LocationSelection: No current user found');
        if (mounted) {
          setState(() {
            _savedAddresses = [];
            _isLoadingAddresses = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ LocationSelection: Error loading saved addresses: $e');
      if (mounted) {
        setState(() {
          _savedAddresses = [];
          _isLoadingAddresses = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationGatingProvider);

    // Listen for location state changes and handle navigation
    // Only handle navigation for manual address selection (not GPS-based detection)
    ref.listen<LocationGatingState>(locationGatingProvider, (previous, current) {
      debugPrint('🔄 LocationSelection: State changed from ${previous?.status} to ${current.status}');

      // Only navigate if this is a fresh state change (not a rebuild)
      // AND if this was triggered by manual address selection (not GPS detection)
      if (previous?.status != current.status && _isManualAddressSelection) {
        if (current.status == LocationGatingStatus.completed && current.canProceedToApp) {
          debugPrint('✅ LocationSelection: Navigation to home - manual address selection completed');
          // Use a small delay to ensure state is fully updated
          Future.microtask(() {
            if (mounted) {
              context.go('/home');
            }
          });
        } else if (current.status == LocationGatingStatus.viewingModeReady && current.canProceedToApp) {
          debugPrint('👁️ LocationSelection: Navigation to home - manual address selection viewing mode');
          Future.microtask(() {
            if (mounted) {
              context.go('/home');
            }
          });
        } else if (current.status == LocationGatingStatus.serviceNotAvailable) {
          debugPrint('🚫 LocationSelection: Navigation to service not available - manual address selection');
          Future.microtask(() {
            if (mounted) {
              context.go('/service-not-available');
            }
          });
        } else if (current.status == LocationGatingStatus.failed) {
          debugPrint('❌ LocationSelection: Manual address validation failed: ${current.errorMessage}');
        }
      } else if (previous?.status != current.status) {
        debugPrint('🔄 LocationSelection: State changed but not from manual selection - LocationAccess will handle navigation');
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Search Location',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildContent(context, locationState),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, LocationGatingState locationState) {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search location section
          _buildSearchSection(),
          
          SizedBox(height: 24.h),
          
          // Current location button
          _buildCurrentLocationSection(),
          
          SizedBox(height: 32.h),
          
          // Saved addresses section
          _buildSavedAddressesSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Container(
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _searchFocusNode.hasFocus 
                ? AppColors.primary 
                : Colors.transparent,
              width: 2,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search for area, street name...',
              hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
              suffixIcon: _isSearching
                  ? Padding(
                      padding: EdgeInsets.all(12.w),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
            onChanged: _handleSearchChange,
            onSubmitted: _handleSearchSubmit,
          ),
        ),
        

        // Search results
        if (_searchResults.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _buildSearchResults(),
        ],
      ],
    );
  }

  Widget _buildSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              'Search Results',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              return _buildSearchResultItem(result);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          Icons.location_on,
          color: AppColors.primary,
          size: 20.w,
        ),
      ),
      title: Text(
        result['name'] ?? 'Unknown Location',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        result['formatted_address'] ?? '',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _handleSearchResultSelect(result),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
    );
  }

  Widget _buildCurrentLocationSection() {
    return UseCurrentLocationButton(
      customText: 'Use current location',
      onLocationDetected: () {
        // Location detection handled by provider
        // Navigation handled by listener above
      },
      buttonType: UseCurrentLocationButtonType.secondary, // Use secondary style
    );
  }

  Widget _buildSavedAddressesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bookmark,
                color: AppColors.textSecondary,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Saved Addresses',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isLoadingAddresses) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: 16.h),

          if (_savedAddresses.isEmpty && !_isLoadingAddresses)
            _buildEmptySavedAddresses()
          else
            Expanded(
              child: ListView.separated(
                itemCount: _savedAddresses.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  return _buildSavedAddressItem(_savedAddresses[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySavedAddresses() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bookmark_border,
            color: AppColors.textSecondary,
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            'No Saved Addresses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Save your frequently used addresses for quick access',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressItem(Address address) {
    return InkWell(
      onTap: () => _handleSavedAddressSelect(address),
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.greyLight,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getAddressIcon(address.addressType),
                  style: TextStyle(fontSize: 20.sp),
                ),
              ),
            ),
            
            SizedBox(width: 16.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.addressType?.toUpperCase() ?? 'SAVED ADDRESS',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    AddressFormatter.formatAddress(address, includeCountry: false),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _handleSearchChange(String value) {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    // Debounce search to avoid too many API calls
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      debugPrint('🔍 LocationSelection: Searching for: $query');
      final results = await GooglePlacesService.searchPlaces(query: query);

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('❌ LocationSelection: Search error: $e');
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  void _handleSearchSubmit(String value) {
    if (value.trim().isEmpty) return;
    _performSearch(value);
  }

  /// Get address type icon
  String _getAddressIcon(String? addressType) {
    switch (addressType?.toLowerCase()) {
      case 'home':
        return '🏠';
      case 'work':
      case 'office':
        return '🏢';
      default:
        return '📍';
    }
  }





  Future<void> _handleSavedAddressSelect(Address address) async {
    try {
      debugPrint('📍 LocationSelection: Selected saved address: ${address.addressType}');

      // Mark this as manual address selection
      _isManualAddressSelection = true;

      // Note: Usage count update can be added later if needed

      // Create LocationData from Address
      final locationData = LocationData(
        latitude: address.latitude ?? 0.0,
        longitude: address.longitude ?? 0.0,
        address: '${address.addressLine1}, ${address.city}',
        city: address.city,
        state: address.state,
        postalCode: address.postalCode,
        country: address.country,
        locality: address.landmark,
        subLocality: address.addressLine2,
      );

      // Validate the address coordinates against zones
      await _validateAndProceedWithLocation(locationData);
    } catch (e) {
      debugPrint('❌ LocationSelection: Error selecting saved address: $e');
      _showErrorSnackBar('Failed to select address. Please try again.');
    }
  }

  Future<void> _handleSearchResultSelect(Map<String, dynamic> result) async {
    try {
      debugPrint('📍 LocationSelection: Selected search result: ${result['name']}');

      // Mark this as manual address selection
      _isManualAddressSelection = true;

      // Create LocationData from search result
      final locationData = LocationData(
        latitude: result['lat'],
        longitude: result['lng'],
        address: result['formatted_address'],
        city: 'Unknown City', // Will be filled by geocoding if needed
        state: 'Unknown State',
        postalCode: '000000',
        country: 'India',
        locality: null,
        subLocality: null,
      );

      // Validate and proceed
      await _validateAndProceedWithLocation(locationData);
    } catch (e) {
      debugPrint('❌ LocationSelection: Error selecting search result: $e');
      _showErrorSnackBar('Failed to select location. Please try again.');
    }
  }

  Future<void> _validateAndProceedWithLocation(LocationData locationData) async {
    try {
      debugPrint('🔍 LocationSelection: Validating zone for selected address...');

      // Use the location gating provider to validate the zone properly
      final locationGatingNotifier = ref.read(locationGatingProvider.notifier);

      // Use validateManualAddress which does proper zone validation
      await locationGatingNotifier.validateManualAddress(
        locationData.address,
        locationData.latitude,
        locationData.longitude,
      );

      // The listener in build method will handle navigation based on validation result
    } catch (e) {
      debugPrint('❌ LocationSelection: Zone validation error: $e');
      _showErrorSnackBar('Failed to validate service area. Please try again.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}


