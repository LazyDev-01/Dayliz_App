import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';

/// A reusable Google Maps widget for location picking
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
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentLocation = widget.initialLocation!;
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      Position? position = await _locationService.getCurrentPosition();
      if (position != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
        });

        // Move camera to current location
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLng(newLocation),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;

    // Move to initial location
    await controller.animateCamera(
      CameraUpdate.newLatLng(_currentLocation),
    );
  }

  Future<void> _onCameraMove(CameraPosition position) async {
    setState(() {
      _currentLocation = position.target;
    });

    // Notify parent widget about location change
    widget.onLocationChanged?.call(position.target);
  }

  Future<void> _onCameraIdle() async {
    // Get address for the new location when camera stops moving
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
        debugPrint('Error getting address: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Google Map
            GoogleMap(
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              initialCameraPosition: CameraPosition(
                target: _currentLocation,
                zoom: 16.0,
              ),
              mapType: widget.mapType,
              myLocationEnabled: true,
              myLocationButtonEnabled: false, // We'll use custom button
              zoomControlsEnabled: false,
              markers: widget.markers ?? {},
              compassEnabled: true,
              mapToolbarEnabled: false,
            ),

            // Center marker (location pin)
            if (widget.showCenterMarker)
              const Center(
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),

            // Current location button
            if (widget.showCurrentLocationButton)
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
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
    _mapController?.dispose();
    super.dispose();
  }
}

/// Location data model for map integration
class MapLocationData {
  final LatLng coordinates;
  final String address;
  final String city;
  final String state;
  final String postalCode;

  MapLocationData({
    required this.coordinates,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory MapLocationData.fromLocationData(LocationData locationData) {
    return MapLocationData(
      coordinates: LatLng(locationData.latitude, locationData.longitude),
      address: locationData.address ?? '',
      city: locationData.city ?? '',
      state: locationData.state ?? '',
      postalCode: locationData.postalCode ?? '',
    );
  }
}
