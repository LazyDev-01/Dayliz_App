import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../../core/services/location_service.dart';
import '../../../core/utils/google_maps_helper.dart';

/// A reusable Google Maps widget for location picking
/// Simple and clean implementation with rich POI data
class GoogleMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng)? onLocationChanged;
  final Function(LocationData)? onLocationSelected;
  final bool showCurrentLocationButton;
  final bool showCenterMarker;
  final double height;
  final Set<Marker>? markers;
  final MapType mapType;

  const GoogleMapWidget({
    Key? key,
    this.initialLocation,
    this.onLocationChanged,
    this.onLocationSelected,
    this.showCurrentLocationButton = true,
    this.showCenterMarker = true,
    this.height = 300,
    this.markers,
    this.mapType = MapType.normal,
  }) : super(key: key);

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  GoogleMapController? _mapController;
  LatLng _currentLocation = const LatLng(25.5138, 90.2172); // Default to Tura
  bool _isLoading = false;
  bool _isMapReady = false; // Track map readiness to prevent rendering issues
  final LocationService _locationService = LocationService();
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _currentMapType = widget.mapType;
    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation!;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      geo.Position? position = await _locationService.getCurrentPosition();
      if (position != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
        });

        // Move camera to current location with high zoom
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newLocation,
                zoom: 18.0, // High zoom level so users don't need to zoom manually
              ),
            ),
          );
        }

        // Notify parent widget
        widget.onLocationChanged?.call(newLocation);

        // Get address for the location
        if (widget.onLocationSelected != null) {
          LocationData? locationData = await _locationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (locationData != null) {
            widget.onLocationSelected!(locationData);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    debugPrint('🗺️ Google Maps controller created successfully!');
    _mapController = controller;

    try {
      // Use helper for optimized camera animation with frame sync
      await GoogleMapsHelper.animateCameraWithSync(
        controller,
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        zoom: 18.0,
      );

      // Mark map as ready after successful initialization
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }

      debugPrint('✅ Camera moved to initial location: $_currentLocation');
    } catch (e) {
      debugPrint('❌ Error moving camera: $e');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Google Map with error handling
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 18.0, // Higher initial zoom
              ),
              mapType: _currentMapType,
              myLocationEnabled: false, // We'll use custom button
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              markers: widget.markers ?? {},
              onCameraMove: (CameraPosition position) {
                // Update current location when camera moves
                _currentLocation = position.target;
                widget.onLocationChanged?.call(position.target);
              },
              onCameraIdle: () async {
                // Get address when camera stops moving
                if (widget.onLocationSelected != null) {
                  try {
                    LocationData? locationData = await _locationService.getAddressFromCoordinates(
                      _currentLocation.latitude,
                      _currentLocation.longitude,
                    );
                    if (locationData != null) {
                      widget.onLocationSelected!(locationData);
                    }
                  } catch (e) {
                    debugPrint('❌ Error getting address: $e');
                  }
                }
              },
              // Add error callbacks
              onTap: (LatLng position) {
                debugPrint('🗺️ Map tapped at: ${position.latitude}, ${position.longitude}');
              },
            ),

            // Simple center marker (location pin)
            if (widget.showCenterMarker)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simple red location pin
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 48,
                    ),
                    // Small dot at the exact center
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.red,
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Enhanced current location button
            if (widget.showCurrentLocationButton)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4CAF50), // Dayliz green
                    elevation: 0,
                    onPressed: _getCurrentLocation, // Always enabled
                    child: const Icon(
                      Icons.my_location,
                      size: 22,
                    ),
                  ),
                ),
              ),



            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Use helper for proper disposal
    GoogleMapsHelper.disposeMapController(_mapController);
    super.dispose();
  }
}
