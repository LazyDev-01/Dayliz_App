import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Very simple Google Maps test to check if maps load at all
class SimpleGoogleMapsTest extends StatefulWidget {
  const SimpleGoogleMapsTest({Key? key}) : super(key: key);

  @override
  State<SimpleGoogleMapsTest> createState() => _SimpleGoogleMapsTestState();
}

class _SimpleGoogleMapsTestState extends State<SimpleGoogleMapsTest> {
  GoogleMapController? _controller;
  bool _mapLoaded = false;
  String _status = 'Loading Google Maps...';

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    setState(() {
      _mapLoaded = true;
      _status = 'Google Maps loaded successfully! ✅';
    });
    debugPrint('✅ Google Maps loaded successfully!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Google Maps Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _mapLoaded ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _mapLoaded ? Colors.green : Colors.orange,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _mapLoaded ? Icons.check_circle : Icons.hourglass_empty,
                  color: _mapLoaded ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _mapLoaded ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Simple Google Map
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(25.5138, 90.2172), // Tura, Meghalaya
                    zoom: 18.0, // Higher zoom for better detail
                  ),
                  mapType: MapType.normal,
                ),
              ),
            ),
          ),

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ISSUE IDENTIFIED: Map tiles not loading',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
                SizedBox(height: 8),
                Text(
                  'SOLUTION: Enable these APIs in Google Cloud Console:\n'
                  '1. Maps Static API\n'
                  '2. Maps JavaScript API\n'
                  '3. Geocoding API\n'
                  '4. Places API\n\n'
                  'Also check API key restrictions!',
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
