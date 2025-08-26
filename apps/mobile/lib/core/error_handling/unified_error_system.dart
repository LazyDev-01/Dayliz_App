import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../constants/app_colors.dart';
import '../errors/failures.dart';

/// Unified Error Handling System for Dayliz App
/// This system provides consistent error handling across all app features
class UnifiedErrorSystem {
  
  /// Maps any error/failure to user-friendly message
  static ErrorInfo mapToUserFriendly(dynamic error) {
    if (error is Failure) {
      return _mapFailureToErrorInfo(error);
    } else if (error is Exception) {
      return _mapExceptionToErrorInfo(error);
    } else {
      return _mapGenericErrorToErrorInfo(error);
    }
  }
  
  /// Maps failures to error info
  static ErrorInfo _mapFailureToErrorInfo(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return const ErrorInfo(
          type: ErrorType.network,
          title: 'Connection Problem',
          message: 'Please check your internet connection and try again',
          icon: Icons.wifi_off,
          retryText: 'Retry',
          canRetry: true,
        );

      case ServerFailure:
        return const ErrorInfo(
          type: ErrorType.server,
          title: 'Service Unavailable',
          message: 'Our servers are having issues. Please try again in a moment',
          icon: Icons.cloud_off,
          retryText: 'Try Again',
          canRetry: true,
        );
        
      case AuthFailure:
        return const ErrorInfo(
          type: ErrorType.authentication,
          title: 'Authentication Required',
          message: 'Please log in again to continue',
          icon: Icons.lock_outline,
          retryText: 'Log In',
          canRetry: true,
        );

      case ValidationFailure:
        return ErrorInfo(
          type: ErrorType.validation,
          title: 'Invalid Input',
          message: failure.message,
          icon: Icons.error_outline,
          retryText: 'Fix',
          canRetry: false,
        );
        
      case CacheFailure:
        return const ErrorInfo(
          type: ErrorType.storage,
          title: 'Storage Error',
          message: 'Unable to save or retrieve data locally',
          icon: Icons.storage,
          retryText: 'Retry',
          canRetry: true,
        );

      case NotFoundFailure:
        return ErrorInfo(
          type: ErrorType.notFound,
          title: 'Not Found',
          message: failure.message,
          icon: Icons.search_off,
          retryText: 'Go Back',
          canRetry: false,
        );

      default:
        return const ErrorInfo(
          type: ErrorType.unknown,
          title: 'Something Went Wrong',
          message: 'Please try again or contact support if the problem persists',
          icon: Icons.error_outline,
          retryText: 'Try Again',
          canRetry: true,
        );
    }
  }
  
  /// Maps exceptions to error info
  static ErrorInfo _mapExceptionToErrorInfo(Exception exception) {
    final errorString = exception.toString().toLowerCase();
    
    // Network errors
    if (errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return const ErrorInfo(
        type: ErrorType.network,
        title: 'Connection Problem',
        message: 'Please check your internet connection and try again',
        icon: Icons.wifi_off,
        retryText: 'Retry',
        canRetry: true,
      );
    }

    // Server errors
    if (errorString.contains('500') ||
        errorString.contains('server') ||
        errorString.contains('timeout')) {
      return const ErrorInfo(
        type: ErrorType.server,
        title: 'Service Unavailable',
        message: 'Our servers are having issues. Please try again in a moment',
        icon: Icons.cloud_off,
        retryText: 'Try Again',
        canRetry: true,
      );
    }
    
    // Authentication errors
    if (errorString.contains('401') ||
        errorString.contains('unauthorized') ||
        errorString.contains('authentication')) {
      return const ErrorInfo(
        type: ErrorType.authentication,
        title: 'Authentication Required',
        message: 'Please log in again to continue',
        icon: Icons.lock_outline,
        retryText: 'Log In',
        canRetry: true,
      );
    }

    // Permission errors
    if (errorString.contains('403') ||
        errorString.contains('forbidden') ||
        errorString.contains('permission')) {
      return const ErrorInfo(
        type: ErrorType.permission,
        title: 'Access Denied',
        message: 'You don\'t have permission to access this resource',
        icon: Icons.block,
        retryText: 'Go Back',
        canRetry: false,
      );
    }
    
    // Format errors
    if (errorString.contains('format') ||
        errorString.contains('json') ||
        errorString.contains('parsing')) {
      return const ErrorInfo(
        type: ErrorType.dataFormat,
        title: 'Data Error',
        message: 'The data received was in an unexpected format',
        icon: Icons.data_usage,
        retryText: 'Retry',
        canRetry: true,
      );
    }

    // Default exception handling
    return const ErrorInfo(
      type: ErrorType.unknown,
      title: 'Something Went Wrong',
      message: 'Please try again or contact support if the problem persists',
      icon: Icons.error_outline,
      retryText: 'Try Again',
      canRetry: true,
    );
  }
  
  /// Maps generic errors to error info
  static ErrorInfo _mapGenericErrorToErrorInfo(dynamic error) {
    return const ErrorInfo(
      type: ErrorType.unknown,
      title: 'Unexpected Error',
      message: 'Something unexpected happened. Please try again',
      icon: Icons.error_outline,
      retryText: 'Try Again',
      canRetry: true,
    );
  }
}

/// Error information container
class ErrorInfo {
  final ErrorType type;
  final String title;
  final String message;
  final IconData icon;
  final String retryText;
  final bool canRetry;
  final Color? color;
  
  const ErrorInfo({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.retryText,
    required this.canRetry,
    this.color,
  });
}

/// Error types for categorization
enum ErrorType {
  network,
  server,
  authentication,
  permission,
  validation,
  business,
  payment,
  location,
  storage,
  dataFormat,
  notFound,
  unknown,
}

/// Universal Error Widget - replaces all other error widgets
class UniversalErrorWidget extends StatelessWidget {
  final ErrorInfo errorInfo;
  final VoidCallback? onRetry;
  final bool isCompact;
  final bool showIcon;
  
  const UniversalErrorWidget({
    Key? key,
    required this.errorInfo,
    this.onRetry,
    this.isCompact = false,
    this.showIcon = true,
  }) : super(key: key);
  
  /// Factory constructor for any error
  factory UniversalErrorWidget.fromError({
    required dynamic error,
    VoidCallback? onRetry,
    bool isCompact = false,
    bool showIcon = true,
  }) {
    final errorInfo = UnifiedErrorSystem.mapToUserFriendly(error);
    return UniversalErrorWidget(
      errorInfo: errorInfo,
      onRetry: onRetry,
      isCompact: isCompact,
      showIcon: showIcon,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16.w : 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              errorInfo.icon,
              size: isCompact ? 48.sp : 64.sp,
              color: errorInfo.color ?? AppColors.textSecondary,
            ),
            SizedBox(height: isCompact ? 12.h : 16.h),
          ],
          
          // Error title
          Text(
            errorInfo.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8.h),
          
          // Error message
          Text(
            errorInfo.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (errorInfo.canRetry && onRetry != null) ...[
            SizedBox(height: isCompact ? 16.h : 24.h),
            _buildRetryButton(context),
          ],
        ],
      ),
    );
  }
  
  Widget _buildRetryButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        onRetry?.call();
      },
      icon: Icon(
        Icons.refresh,
        size: 18.sp,
        color: Colors.white,
      ),
      label: Text(
        errorInfo.retryText,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
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
