import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/razorpay_service.dart';
import '../../../data/services/upi_payment_service.dart';
import '../../../data/models/upi_payment_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/supabase_providers.dart';
import 'payment_success_screen.dart';
import 'payment_failure_screen.dart';

// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// Payment Status Recovery Screen
/// Handles payment status checking when app is reopened after payment
class PaymentStatusRecoveryScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pendingPayment;

  const PaymentStatusRecoveryScreen({
    super.key,
    required this.pendingPayment,
  });

  @override
  ConsumerState<PaymentStatusRecoveryScreen> createState() => _PaymentStatusRecoveryScreenState();
}

class _PaymentStatusRecoveryScreenState extends ConsumerState<PaymentStatusRecoveryScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'Checking payment status...';
  bool _isChecking = true;
  int _checkAttempts = 0;
  static const int _maxCheckAttempts = 10;
  static const Duration _checkInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStatusCheck();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _startStatusCheck() {
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted || !_isChecking) return;

    try {
      setState(() {
        _checkAttempts++;
        _statusMessage = 'Checking payment status... (${_checkAttempts}/${_maxCheckAttempts})';
      });

      // Get auth token from current user
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _handleStatusCheckFailure('Authentication required');
        return;
      }

      // Get real JWT token from Supabase session
      final supabaseClient = ref.read(supabaseClientProvider);
      final session = supabaseClient.auth.currentSession;
      final authToken = session?.accessToken;

      if (authToken == null) {
        _handleStatusCheckFailure('Authentication token not available. Please login again.');
        return;
      }

      // Get payment details from pending payment
      final orderId = widget.pendingPayment['order_id'] as String;
      final razorpayOrderId = widget.pendingPayment['razorpay_order_id'] as String;
      final amount = widget.pendingPayment['amount'] as double;

      // Check payment status with backend
      final upiService = UpiPaymentService(client: ref.read(httpClientProvider));

      final statusResponse = await upiService.getPaymentStatus(
        orderId: orderId,
        authToken: authToken,
      );

      if (statusResponse.paymentStatus.isCompleted) {
        // Payment was successful
        await _handlePaymentSuccess(statusResponse, orderId, amount);
      } else if (statusResponse.paymentStatus.isFailed) {
        // Payment failed
        await _handlePaymentFailure(statusResponse.failureReason ?? 'Payment failed', orderId);
      } else if (statusResponse.paymentStatus.isProcessing || statusResponse.paymentStatus == PaymentStatus.pending) {
        // Payment still pending, continue checking
        if (_checkAttempts < _maxCheckAttempts) {
          await Future.delayed(_checkInterval);
          _checkPaymentStatus();
        } else {
          // Max attempts reached, treat as timeout
          await _handlePaymentTimeout(orderId);
        }
      } else {
        // Unknown status
        await _handleStatusCheckFailure('Unknown payment status');
      }

    } catch (e) {
      debugPrint('PaymentStatusRecoveryScreen: Status check failed - $e');
      
      if (_checkAttempts < _maxCheckAttempts) {
        // Retry after delay
        await Future.delayed(_checkInterval);
        _checkPaymentStatus();
      } else {
        _handleStatusCheckFailure('Failed to check payment status');
      }
    }
  }

  Future<void> _handlePaymentSuccess(
    PaymentStatusResponse statusResponse,
    String orderId,
    double amount,
  ) async {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Payment confirmed!';
    });

    // Clear pending payment state
    await RazorpayService.instance.checkPendingPayment();

    // Navigate to success screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            orderId: orderId,
            paymentId: statusResponse.paymentId ?? '',
            orderData: {
              'total': amount,
              'status': 'confirmed',
            },
          ),
        ),
      );
    }
  }

  Future<void> _handlePaymentFailure(String errorMessage, String orderId) async {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Payment failed';
    });

    // Clear pending payment state
    await RazorpayService.instance.checkPendingPayment();

    // Navigate to failure screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentFailureScreen(
            orderId: orderId,
            errorMessage: errorMessage,
            orderData: {
              'total': widget.pendingPayment['amount'],
            },
          ),
        ),
      );
    }
  }

  Future<void> _handlePaymentTimeout(String orderId) async {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Payment status check timed out';
    });

    // Clear pending payment state
    await RazorpayService.instance.checkPendingPayment();

    // Navigate to failure screen with timeout message
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentFailureScreen(
            orderId: orderId,
            errorMessage: 'Payment status check timed out. Please contact support if payment was deducted.',
            orderData: {
              'total': widget.pendingPayment['amount'],
            },
          ),
        ),
      );
    }
  }

  Future<void> _handleStatusCheckFailure(String errorMessage) async {
    setState(() {
      _isChecking = false;
      _statusMessage = 'Failed to check payment status';
    });

    // Show error dialog with options
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Payment Status Check Failed'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryStatusCheck();
              },
              child: const Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    }
  }

  void _retryStatusCheck() {
    setState(() {
      _isChecking = true;
      _checkAttempts = 0;
      _statusMessage = 'Retrying payment status check...';
    });
    _checkPaymentStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation during check
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildStatusAnimation(),
                const SizedBox(height: 48),
                _buildStatusMessage(),
                const SizedBox(height: 24),
                _buildPaymentDetails(),
                const Spacer(),
                if (!_isChecking) _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.withOpacity(0.7),
                  Colors.blue,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 5,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.sync,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    return Column(
      children: [
        Text(
          _statusMessage,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'re verifying your payment status. This may take a few moments.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order ID:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                widget.pendingPayment['order_id'] as String,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₹${(widget.pendingPayment['amount'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _retryStatusCheck,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Check Status Again',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.go('/home');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Go to Home',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
