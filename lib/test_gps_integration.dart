import 'package:flutter/material.dart';
import 'core/services/location_service.dart';

/// Test screen to verify GPS integration functionality
class TestGPSIntegrationScreen extends StatefulWidget {
  const TestGPSIntegrationScreen({Key? key}) : super(key: key);

  @override
  State<TestGPSIntegrationScreen> createState() => _TestGPSIntegrationScreenState();
}

class _TestGPSIntegrationScreenState extends State<TestGPSIntegrationScreen> {
  final LocationService _locationService = LocationService();

  String _status = 'Ready to test Enhanced Mock GPS';
  bool _isLoading = false;
  LocationData? _currentLocation;
  String _permissionStatus = 'Unknown';
  bool _serviceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking initial status...';
    });

    try {
      // Check if location services are enabled
      _serviceEnabled = await _locationService.isLocationServiceEnabled();

      // Check permission status
      MockLocationPermission permission = await _locationService.checkLocationPermission();
      _permissionStatus = permission.toString();

      setState(() {
        _status = 'Initial status checked';
      });
    } catch (e) {
      setState(() {
        _status = 'Error checking status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
      _status = 'Requesting location permission...';
    });

    try {
      MockLocationPermission permission = await _locationService.requestLocationPermission();
      setState(() {
        _permissionStatus = permission.toString();
        _status = 'Permission request completed';
      });
    } catch (e) {
      setState(() {
        _status = 'Error requesting permission: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _status = 'Getting current location...';
      _currentLocation = null;
    });

    try {
      LocationData? location = await _locationService.getCurrentLocationWithAddress();
      setState(() {
        _currentLocation = location;
        _status = location != null
            ? 'Location retrieved successfully!'
            : 'Failed to get location';
      });
    } catch (e) {
      setState(() {
        _status = 'Error getting location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  Future<void> _openAppSettings() async {
    await _locationService.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Mock GPS Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Current Status: $_status'),
                    Text('Service Enabled: $_serviceEnabled'),
                    Text('Permission: $_permissionStatus'),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _checkInitialStatus,
                        child: const Text('Check Status'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestPermission,
                        child: const Text('Request Permission'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Get Current Location'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _openLocationSettings,
                            child: const Text('Location Settings'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _openAppSettings,
                            child: const Text('App Settings'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Location Data Section
            if (_currentLocation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${_currentLocation!.latitude}'),
                      Text('Longitude: ${_currentLocation!.longitude}'),
                      Text('Address: ${_currentLocation!.address ?? 'N/A'}'),
                      Text('City: ${_currentLocation!.city ?? 'N/A'}'),
                      Text('State: ${_currentLocation!.state ?? 'N/A'}'),
                      Text('Postal Code: ${_currentLocation!.postalCode ?? 'N/A'}'),
                      Text('Country: ${_currentLocation!.country ?? 'N/A'}'),
                      Text('Locality: ${_currentLocation!.locality ?? 'N/A'}'),
                      Text('Sub Locality: ${_currentLocation!.subLocality ?? 'N/A'}'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
