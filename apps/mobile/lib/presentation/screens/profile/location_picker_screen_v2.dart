import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../widgets/common/unified_app_bar.dart';

import '../../../core/services/location_service.dart';
import '../../widgets/address/address_form_bottom_sheet.dart';
import '../../widgets/common/deferred_google_map_widget.dart';
import 'location_search_screen.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  String _currentAddress = 'Detecting location...';
  String _currentArea = 'Please wait...';
  LocationData? _currentLocationData;
  final LocationService _locationService = LocationService();
  bool _isLocationDetected = false;
  bool _isCheckingGPS = true; // Start as true to show loading initially
  bool _isGPSDisabled = false;

  @override
  void initState() {
    super.initState();
    _checkGPSAndRequestLocation();
  }

  /// Initialize location detection without GPS service requests
  Future<void> _checkGPSAndRequestLocation() async {
    setState(() {
      _isCheckingGPS = true;
    });

    try {
      // Check if GPS is enabled (no dialog, just check)
      final isGPSEnabled = await _locationService.isLocationServiceEnabled();

      if (!isGPSEnabled) {
        setState(() {
          _currentAddress = 'Unable to detect location';
          _currentArea = 'Please search manually or enable GPS';
          _isCheckingGPS = false;
          _isGPSDisabled = true;
        });
        return;
      }

      // Check permissions (request if needed)
      final permission = await _locationService.checkLocationPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await _locationService.requestLocationPermission();
        if (newPermission == LocationPermission.denied ||
            newPermission == LocationPermission.deniedForever) {
          setState(() {
            _currentAddress = 'Location permission required';
            _currentArea = 'Please grant location permission';
            _isCheckingGPS = false;
          });
          return;
        }
      }

      // Get current location
      await _getCurrentLocation();

    } catch (e) {
      debugPrint('❌ Error checking GPS: $e');
      setState(() {
        _currentAddress = 'Location error';
        _currentArea = 'Please try again';
        _isCheckingGPS = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationData? locationData = await _locationService.getCurrentLocationWithAddress();
      if (locationData != null) {
        setState(() {
          _currentLocationData = locationData;
          _currentAddress = _formatMainAddress(locationData);
          _currentArea = _formatDetailedAddress(locationData);
          _isLocationDetected = true;
          _isCheckingGPS = false;
          _isGPSDisabled = false; // Reset GPS disabled state on successful location
        });
      } else {
        setState(() {
          _currentAddress = 'Unable to detect location';
          _currentArea = 'Please search manually';
          _isCheckingGPS = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to detect location';
        _currentArea = 'Please search manually';
        _isCheckingGPS = false;
      });
    }
  }

  /// Format address for clean display like reference app
  String _formatMainAddress(LocationData locationData) {
    // Extract the main location name (area/locality)
    if (locationData.subLocality != null && locationData.subLocality!.isNotEmpty) {
      return locationData.subLocality!;
    } else if (locationData.locality != null && locationData.locality!.isNotEmpty) {
      return locationData.locality!;
    } else {
      // Fallback: extract first meaningful part from full address
      final addressParts = locationData.address.split(', ');
      if (addressParts.isNotEmpty) {
        return addressParts[0].trim();
      }
      return 'Selected Location';
    }
  }

  /// Format detailed address for subtitle
  String _formatDetailedAddress(LocationData locationData) {
    final parts = <String>[];

    // Add area/locality if different from main address
    final mainAddress = _formatMainAddress(locationData);
    if (locationData.subLocality != null &&
        locationData.subLocality!.isNotEmpty &&
        locationData.subLocality! != mainAddress) {
      parts.add(locationData.subLocality!);
    }

    // Add city
    if (locationData.city.isNotEmpty && locationData.city != 'Unknown City') {
      parts.add(locationData.city);
    }

    // Add state
    if (locationData.state.isNotEmpty && locationData.state != 'Unknown State') {
      parts.add(locationData.state);
    }

    // Add postal code if available
    if (locationData.postalCode.isNotEmpty && locationData.postalCode != '000000') {
      parts.add(locationData.postalCode);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Location detected';
  }

  /// Open location search screen
  void _openLocationSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          onLocationSelected: (location) {
            // Update with selected location from search
            setState(() {
              // Create LocationData from search result if coordinates are available
              if (location['latitude'] != null && location['longitude'] != null) {
                _currentLocationData = LocationData(
                  latitude: (location['latitude'] as num).toDouble(),
                  longitude: (location['longitude'] as num).toDouble(),
                  address: location['address'] ?? 'Selected location',
                  city: location['city'] ?? 'Unknown City',
                  state: location['state'] ?? 'Unknown State',
                  postalCode: location['postalCode'] ?? '000000',
                  country: location['country'] ?? 'India',
                  locality: location['locality'],
                  subLocality: location['subLocality'],
                  thoroughfare: location['thoroughfare'],
                  subThoroughfare: location['subThoroughfare'],
                );

                // Use formatted address display
                _currentAddress = _formatMainAddress(_currentLocationData!);
                _currentArea = _formatDetailedAddress(_currentLocationData!);
              } else {
                // Fallback for search results without coordinates
                _currentAddress = location['address'] ?? 'Selected location';
                _currentArea = location['area'] ?? 'Manual selection';
              }

              _isLocationDetected = true;
              _isGPSDisabled = false; // Reset GPS disabled state
            });
          },
        ),
      ),
    ).then((_) {
      // Add a small delay when returning to prevent rendering glitches
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            // Force a rebuild to ensure proper map rendering
          });
        }
      });
    });
  }





  void _openAddressForm() {
    AddressFormBottomSheet.show(
      context,
      locationData: _currentLocationData, // Pass GPS data to form
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: UnifiedAppBars.withBackButton(
        title: 'Select Delivery Location',
        fallbackRoute: '/profile/addresses',
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Color(0xFF374151), // Consistent grey color
            ),
            onPressed: _openLocationSearch,
            tooltip: 'Search location',
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // Important: Allow screen to resize when keyboard appears
      body: Column(
        children: [
          // GPS Disabled Notification Bar
          if (_isGPSDisabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border(
                  bottom: BorderSide(
                    color: Colors.orange[200]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_off,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GPS is disabled. Please enable GPS in settings or use search to find your location.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Google Maps Container - Flexible to shrink when keyboard appears
          Expanded(
            flex: 3, // Takes 3/4 of available space
            child: LazyGoogleMapWidget(
              height: double.infinity,
              initialLocation: _currentLocationData != null
                  ? LatLng(_currentLocationData!.latitude, _currentLocationData!.longitude)
                  : null,
              onLocationSelected: (locationData) {
                setState(() {
                  _currentLocationData = locationData;
                  _currentAddress = _formatMainAddress(locationData);
                  _currentArea = _formatDetailedAddress(locationData);
                  _isLocationDetected = true;
                  _isGPSDisabled = false; // Reset GPS disabled state
                });
              },
              showCurrentLocationButton: true,
              showCenterMarker: true,
            ),
          ),

          // Bottom section with address info and button - Fixed minimum height
          Container(
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: 120, // Minimum height to prevent overflow
              maxHeight: MediaQuery.of(context).size.height * 0.4, // Maximum 40% of screen
            ),
            child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [


                // Clean address display without change button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentAddress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentArea,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Continue button - disabled until location is detected
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLocationDetected && !_isCheckingGPS ? _openAddressForm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isLocationDetected && !_isCheckingGPS ? Colors.green : Colors.grey[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isCheckingGPS
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Detecting location...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            _isLocationDetected ? 'Continue' : 'Waiting for location...',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                // Safe area padding for bottom - only when keyboard is not open
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0
                    ? 0
                    : MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
        ),
        ],
      ),
    );
  }
}


