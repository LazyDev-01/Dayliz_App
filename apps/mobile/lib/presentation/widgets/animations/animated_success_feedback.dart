import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'lottie_animation_widget.dart';
import '../../../core/constants/animation_constants.dart';

/// An animated success feedback widget for celebrating user achievements
class AnimatedSuccessFeedback extends StatelessWidget {
  /// Success message title
  final String? title;
  
  /// Success message subtitle
  final String? subtitle;
  
  /// Callback when animation completes
  final VoidCallback? onCompleted;
  
  /// Whether to auto-dismiss after animation
  final bool autoDismiss;
  
  /// Animation size
  final double? animationSize;
  
  /// Custom action button
  final Widget? actionButton;
  
  /// Whether to show haptic feedback
  final bool enableHaptics;
  
  /// Animation speed multiplier
  final double speed;

  const AnimatedSuccessFeedback({
    Key? key,
    this.title,
    this.subtitle,
    this.onCompleted,
    this.autoDismiss = true,
    this.animationSize,
    this.actionButton,
    this.enableHaptics = true,
    this.speed = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Trigger haptic feedback when widget builds
    if (enableHaptics) {
      HapticFeedback.lightImpact();
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Checkmark Lottie Animation
            LottieAnimationWidget(
              animationPath: AnimationConstants.successCheckmark,
              width: animationSize ?? 120,
              height: animationSize ?? 120,
              repeat: false,
              autoStart: true,
              speed: speed,
              onCompleted: () {
                if (enableHaptics) {
                  HapticFeedback.mediumImpact();
                }
                if (autoDismiss) {
                  // Auto-dismiss after a short delay
                  Future.delayed(const Duration(milliseconds: 500), () {
                    onCompleted?.call();
                  });
                } else {
                  onCompleted?.call();
                }
              },
              fallback: Icon(
                Icons.check_circle,
                size: animationSize ?? 120,
                color: Colors.green,
              ),
            ),
            
            if (title != null) ...[
              const SizedBox(height: 16),
              Text(
                title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Quick factory methods for common success scenarios
class DaylizSuccessAnimations {
  /// Order placed successfully
  static Widget orderPlaced({
    String? orderNumber,
    VoidCallback? onViewOrder,
    VoidCallback? onContinueShopping,
  }) {
    return AnimatedSuccessFeedback(
      title: 'Order Placed Successfully!',
      subtitle: orderNumber != null 
        ? 'Order #$orderNumber has been confirmed'
        : 'Your order has been confirmed',
      autoDismiss: false,
      actionButton: Column(
        children: [
          if (onViewOrder != null)
            ElevatedButton(
              onPressed: onViewOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 45),
              ),
              child: const Text('View Order'),
            ),
          if (onContinueShopping != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onContinueShopping,
              child: const Text('Continue Shopping'),
            ),
          ],
        ],
      ),
    );
  }

  /// Payment successful
  static Widget paymentSuccess({
    String? amount,
    VoidCallback? onCompleted,
  }) {
    return AnimatedSuccessFeedback(
      title: 'Payment Successful!',
      subtitle: amount != null 
        ? 'Payment of $amount completed successfully'
        : 'Your payment has been processed',
      onCompleted: onCompleted,
      speed: 1.2,
    );
  }

  /// Profile updated
  static Widget profileUpdated({
    VoidCallback? onCompleted,
  }) {
    return AnimatedSuccessFeedback(
      title: 'Profile Updated!',
      subtitle: 'Your changes have been saved successfully',
      onCompleted: onCompleted,
      animationSize: 80,
    );
  }

  /// Address saved
  static Widget addressSaved({
    VoidCallback? onCompleted,
  }) {
    return AnimatedSuccessFeedback(
      title: 'Address Saved!',
      subtitle: 'Your delivery address has been updated',
      onCompleted: onCompleted,
      animationSize: 80,
    );
  }

  /// Item added to cart
  static Widget addedToCart({
    String? productName,
    VoidCallback? onCompleted,
  }) {
    return AnimatedSuccessFeedback(
      title: 'Added to Cart!',
      subtitle: productName != null 
        ? '$productName has been added to your cart'
        : 'Item added to your cart',
      onCompleted: onCompleted,
      animationSize: 60,
      autoDismiss: true,
    );
  }

  /// Generic success message
  static Widget generic({
    required String title,
    String? subtitle,
    VoidCallback? onCompleted,
    double? size,
  }) {
    return AnimatedSuccessFeedback(
      title: title,
      subtitle: subtitle,
      onCompleted: onCompleted,
      animationSize: size,
    );
  }
}

/// Success dialog helper
class SuccessDialog {
  /// Show success dialog with animation
  static Future<void> show(
    BuildContext context, {
    required Widget successWidget,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: successWidget,
        ),
      ),
    );
  }

  /// Show order success dialog
  static Future<void> showOrderSuccess(
    BuildContext context, {
    String? orderNumber,
    VoidCallback? onViewOrder,
    VoidCallback? onContinueShopping,
  }) {
    return show(
      context,
      barrierDismissible: false,
      successWidget: DaylizSuccessAnimations.orderPlaced(
        orderNumber: orderNumber,
        onViewOrder: () {
          Navigator.of(context).pop();
          onViewOrder?.call();
        },
        onContinueShopping: () {
          Navigator.of(context).pop();
          onContinueShopping?.call();
        },
      ),
    );
  }

  /// Show payment success dialog
  static Future<void> showPaymentSuccess(
    BuildContext context, {
    String? amount,
    VoidCallback? onCompleted,
  }) {
    return show(
      context,
      successWidget: DaylizSuccessAnimations.paymentSuccess(
        amount: amount,
        onCompleted: () {
          Navigator.of(context).pop();
          onCompleted?.call();
        },
      ),
    );
  }
}

/// Success snackbar helper
class SuccessSnackbar {
  /// Show success snackbar with icon
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
