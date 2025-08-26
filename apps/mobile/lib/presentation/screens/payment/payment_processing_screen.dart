import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

import '../../../core/services/razorpay_service.dart';
import '../../../data/models/upi_payment_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/user_profile_providers.dart';
import '../../providers/supabase_providers.dart';


// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) => http.Client());

/// Payment Processing Screen - Separate from Order Processing
/// Handles the actual payment flow after order creation
class PaymentProcessingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final RazorpayOrderResponse razorpayOrder;
  final Map<String, dynamic> orderData;

  const PaymentProcessingScreen({
    super.key,
    required this.orderId,
    required this.razorpayOrder,
    required this.orderData,
  });

  @override
  ConsumerState<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends ConsumerState<PaymentProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  bool _isSuccess = false;
  bool _isError = false;
  String _statusMessage = 'Please do not close the app or go back.';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPaymentProcess();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  void _startPaymentProcess() {
    // Start payment after brief delay
    Future.delayed(const Duration(seconds: 2), () {
      _initiatePayment();
    });
  }

  Future<void> _initiatePayment() async {
    if (!mounted) return;

    try {
      // Payment process started

      // Get user details
      final user = ref.read(currentUserProvider);
      final userProfile = ref.read(userProfileProvider);

      if (user == null) {
        _navigateToFailure('User not authenticated');
        return;
      }

      // Initialize Razorpay service
      await RazorpayService.instance.initialize();

      // Start payment
      final result = await RazorpayService.instance.startPayment(
        orderResponse: widget.razorpayOrder,
        userEmail: user.email ?? '',
        userPhone: user.phone ?? '', // Use phone from user entity
        userName: userProfile?.fullName ?? 'User',
      );

      // Handle payment result
      if (result.success) {
        await _verifyPayment(result);
      } else {
        _navigateToFailure(result.errorMessage ?? 'Payment failed');
      }

    } catch (e) {
      debugPrint('PaymentProcessingScreen: Payment initiation failed - $e');
      _navigateToFailure('Failed to start payment: ${e.toString()}');
    }
  }

  Future<void> _verifyPayment(PaymentResult result) async {
    try {
      // Get auth token from current user
      final user = ref.read(currentUserProvider);
      if (user == null) {
        _navigateToFailure('Authentication required');
        return;
      }

      // Get real JWT token from Supabase session
      final supabaseClient = ref.read(supabaseClientProvider);
      final session = supabaseClient.auth.currentSession;
      final authToken = session?.accessToken;

      if (authToken == null) {
        _navigateToFailure('Authentication token not available. Please login again.');
        return;
      }

      // Mock payment verification (since backend is not running)
      // In a real implementation, this would verify with the backend
      await Future.delayed(const Duration(seconds: 1)); // Simulate verification delay

      // Create mock successful payment response
      final paymentResponse = PaymentResponse(
        success: true,
        orderId: widget.orderId,
        paymentId: result.paymentId,
        status: PaymentStatus.completed,
        message: 'Payment verified successfully',
        razorpayOrderId: result.razorpayOrderId,
      );

      _navigateToSuccess(paymentResponse);

    } catch (e) {
      debugPrint('PaymentProcessingScreen: Payment verification failed - $e');
      _navigateToFailure('Payment verification failed');
    }
  }

  void _navigateToSuccess(PaymentResponse paymentResponse) {
    if (!mounted) return;

    setState(() {
      _isSuccess = true;
      _isError = false;
      _statusMessage = 'Payment successful!';
    });

    // Navigate to order summary after showing success message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        GoRouter.of(context).pushReplacement('/clean/order-summary/${widget.orderId}');
      }
    });
  }

  void _navigateToFailure(String errorMessage) {
    if (!mounted) return;

    setState(() {
      _isSuccess = false;
      _isError = true;
      _statusMessage = 'Payment failed: $errorMessage';
    });

    // Show failure message for longer, then navigate back to payment selection
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        GoRouter.of(context).pop(); // Go back to payment selection
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation during payment
      child: Scaffold(
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
                  _buildPaymentAnimation(),
                  const SizedBox(height: 48),
                  _buildMessageSection(),
                  const Spacer(),
                  _buildSecurityNote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentAnimation() {
    return SizedBox(
      width: 90,
      height: 90,
      child: _isSuccess
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 90,
            )
          : _isError
              ? const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 90,
                )
              : Lottie.asset(
                  'assets/animations/payment_processing.json',
                  repeat: true,
                  animate: true,
                  fit: BoxFit.contain,
                ),
    );
  }

  Widget _buildMessageSection() {
    return Column(
      children: [
        Text(
          _isSuccess
              ? 'Payment Successful!'
              : _isError
                  ? 'Payment Failed'
                  : 'Processing Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _isSuccess
                ? Colors.green
                : _isError
                    ? Colors.red
                    : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _statusMessage,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }



  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.blue[600],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your payment is secured with 256-bit SSL encryption',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
