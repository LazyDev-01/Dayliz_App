import 'package:flutter/material.dart';

/// Utility class for managing app notifications and feedback
/// 
/// This class provides centralized control over user notifications,
/// allowing for easy enabling/disabling of different notification types
/// during different phases of app development.
class NotificationUtils {
  // Feature flags for different notification types
  static const bool _showSnackBars = false; // Disabled for early launch
  static const bool _showToasts = false; // Disabled for early launch
  static const bool _showDialogs = true; // Keep important dialogs enabled
  
  /// Shows a snack bar message if enabled
  /// 
  /// [context] - The build context
  /// [message] - The message to display
  /// [backgroundColor] - Optional background color
  /// [duration] - Optional duration (defaults to 2 seconds)
  /// [action] - Optional snack bar action
  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!_showSnackBars) {
      // Snack bars disabled for early launch
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 2),
        action: action,
      ),
    );
  }
  
  /// Shows a success snack bar if enabled
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.green,
      duration: duration,
    );
  }
  
  /// Shows an error snack bar if enabled
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.red,
      duration: duration,
    );
  }
  
  /// Shows a warning snack bar if enabled
  static void showWarningSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.orange,
      duration: duration,
    );
  }
  
  /// Shows an info snack bar if enabled
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    showSnackBar(
      context,
      message,
      backgroundColor: Colors.blue,
      duration: duration,
    );
  }
  
  /// Shows a confirmation dialog (always enabled for important actions)
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    if (!_showDialogs) {
      // If dialogs are disabled, return false (cancel action)
      return false;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: confirmColor != null
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  /// Shows an error dialog (always enabled for critical errors)
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    if (!_showDialogs) {
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
  
  /// Logs a message instead of showing notification (for debugging)
  static void logMessage(String message, {String? tag}) {
    final logTag = tag ?? 'NotificationUtils';
    debugPrint('[$logTag] $message');
  }
  
  /// Re-enable notifications (for future use)
  static void enableNotifications() {
    // This would require making the flags non-const and mutable
    // For now, this is a placeholder for future implementation
    logMessage('Notifications would be enabled here');
  }
  
  /// Disable notifications (for early launch)
  static void disableNotifications() {
    // This would require making the flags non-const and mutable
    // For now, this is a placeholder for future implementation
    logMessage('Notifications disabled for early launch');
  }
}
