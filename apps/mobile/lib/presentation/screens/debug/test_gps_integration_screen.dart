import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../../../core/config/app_config.dart';

/// Test screen to verify GPS integration functionality
class TestGPSIntegrationScreen extends StatefulWidget {
  const TestGPSIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<TestGPSIntegrationScreen> createState() => _TestGPSIntegrationScreenState();
}

class _TestGPSIntegrationScreenState extends State<TestGPSIntegrationScreen> {
  String _status = 'Ready to test GPS';
  Position? _currentPosition;
  bool _isLoading = false;
  bool _useMockLocation = false;
  final LocationService _locationService = LocationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Integration Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GPS Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_currentPosition != null) ...[
                      const SizedBox(height: 8),
                      Text('Latitude: ${_currentPosition!.latitude}'),
                      Text('Longitude: ${_currentPosition!.longitude}'),
                      Text('Accuracy: ${_currentPosition!.accuracy}m'),
                      Text('Timestamp: ${_currentPosition!.timestamp}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Mock Location'),
              subtitle: const Text('Toggle between real GPS and mock location'),
              value: _useMockLocation,
              onChanged: (value) {
                setState(() {
                  _useMockLocation = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLocationPermissions,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Location Permissions'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _getCurrentLocation,
              child: const Text('Get Current Location'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testLocationService,
              child: const Text('Test Location Service'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testAppConfig,
              child: const Text('Test App Config'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testLocationPermissions() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing location permissions...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _status = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _status = 'Location permissions are denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _status = 'Location permissions are permanently denied, we cannot request permissions.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'Location permissions granted successfully!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error testing permissions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting current location...';
    });

    try {
      if (_useMockLocation) {
        // Use mock location for testing
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _currentPosition = Position(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime.now(),
            accuracy: 5.0,
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
          _status = 'Mock location retrieved successfully!';
          _isLoading = false;
        });
      } else {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
          _status = 'Real location retrieved successfully!';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error getting location: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testLocationService() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing location service...';
    });

    try {
      final locationData = await _locationService.getCurrentLocationWithAddress();
      if (locationData != null) {
        // Convert LocationData to Position for display
        final position = Position(
          latitude: locationData.latitude,
          longitude: locationData.longitude,
          timestamp: DateTime.now(), // Use current time since LocationData doesn't have timestamp
          accuracy: 5.0, // Default accuracy
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
        setState(() {
          _currentPosition = position;
          _status = 'Location service test successful!\nAddress: ${locationData.address}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _status = 'Location service returned null';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Location service test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testAppConfig() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing app config...';
    });

    try {
      setState(() {
        _status = 'App config loaded successfully!\n'
            'Development Mode: ${AppConfig.isDevelopment}\n'
            'FastAPI Base URL: ${AppConfig.fastApiBaseUrl}\n'
            'Supabase URL: ${AppConfig.supabaseUrl}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'App config test failed: $e';
        _isLoading = false;
      });
    }
  }
}
