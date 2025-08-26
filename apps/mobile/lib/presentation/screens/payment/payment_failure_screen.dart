import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/upi_payment_model.dart';
import 'payment_processing_screen.dart';

/// Payment Failure Screen
/// Shows payment failure with retry options and helpful guidance
class PaymentFailureScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String errorMessage;
  final Map<String, dynamic> orderData;
  final RazorpayOrderResponse? razorpayOrder;

  const PaymentFailureScreen({
    super.key,
    required this.orderId,
    required this.errorMessage,
    required this.orderData,
    this.razorpayOrder,
  });

  @override
  ConsumerState<PaymentFailureScreen> createState() => _PaymentFailureScreenState();
}

class _PaymentFailureScreenState extends ConsumerState<PaymentFailureScreen>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _fadeController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _fadeAnimation;

  bool _isRetrying = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _shakeController.forward();
        _fadeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildFailureAnimation(),
                const SizedBox(height: 48),
                _buildFailureMessage(),
                const SizedBox(height: 32),
                _buildErrorDetails(),
                const SizedBox(height: 32),
                _buildHelpfulTips(),
                const Spacer(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFailureAnimation() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            20 * _shakeAnimation.value * (1 - _shakeAnimation.value) * 4,
            0,
          ),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red[400],
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFailureMessage() {
    return Column(
      children: [
        const Text(
          'Payment Failed',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Don\'t worry! Your order is saved and you can try again.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorDetails() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Error Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getFormattedErrorMessage(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order ID: ${widget.orderId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpfulTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Helpful Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._getHelpfulTips().map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: TextStyle(color: Colors.blue[600]),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Retry Payment Button
        if (_retryCount < _maxRetries && widget.razorpayOrder != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isRetrying ? null : _retryPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isRetrying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Retry Payment (${_maxRetries - _retryCount} attempts left)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        
        if (_retryCount < _maxRetries && widget.razorpayOrder != null)
          const SizedBox(height: 16),
        
        // Try Different Payment Method Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.go('/checkout/payment-selection');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Different Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Back to Cart Button
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              context.go('/cart');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Back to Cart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Contact Support
        TextButton.icon(
          onPressed: () {
            _contactSupport();
          },
          icon: const Icon(Icons.support_agent, size: 20),
          label: const Text('Contact Support'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getFormattedErrorMessage() {
    // Format common error messages to be more user-friendly
    final message = widget.errorMessage.toLowerCase();
    
    if (message.contains('cancelled') || message.contains('user_cancelled')) {
      return 'Payment was cancelled. You can try again when ready.';
    } else if (message.contains('timeout')) {
      return 'Payment timed out. Please check your internet connection and try again.';
    } else if (message.contains('insufficient')) {
      return 'Insufficient balance in your account. Please check your balance and try again.';
    } else if (message.contains('network')) {
      return 'Network error occurred. Please check your internet connection.';
    } else if (message.contains('invalid')) {
      return 'Invalid payment details. Please try again with correct information.';
    } else {
      return widget.errorMessage;
    }
  }

  List<String> _getHelpfulTips() {
    final message = widget.errorMessage.toLowerCase();
    
    if (message.contains('cancelled')) {
      return [
        'Make sure to complete the payment in your UPI app',
        'Don\'t close the payment screen until completion',
        'Check if your UPI app is working properly',
      ];
    } else if (message.contains('timeout')) {
      return [
        'Ensure you have a stable internet connection',
        'Try switching between WiFi and mobile data',
        'Complete payment within 15 minutes',
      ];
    } else if (message.contains('insufficient')) {
      return [
        'Check your bank account balance',
        'Ensure your UPI app is linked to an active account',
        'Try using a different payment method',
      ];
    } else {
      return [
        'Check your internet connection',
        'Ensure your UPI app is updated',
        'Try using a different payment method',
        'Contact your bank if the issue persists',
      ];
    }
  }

  void _retryPayment() async {
    if (_isRetrying || widget.razorpayOrder == null) return;

    setState(() {
      _isRetrying = true;
      _retryCount++;
    });

    try {
      // Navigate back to payment processing screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentProcessingScreen(
            orderId: widget.orderId,
            razorpayOrder: widget.razorpayOrder!,
            orderData: widget.orderData,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isRetrying = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to retry payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _contactSupport() {
    // TODO: Implement support contact functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support contact will be available soon'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
