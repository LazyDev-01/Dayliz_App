import 'package:flutter/material.dart';

/// A reusable widget for displaying error states with a retry option
class ErrorDisplay extends StatelessWidget {
  /// The error message to display
  final String message;

  /// The icon to display (default: error_outline)
  final IconData icon;

  /// The color of the icon and button (default: error color)
  final Color? color;

  /// The callback function when the retry button is pressed
  final VoidCallback? onRetry;

  /// The text for the retry button (default: 'Retry')
  final String retryText;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.icon = Icons.error_outline,
    this.color,
    this.onRetry,
    this.retryText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = color ?? Theme.of(context).colorScheme.error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}