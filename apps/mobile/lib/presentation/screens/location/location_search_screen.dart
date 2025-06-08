import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/google_places_service.dart';
import '../../../core/usecases/usecase.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/geofencing/delivery_zone.dart';
import '../../providers/auth_providers.dart';
import '../../providers/geofencing_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../widgets/common/loading_widget.dart';

/// Screen for searching location manually using Google Places
class LocationSearchScreen extends ConsumerStatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _searchResults = [];
  bool _addressesLoaded = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    // Load saved addresses
    Future.microtask(() => _loadSavedAddresses());
  }

  /// Load saved addresses for authenticated users
  Future<void> _loadSavedAddresses() async {
    final authState = ref.read(authNotifierProvider);
    if (authState.isAuthenticated && authState.user != null && !_addressesLoaded) {
      try {
        debugPrint('Loading saved addresses for search screen');
        await ref.read(userProfileNotifierProvider.notifier).loadAddresses(authState.user!.id);
        setState(() {
          _addressesLoaded = true;
        });
        debugPrint('Saved addresses loaded for search screen');
      } catch (e) {
        debugPrint('Error loading saved addresses in search screen: $e');
        setState(() {
          _addressesLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Handle search input changes
  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _errorMessage = null;
      });
      return;
    }

    // Debounce search to avoid too many API calls
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query && query.trim().isNotEmpty) {
        _performSearch(query);
      }
    });
  }

  /// Perform Google Places search with cost controls
  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 [LocationSearch] Searching for: "$query"');

      // Use Google Places API with cost controls
      final results = await GooglePlacesService.searchPlaces(
        query: query,
        region: 'IN', // Focus on India
        language: 'en',
      );

      debugPrint('✅ [LocationSearch] Found ${results.length} results');

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Log usage stats for monitoring
      final stats = GooglePlacesService.getUsageStats();
      debugPrint('📊 [Places] Usage: ${stats['requests_last_hour']}/hour, ${stats['cache_entries']} cached');

    } catch (e) {
      debugPrint('❌ [LocationSearch] Search failed: $e');
      setState(() {
        _errorMessage = 'Failed to search locations. Please try again.';
        _isLoading = false;
      });
    }
  }



  /// Handle location selection
  Future<void> _onLocationSelected(Map<String, dynamic> place) async {
    final coordinates = LatLng(
      place['lat'].toDouble(),
      place['lng'].toDouble(),
    );

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Detect zone for selected coordinates
      final detectionResult = await ref.read(zoneDetectionProvider(coordinates).future);

      if (detectionResult.isInZone) {
        // Zone found - mark location setup complete and close all screens
        final markCompletedUseCase = ref.read(markLocationSetupCompletedUseCaseProvider);
        markCompletedUseCase(NoParams());

        // Navigate to home and close all location setup screens
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.go('/home');
        }
      } else {
        // No zone found - show coming soon message
        _showComingSoonDialog(place['formatted_address']);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to check delivery availability. Please try again.';
        _isLoading = false;
      });
    }
  }

  /// Show coming soon dialog when no zone is found
  void _showComingSoonDialog(String address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text('Coming Soon!', style: AppTextStyles.headline3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We don\'t deliver to this area yet, but we\'re expanding soon!',
              style: AppTextStyles.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Selected location: $address',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              'We\'ll notify you as soon as we start delivering to your area.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Try Another Location', style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home'); // Allow browsing even if no delivery
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Browse Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            // Always pop back to bottom sheet (location setup is mandatory)
            Navigator.of(context).pop();
          },
        ),
        // No title - just back button
      ),
      body: Column(
        children: [
          // Reduced Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 44, // Reduced height
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
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
                              _errorMessage = null;
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
              ),
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingWidget());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _performSearch(_searchController.text),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No locations found',
                style: AppTextStyles.headline3.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final place = _searchResults[index];
          return _buildLocationTile(place);
        },
      );
    }

    // Default state - show saved addresses
    return _buildSavedAddresses();
  }

  Widget _buildLocationTile(Map<String, dynamic> place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.location_on, color: AppColors.primary),
        ),
        title: Text(
          place['name'],
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          place['formatted_address'],
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => _onLocationSelected(place),
      ),
    );
  }

  Widget _buildSavedAddresses() {
    // Watch the user profile state to get saved addresses
    final profileState = ref.watch(userProfileNotifierProvider);
    final savedAddresses = profileState.addresses ?? [];

    if (savedAddresses.isEmpty) {
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
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: savedAddresses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final address = entry.value;
                  final isLast = index == savedAddresses.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () => _onSavedAddressSelected(address),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
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
                          indent: 46, // Align with text (icon + spacing)
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle saved address selection
  void _onSavedAddressSelected(Address address) {
    // Create a mock place object from the address for zone detection
    final place = {
      'place_id': 'saved_address_${address.id}',
      'name': address.addressType?.isNotEmpty == true
          ? '${address.addressType} - ${address.addressLine1}'
          : address.addressLine1,
      'formatted_address': '${address.addressLine1}, ${address.city}, ${address.state}',
      'lat': address.latitude ?? 25.5138, // Default to Tura coordinates if not available
      'lng': address.longitude ?? 90.2065,
      'types': ['saved_address'],
    };

    _onLocationSelected(place);
  }
}
