import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

/// Enhanced inline error widget for user-friendly error handling
/// Designed to replace technical error messages with clear, actionable UI
class InlineErrorWidget extends StatefulWidget {
  /// The user-friendly error message to display
  final String message;

  /// The retry callback (optional)
  final VoidCallback? onRetry;

  /// The retry button text (defaults to "Try Again")
  final String retryText;

  /// Optional subtitle for additional context
  final String? subtitle;

  /// Whether to show the error icon (defaults to true)
  final bool showIcon;

  /// Custom icon to display (defaults to error_outline)
  final IconData? icon;

  /// Whether to use compact layout (smaller padding and text)
  final bool isCompact;

  const InlineErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
    this.retryText = 'Try Again',
    this.subtitle,
    this.showIcon = true,
    this.icon,
    this.isCompact = false,
  }) : super(key: key);

  @override
  State<InlineErrorWidget> createState() => _InlineErrorWidgetState();
}

class _InlineErrorWidgetState extends State<InlineErrorWidget> {
  bool _isRetrying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(widget.isCompact ? 16.w : 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showIcon) ...[
            Icon(
              widget.icon ?? Icons.error_outline,
              size: widget.isCompact ? 48.sp : 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: widget.isCompact ? 12.h : 16.h),
          ],
          
          // Main error message
          Text(
            widget.message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (widget.subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              widget.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          if (widget.onRetry != null) ...[
            SizedBox(height: widget.isCompact ? 16.h : 24.h),
            _buildRetryButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRetryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isRetrying ? null : () async {
        if (_isRetrying) return;

        setState(() {
          _isRetrying = true;
        });

        HapticFeedback.lightImpact();

        try {
          // Call the retry function
          widget.onRetry?.call();

          // Add a small delay to show loading state
          await Future.delayed(const Duration(milliseconds: 500));
        } finally {
          if (mounted) {
            setState(() {
              _isRetrying = false;
            });
          }
        }
      },
      icon: _isRetrying
          ? SizedBox(
              width: 18.sp,
              height: 18.sp,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _isRetrying ? Colors.white70 : Colors.white,
                ),
              ),
            )
          : Icon(
              Icons.refresh,
              size: 18.sp,
              color: Colors.white,
            ),
      label: Text(
        _isRetrying ? 'Retrying...' : widget.retryText,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: _isRetrying ? Colors.white70 : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isRetrying ? Colors.grey[600] : Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 12.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
      ),
    );
  }
}

/// Specialized error widgets for common scenarios
class NetworkErrorWidgets {
  
  /// Error for when data fails to load
  static Widget loadingFailed({
    required String dataType,
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Unable to load $dataType',
      subtitle: 'Please check your connection and try again',
      onRetry: onRetry,
      retryText: 'Retry',
      isCompact: isCompact,
    );
  }
  
  /// Error for when search fails
  static Widget searchFailed({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Search unavailable',
      subtitle: 'Unable to search right now. Please try again',
      onRetry: onRetry,
      retryText: 'Try Again',
      icon: Icons.search_off,
      isCompact: isCompact,
    );
  }
  
  /// Error for when cart operations fail
  static Widget cartOperationFailed({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Cart unavailable',
      subtitle: 'Unable to load your cart. Please try again',
      onRetry: onRetry,
      retryText: 'Reload Cart',
      icon: Icons.shopping_cart_outlined,
      isCompact: isCompact,
    );
  }
  
  /// Error for when orders fail to load
  static Widget ordersFailed({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Orders unavailable',
      subtitle: 'Unable to load your orders. Please try again',
      onRetry: onRetry,
      retryText: 'Reload Orders',
      icon: Icons.receipt_long_outlined,
      isCompact: isCompact,
    );
  }
  
  /// Error for when addresses fail to load
  static Widget addressesFailed({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Addresses unavailable',
      subtitle: 'Unable to load your addresses. Please try again',
      onRetry: onRetry,
      retryText: 'Reload Addresses',
      icon: Icons.location_on_outlined,
      isCompact: isCompact,
    );
  }
  
  /// Generic server error
  static Widget serverError({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Service temporarily unavailable',
      subtitle: 'Our servers are having issues. Please try again in a moment',
      onRetry: onRetry,
      retryText: 'Try Again',
      isCompact: isCompact,
    );
  }
  
  /// Universal connection problem - MAIN ERROR FOR ALL NETWORK ISSUES
  /// Use this for all network-related errors across the app
  static Widget connectionProblem({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return InlineErrorWidget(
      message: 'Connection problem',
      subtitle: 'Please check your internet connection and try again',
      onRetry: onRetry,
      retryText: 'Retry',
      icon: Icons.wifi_off,
      isCompact: isCompact,
    );
  }

  /// Alias for connectionProblem - for backward compatibility
  /// @deprecated Use connectionProblem() instead
  static Widget networkError({
    required VoidCallback onRetry,
    bool isCompact = false,
  }) {
    return connectionProblem(onRetry: onRetry, isCompact: isCompact);
  }
}
