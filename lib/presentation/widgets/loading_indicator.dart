import 'package:flutter/material.dart';

/// A reusable loading indicator widget that displays a centered circular progress
/// indicator with an optional message.
class LoadingIndicator extends StatelessWidget {
  /// The message to display below the progress indicator
  final String? message;
  
  /// Whether to show the indicator on a colored background
  final bool withBackground;
  
  /// The color of the progress indicator
  final Color? color;

  /// Creates a loading indicator
  const LoadingIndicator({
    Key? key,
    this.message,
    this.withBackground = false,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );

    if (withBackground) {
      return Container(
        color: Colors.black.withOpacity(0.1),
        child: Center(child: indicator),
      );
    }

    return Center(child: indicator);
  }
} 