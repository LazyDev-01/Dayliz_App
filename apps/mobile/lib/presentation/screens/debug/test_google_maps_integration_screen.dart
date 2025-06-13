import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/common/google_map_widget.dart';
import '../../../core/services/location_service.dart';

/// Test screen to verify Google Maps integration functionality
class TestGoogleMapsIntegrationScreen extends StatefulWidget {
  const TestGoogleMapsIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<TestGoogleMapsIntegrationScreen> createState() => _TestGoogleMapsIntegrationScreenState();
}

class _TestGoogleMapsIntegrationScreenState extends State<TestGoogleMapsIntegrationScreen> {
  LatLng? _selectedLocation;
  LocationData? _selectedLocationData;
  String _statusMessage = 'Ready to test Google Maps integration';

  void _onLocationChanged(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _statusMessage = 'Location: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
    });
  }

  void _onLocationSelected(LocationData locationData) {
    setState(() {
      _selectedLocationData = locationData;
      _statusMessage = 'Address: ${locationData.address ?? 'Unknown'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Test'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Google Maps Integration Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                ),
                if (_selectedLocation != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Coordinates: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          // Google Maps Widget
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const Text(
                    'Google Maps with Rich POI Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Google Maps Widget
                  Expanded(
                    child: GoogleMapWidget(
                      height: double.infinity,
                      onLocationChanged: _onLocationChanged,
                      onLocationSelected: _onLocationSelected,
                      showCurrentLocationButton: true,
                      showCenterMarker: true,
                      mapType: MapType.normal, // Rich POI data
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Address Information Section
          if (_selectedLocationData != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedLocationData!.address != null)
                    Text('Address: ${_selectedLocationData!.address}'),
                  if (_selectedLocationData!.city != null)
                    Text('City: ${_selectedLocationData!.city}'),
                  if (_selectedLocationData!.state != null)
                    Text('State: ${_selectedLocationData!.state}'),
                  if (_selectedLocationData!.postalCode != null)
                    Text('Postal Code: ${_selectedLocationData!.postalCode}'),
                  if (_selectedLocationData!.country != null)
                    Text('Country: ${_selectedLocationData!.country}'),
                ],
              ),
            ),

          // Test Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Instructions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '1. Tap the location button to get current GPS location\n'
                  '2. Move the map to see different locations\n'
                  '3. Check if business names and POI labels are visible\n'
                  '4. Verify address resolution is working\n'
                  '5. Test different map types using the style selector',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
