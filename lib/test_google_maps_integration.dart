import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'presentation/widgets/common/google_map_widget.dart';
import 'core/services/location_service.dart';

/// Test screen to verify Google Maps integration functionality
class TestGoogleMapsIntegrationScreen extends StatefulWidget {
  const TestGoogleMapsIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<TestGoogleMapsIntegrationScreen> createState() => _TestGoogleMapsIntegrationScreenState();
}

class _TestGoogleMapsIntegrationScreenState extends State<TestGoogleMapsIntegrationScreen> {
  String _status = 'Initializing Google Maps...';
  LatLng? _selectedLocation;
  LocationData? _selectedLocationData;
  bool _isLoading = false;
  bool _mapLoaded = false;

  void _onLocationChanged(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _status = 'Location: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    });
  }

  void _onLocationSelected(LocationData locationData) {
    setState(() {
      _selectedLocationData = locationData;
      _status = 'Address: ${locationData.address}';
      if (!_mapLoaded) {
        _mapLoaded = true;
        _status = '✅ Google Maps loaded successfully! Address: ${locationData.address}';
      }
    });
  }

  void _onMapReady() {
    setState(() {
      _mapLoaded = true;
      _status = '✅ Google Maps initialized successfully!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(_status),
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  Text('Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _mapLoaded ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: _mapLoaded ? Colors.green : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _mapLoaded ? 'Google Maps Loaded' : 'Loading Google Maps...',
                      style: TextStyle(
                        color: _mapLoaded ? Colors.green : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),

          // Google Maps Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive Google Map',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Google Map Widget
                  Expanded(
                    child: GoogleMapWidget(
                      height: double.infinity,
                      onLocationChanged: _onLocationChanged,
                      onLocationSelected: _onLocationSelected,
                      showCurrentLocationButton: true,
                      showCenterMarker: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Location Data Section
          if (_selectedLocationData != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Location Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildLocationDetail('Address', _selectedLocationData!.address),
                  _buildLocationDetail('City', _selectedLocationData!.city),
                  _buildLocationDetail('State', _selectedLocationData!.state),
                  _buildLocationDetail('Postal Code', _selectedLocationData!.postalCode),
                  _buildLocationDetail('Country', _selectedLocationData!.country),
                  _buildLocationDetail('Locality', _selectedLocationData!.locality),
                  _buildLocationDetail('Sub Locality', _selectedLocationData!.subLocality),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationDetail(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
