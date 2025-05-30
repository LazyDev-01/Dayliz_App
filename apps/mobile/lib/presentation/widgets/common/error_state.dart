import 'package:flutter/material.dart';

/// A reusable error state widget for displaying when an error occurs
class ErrorState extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// Alternative error parameter for compatibility with AsyncValue error callbacks
  final String? error;
  
  /// The retry callback (optional)
  final VoidCallback? onRetry;
  
  /// The retry button text (defaults to "Retry")
  final String retryText;

  const ErrorState({
    Key? key,
    this.message = 'An error occurred',
    this.error,
    this.onRetry,
    this.retryText = "Retry",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use error parameter if provided, otherwise use message
    final displayMessage = error ?? message;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              displayMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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