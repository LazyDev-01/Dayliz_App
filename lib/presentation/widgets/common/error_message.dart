import 'package:flutter/material.dart';

/// A reusable error message widget for displaying inline errors
class ErrorMessage extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// The retry callback (optional)
  final VoidCallback? onRetry;
  
  /// The retry button text (defaults to "Retry")
  final String retryText;
  
  /// Whether to show the error icon (defaults to true)
  final bool showIcon;

  const ErrorMessage({
    Key? key,
    required this.message,
    this.onRetry,
    this.retryText = "Retry",
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showIcon) ...[
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 