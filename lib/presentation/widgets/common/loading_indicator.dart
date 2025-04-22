import 'package:flutter/material.dart';

/// A reusable loading indicator widget
class LoadingIndicator extends StatelessWidget {
  /// The size of the loading indicator (default: 40)
  final double size;
  
  /// The stroke width of the loading indicator (default: 4)
  final double strokeWidth;
  
  /// The color of the loading indicator (default: Theme's primary color)
  final Color? color;
  
  /// Optional message to display beneath the indicator
  final String? message;

  const LoadingIndicator({
    Key? key,
    this.size = 40,
    this.strokeWidth = 4,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: color != null
                  ? AlwaysStoppedAnimation<Color>(color!)
                  : null,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ],
      ),
    );
  }
} 