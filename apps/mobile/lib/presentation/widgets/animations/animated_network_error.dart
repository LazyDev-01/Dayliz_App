import 'package:flutter/material.dart';
import 'lottie_animation_widget.dart';
import '../../../core/constants/animation_constants.dart';

/// An animated network error widget that displays when there are connectivity issues
class AnimatedNetworkError extends StatelessWidget {
  /// Custom error message
  final String? message;
  
  /// Custom subtitle text
  final String? subtitle;
  
  /// Retry callback
  final VoidCallback? onRetry;
  
  /// Whether to show the retry button
  final bool showRetryButton;
  
  /// Animation size
  final double? animationSize;
  
  /// Custom button text
  final String? retryButtonText;

  const AnimatedNetworkError({
    Key? key,
    this.message,
    this.subtitle,
    this.onRetry,
    this.showRetryButton = true,
    this.animationSize,
    this.retryButtonText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Network Error Lottie Animation
            LottieAnimationWidget(
              animationPath: AnimationConstants.errorAnimation,
              width: animationSize ?? 150,
              height: animationSize ?? 150,
              repeat: true,
              autoStart: true,
              speed: 0.8,
              fallback: Icon(
                Icons.wifi_off,
                size: animationSize ?? 150,
                color: Colors.grey.shade400,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Error Title
            Text(
              message ?? 'Connection Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Error Subtitle
            Text(
              subtitle ?? 'Please check your internet connection and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Retry Button
            if (showRetryButton && onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Quick factory methods for common network error scenarios
class DaylizNetworkErrors {
  /// General network connectivity error
  static Widget connectionError({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return AnimatedNetworkError(
      message: customMessage ?? 'No Internet Connection',
      subtitle: 'Please check your connection and try again.',
      onRetry: onRetry,
    );
  }

  /// Server error (API down, 500 errors, etc.)
  static Widget serverError({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return AnimatedNetworkError(
      message: customMessage ?? 'Server Error',
      subtitle: 'Something went wrong on our end. Please try again.',
      onRetry: onRetry,
      retryButtonText: 'Retry',
    );
  }

  /// Timeout error
  static Widget timeoutError({
    VoidCallback? onRetry,
  }) {
    return AnimatedNetworkError(
      message: 'Request Timeout',
      subtitle: 'The request took too long. Please check your connection.',
      onRetry: onRetry,
    );
  }

  /// API error with custom message
  static Widget apiError({
    required String errorMessage,
    VoidCallback? onRetry,
  }) {
    return AnimatedNetworkError(
      message: 'Something went wrong',
      subtitle: errorMessage,
      onRetry: onRetry,
    );
  }

  /// Compact network error for smaller spaces
  static Widget compact({
    VoidCallback? onRetry,
    String? message,
  }) {
    return AnimatedNetworkError(
      message: message ?? 'Connection Error',
      subtitle: 'Tap to retry',
      onRetry: onRetry,
      animationSize: 80,
      showRetryButton: false,
    );
  }
}

/// A network-aware widget that automatically shows error states
class NetworkAwareWidget extends StatelessWidget {
  /// The main content to show when network is available
  final Widget child;
  
  /// Whether there's currently a network error
  final bool hasNetworkError;
  
  /// The specific error message
  final String? errorMessage;
  
  /// Retry callback
  final VoidCallback? onRetry;
  
  /// Whether to show a compact error (for smaller spaces)
  final bool compact;

  const NetworkAwareWidget({
    Key? key,
    required this.child,
    required this.hasNetworkError,
    this.errorMessage,
    this.onRetry,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (hasNetworkError) {
      if (compact) {
        return DaylizNetworkErrors.compact(
          onRetry: onRetry,
          message: errorMessage,
        );
      } else {
        return DaylizNetworkErrors.connectionError(
          onRetry: onRetry,
          customMessage: errorMessage,
        );
      }
    }
    
    return child;
  }
}

/// A mixin for handling network errors in screens
mixin NetworkErrorHandler {
  /// Show network error dialog
  void showNetworkErrorDialog(BuildContext context, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: DaylizNetworkErrors.connectionError(
          onRetry: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
        ),
      ),
    );
  }

  /// Show network error snackbar
  void showNetworkErrorSnackbar(BuildContext context, {VoidCallback? onRetry}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('No internet connection'),
          ],
        ),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
                textColor: Colors.white,
              )
            : null,
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
