import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';
import '../../widgets/address/address_form_bottom_sheet.dart';
import '../../widgets/common/google_map_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
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
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Unable to detect location';
        _currentArea = 'Please search manually';
      });
    }
  }



  void _showSearchOverlay() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LocationSearchScreen(
          onLocationSelected: (location) {
            // Update with selected location
            setState(() {
              _currentAddress = location['address'] ?? 'Selected location';
              _currentArea = location['area'] ?? 'Manual selection';
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
      resizeToAvoidBottomInset: true, // Important: Allow screen to resize when keyboard appears
      body: Column(
        children: [
          // Google Maps Container - Flexible to shrink when keyboard appears
          Expanded(
            flex: 3, // Takes 3/4 of available space
            child: GoogleMapWidget(
              height: double.infinity,
              initialLocation: _currentLocationData != null
                  ? LatLng(_currentLocationData!.latitude, _currentLocationData!.longitude)
                  : null,
              onLocationSelected: (locationData) {
                setState(() {
                  _currentLocationData = locationData;
                  _currentAddress = locationData.address ?? 'Location detected';
                  _currentArea = '${locationData.city ?? ''}, ${locationData.state ?? ''}'.trim();
                  if (_currentArea == ',') {
                    _currentArea = 'GPS location detected';
                  }
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


                // Compact address display with inline change button
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _showSearchOverlay,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'CHANGE',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
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
                      'Continue',
                      style: TextStyle(
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


