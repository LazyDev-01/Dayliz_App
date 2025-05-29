import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/location_service.dart';
import '../../widgets/address/address_form_bottom_sheet.dart';
import 'location_search_screen.dart';

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  String _currentAddress = 'NA';
  String _currentArea = 'NA';
  bool _isLoadingLocation = false;
  LocationData? _currentLocationData;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    // Auto-detect location when page loads
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _currentAddress = 'Detecting location...';
      _currentArea = 'Please wait...';
    });

    try {
      // Get current location with address
      LocationData? locationData = await _locationService.getCurrentLocationWithAddress();

      if (locationData != null) {
        setState(() {
          _currentLocationData = locationData;
          _currentAddress = locationData.address ?? 'Location detected';
          _currentArea = '${locationData.city ?? ''}, ${locationData.state ?? ''}'.trim();
          if (_currentArea == ',') {
            _currentArea = 'GPS location detected';
          }
        });
      } else {
        setState(() {
          _currentAddress = 'Unable to detect location';
          _currentArea = 'Please try manual search or check GPS';
        });
      }
    } catch (e) {
      // Handle location errors
      setState(() {
        if (e is LocationServiceDisabledException) {
          _currentAddress = 'Location services disabled';
          _currentArea = 'Please enable GPS in settings';
        } else if (e is LocationPermissionDeniedException) {
          _currentAddress = 'Location permission denied';
          _currentArea = 'Please grant location permission';
        } else {
          _currentAddress = 'Unable to fetch location';
          _currentArea = 'Please try again or search manually';
        }
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showSearchOverlay() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          onLocationSelected: (location) {
            // Update map with selected location
            setState(() {
              _currentAddress = location['address'] ?? 'Selected location';
              _currentArea = location['area'] ?? 'Manual selection';
            });
          },
        ),
      ),
    );
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirm Delivery Location',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Map Container (No search bar above)
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: const Color(0xFF87CEEB), // Light blue placeholder for map
              child: Stack(
                children: [
                  // Map placeholder
                  const Center(
                    child: Text(
                      'Map will be integrated here',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Location pin in center
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      color: Colors.black87,
                      size: 32,
                    ),
                  ),

                  // Current location button (top right)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.green,
                                ),
                              )
                            : const Icon(
                                Icons.my_location,
                                color: Colors.green,
                                size: 20,
                              ),
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        tooltip: 'Get current location',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom section with address info and button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Delivering your order to" text
                const Row(
                  children: [
                    Text(
                      'Delivering your order to',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Address display container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentAddress,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentArea,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search location manually button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showSearchOverlay,
                    icon: const Icon(
                      Icons.search,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: const Text(
                      'Search location manually',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: const BorderSide(color: Colors.green, width: 1),
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Enter complete address button (smaller)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openAddressForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Enter complete address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Safe area padding for bottom
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


