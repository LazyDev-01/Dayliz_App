import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// A helper class to handle permission requests and checks
class PermissionHelper {
  // Flag to track ongoing permission requests
  static bool _isRequestingPermission = false;

  /// Check and request location permissions, with proper handling for Android 13+
  static Future<bool> checkAndRequestLocationPermission(
    BuildContext context,
    {bool showSettingsDialogIfDenied = true}
  ) async {
    // Prevent multiple simultaneous permission requests
    if (_isRequestingPermission) {
      debugPrint('A permission request is already in progress');
      return false;
    }

    try {
      _isRequestingPermission = true;
      
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        if (context.mounted && showSettingsDialogIfDenied) {
          await _showLocationServicesDialog(context);
        }
        return false;
      }

      // Check for location permission
      PermissionStatus status = await Permission.location.status;
      
      if (status.isGranted) {
        // Permission already granted
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        // Permission permanently denied, open app settings
        if (context.mounted && showSettingsDialogIfDenied) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      }
      
      // Request permission
      status = await Permission.location.request();
      
      // Handle the result
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // User selected "Never Ask Again"
        if (context.mounted && showSettingsDialogIfDenied) {
          await _showPermissionDeniedDialog(context);
        }
        return false;
      } else {
        // Permission denied but not permanently
        return false;
      }
    } finally {
      _isRequestingPermission = false;
    }
  }
  
  /// Show a dialog explaining why location services need to be enabled
  static Future<void> _showLocationServicesDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are disabled. Please enable location services in your device settings to use this feature.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }
  
  /// Show a dialog explaining why location permission is required
  static Future<void> _showPermissionDeniedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'We need access to your location to provide accurate delivery options. Please grant location permission in app settings.'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
            ),
          ],
        );
      },
    );
  }
} 