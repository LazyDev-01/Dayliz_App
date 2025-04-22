import 'package:flutter/material.dart';

/// A helper class to handle permission requests and checks
/// This is a stub implementation until we properly migrate this to clean architecture
class PermissionHelper {
  /// Show a dialog to explain why we need a permission
  static Future<void> showPermissionExplanationDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  /// Placeholder for location permission request
  static Future<bool> requestLocationPermission(BuildContext context) async {
    // Show a placeholder dialog explaining that this feature is not available
    await showPermissionExplanationDialog(
      context,
      title: 'Feature Unavailable',
      message: 'Location features are currently being migrated to the new architecture.',
    );
    return false;
  }
} 