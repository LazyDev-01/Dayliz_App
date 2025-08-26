import 'package:flutter/material.dart';

/// A reusable error display widget for showing errors across the app
/// 
/// This widget provides a consistent way to display errors with optional
/// retry functionality and customizable appearance.
class ErrorDisplay extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Optional subtitle for additional context
  final String? subtitle;
  
  /// The retry callback (optional)
  final VoidCallback? onRetry;
  
  /// The retry button text (defaults to "Retry")
  final String retryText;
  
  /// Whether to show the error icon (defaults to true)
  final bool showIcon;
  
  /// Custom icon to display (defaults to error_outline)
  final IconData? icon;
  
  /// Whether to use compact layout (smaller padding and text)
  final bool isCompact;
  
  /// Custom color for the icon and text
  final Color? color;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.subtitle,
    this.onRetry,
    this.retryText = "Retry",
    this.showIcon = true,
    this.icon,
    this.isCompact = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = color ?? theme.colorScheme.error;
    final textColor = color ?? Colors.grey[700];
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                icon ?? Icons.error_outline,
                size: isCompact ? 40 : 48,
                color: errorColor,
              ),
              SizedBox(height: isCompact ? 12 : 16),
            ],
            
            // Main error message
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Optional subtitle
            if (subtitle != null) ...[
              SizedBox(height: isCompact ? 6 : 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Retry button
            if (onRetry != null) ...[
              SizedBox(height: isCompact ? 12 : 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specialized error displays for common scenarios
class ErrorDisplays {
  
  /// Network connection error
  static Widget networkError({
    VoidCallback? onRetry,
    bool isCompact = false,
  }) {
    return ErrorDisplay(
      message: 'Connection Problem',
      subtitle: 'Please check your internet connection and try again',
      onRetry: onRetry,
      retryText: 'Try Again',
      icon: Icons.wifi_off,
      isCompact: isCompact,
    );
  }
  
  /// Server error
  static Widget serverError({
    VoidCallback? onRetry,
    bool isCompact = false,
    String? customMessage,
  }) {
    return ErrorDisplay(
      message: customMessage ?? 'Server Error',
      subtitle: 'Something went wrong on our end. Please try again',
      onRetry: onRetry,
      retryText: 'Retry',
      icon: Icons.cloud_off,
      isCompact: isCompact,
    );
  }
  
  /// Data loading failed
  static Widget loadingFailed({
    required String dataType,
    VoidCallback? onRetry,
    bool isCompact = false,
  }) {
    return ErrorDisplay(
      message: 'Unable to load $dataType',
      subtitle: 'Please check your connection and try again',
      onRetry: onRetry,
      retryText: 'Retry',
      isCompact: isCompact,
    );
  }
  
  /// Search failed
  static Widget searchFailed({
    VoidCallback? onRetry,
    bool isCompact = false,
  }) {
    return ErrorDisplay(
      message: 'Search unavailable',
      subtitle: 'Unable to search right now. Please try again',
      onRetry: onRetry,
      retryText: 'Try Again',
      icon: Icons.search_off,
      isCompact: isCompact,
    );
  }
  
  /// No data found
  static Widget noDataFound({
    required String dataType,
    String? actionText,
    VoidCallback? onAction,
    bool isCompact = false,
  }) {
    return ErrorDisplay(
      message: 'No $dataType found',
      subtitle: 'Try adjusting your search or filters',
      onRetry: onAction,
      retryText: actionText ?? 'Refresh',
      icon: Icons.inbox_outlined,
      isCompact: isCompact,
      color: Colors.grey[600],
    );
  }
}
