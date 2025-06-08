import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Test Google Maps API directly to check if API key works
class GoogleMapsApiTest extends StatefulWidget {
  const GoogleMapsApiTest({Key? key}) : super(key: key);

  @override
  State<GoogleMapsApiTest> createState() => _GoogleMapsApiTestState();
}

class _GoogleMapsApiTestState extends State<GoogleMapsApiTest> {
  final String _apiKey = 'AIzaSyBf-rFSTkhfN_Z6DB8PR4suHjimIMxxXg0';
  final List<String> _logs = [];
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
    debugPrint(message);
  }

  Future<void> _testGeocodingAPI() async {
    setState(() => _isLoading = true);
    _log('🧪 Testing Geocoding API...');

    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=25.5138,90.2172'
          '&key=$_apiKey';

      _log('📡 Making API call to Geocoding API...');
      final response = await http.get(Uri.parse(url));
      
      _log('📊 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _log('✅ Geocoding API works! Status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          _log('🎉 API key is valid and working!');
        } else {
          _log('❌ API error: ${data['status']} - ${data['error_message'] ?? 'Unknown error'}');
        }
      } else {
        _log('❌ HTTP Error: ${response.statusCode}');
        _log('Response: ${response.body}');
      }
    } catch (e) {
      _log('❌ Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testStaticMapsAPI() async {
    setState(() => _isLoading = true);
    _log('🧪 Testing Static Maps API...');

    try {
      final url = 'https://maps.googleapis.com/maps/api/staticmap'
          '?center=25.5138,90.2172'
          '&zoom=14'
          '&size=400x400'
          '&key=$_apiKey';

      _log('📡 Making API call to Static Maps API...');
      final response = await http.get(Uri.parse(url));
      
      _log('📊 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        _log('✅ Static Maps API works!');
        _log('🎉 Map tiles should be loading!');
      } else {
        _log('❌ Static Maps API failed: ${response.statusCode}');
        _log('Response: ${response.body}');
      }
    } catch (e) {
      _log('❌ Network error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps API Test'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // API Key Info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Key Test',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Testing API key: ${_apiKey.substring(0, 20)}...',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),

          // Test Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGeocodingAPI,
                    child: const Text('Test Geocoding API'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testStaticMapsAPI,
                    child: const Text('Test Static Maps API'),
                  ),
                ),
              ],
            ),
          ),

          // Logs
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Test Results',
                    style: TextStyle(fontWeight: FontWeight.bold),
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

          // Instructions
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What to check:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• If APIs work: Map should load\n'
                  '• If "REQUEST_DENIED": Check API restrictions\n'
                  '• If "OVER_QUERY_LIMIT": Check billing\n'
                  '• If network error: Check internet connection',
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
