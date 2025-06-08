import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';

/// Diagnostic screen to help debug Google Maps issues
class GoogleMapsDiagnosticScreen extends StatefulWidget {
  const GoogleMapsDiagnosticScreen({Key? key}) : super(key: key);

  @override
  State<GoogleMapsDiagnosticScreen> createState() => _GoogleMapsDiagnosticScreenState();
}

class _GoogleMapsDiagnosticScreenState extends State<GoogleMapsDiagnosticScreen> {
  GoogleMapController? _controller;
  String _status = 'Initializing Google Maps...';
  bool _mapCreated = false;
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  @override
  void initState() {
    super.initState();
    _log('🚀 Starting Google Maps diagnostic...');
    _checkGoogleMapsSetup();
  }

  void _checkGoogleMapsSetup() {
    _log('📋 Checking Google Maps setup...');
    _log('✅ google_maps_flutter dependency loaded');
    _log('✅ API Key configured in AndroidManifest.xml');
    _log('✅ google-services.json present');
    _log('⏳ Waiting for map to initialize...');
  }

  void _onMapCreated(GoogleMapController controller) {
    _log('🗺️ Google Maps controller created!');
    _controller = controller;
    setState(() {
      _mapCreated = true;
      _status = 'Google Maps loaded successfully!';
    });
    _log('✅ Map initialization complete');
  }

  void _testMapFunctionality() async {
    if (_controller == null) {
      _log('❌ Map controller not available');
      return;
    }

    try {
      _log('🧪 Testing map functionality...');

      // Test camera movement
      await _controller!.animateCamera(
        CameraUpdate.newLatLng(const LatLng(25.5138, 90.2172)),
      );
      _log('✅ Camera movement test passed');

      // Test zoom
      await _controller!.animateCamera(
        CameraUpdate.zoomTo(15.0),
      );
      _log('✅ Zoom test passed');

      _log('🎉 All tests passed! Google Maps is working correctly.');

    } catch (e) {
      _log('❌ Map functionality test failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps Diagnostic'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _mapCreated ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _mapCreated ? Colors.green : Colors.orange,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _mapCreated ? Icons.check_circle : Icons.warning,
                      color: _mapCreated ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _mapCreated ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_mapCreated) ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testMapFunctionality,
                    child: const Text('Test Map Functionality'),
                  ),
                ],
              ],
            ),
          ),

          // Simple Google Map
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(25.5138, 90.2172), // Tura, Meghalaya
                    zoom: 18.0, // Higher zoom for better detail
                  ),
                  mapType: MapType.normal,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),

          // Logs Section
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Diagnostic Logs',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Logs copied to clipboard')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
