import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/deferred_maps_service.dart';
import '../../../core/services/location_service.dart';
import 'enhanced_loading_states.dart';
import 'google_map_widget.dart';

/// A lazy-loading wrapper for Google Maps that shows loading state first
/// This improves perceived performance by showing immediate feedback
class LazyGoogleMapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng)? onLocationChanged;
  final Function(LocationData)? onLocationSelected;
  final bool showCurrentLocationButton;
  final bool showCenterMarker;
  final double height;
  final Set<Marker>? markers;
  final MapType mapType;

  const LazyGoogleMapWidget({
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
  State<LazyGoogleMapWidget> createState() => _LazyGoogleMapWidgetState();
}

class _LazyGoogleMapWidgetState extends State<LazyGoogleMapWidget> {
  final MapsLoaderService _mapsLoader = MapsLoaderService();
  bool _showMap = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    // Initialize maps service with loading feedback
    final success = await _mapsLoader.initializeMaps();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _showMap = success;
      });
    }
  }

  Widget _buildLoadingState() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnhancedLoadingStates.mapSkeleton(height: widget.height),
          const SizedBox(height: 16),
          Text(
            'Loading Maps...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_showMap) {
      return GoogleMapWidget(
        initialLocation: widget.initialLocation,
        onLocationChanged: widget.onLocationChanged,
        onLocationSelected: widget.onLocationSelected,
        showCurrentLocationButton: widget.showCurrentLocationButton,
        showCenterMarker: widget.showCenterMarker,
        height: widget.height,
        markers: widget.markers,
        mapType: widget.mapType,
      );
    }

    return _buildLoadingState();
  }
}
