import 'dart:async';
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/upi_payment_model.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import 'app_logger.dart';
import 'package:logger/logger.dart';

/// Razorpay service for handling UPI and other payment methods
/// Integrates with existing UPI payment service and models
class RazorpayService {
  static RazorpayService? _instance;
  static RazorpayService get instance => _instance ??= RazorpayService._();
  
  RazorpayService._();

  late Razorpay _razorpay;
  final _secureStorage = const FlutterSecureStorage();
  
  // Payment state management
  Completer<PaymentResult>? _paymentCompleter;
  String? _currentOrderId;
  String? _currentRazorpayOrderId;
  
  // Event streams for payment status
  final _paymentStatusController = StreamController<PaymentStatus>.broadcast();
  Stream<PaymentStatus> get paymentStatusStream => _paymentStatusController.stream;

  /// Initialize Razorpay SDK
  Future<void> initialize() async {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      appLogger.service('RazorpayService', 'Initialized successfully');
    } catch (e) {
      appLogger.service('RazorpayService', 'Initialization failed', level: Level.error);
      throw const PaymentException('Failed to initialize payment service');
    }
  }

  /// Start payment process with Razorpay order details
  Future<PaymentResult> startPayment({
    required RazorpayOrderResponse orderResponse,
    required String userEmail,
    required String userPhone,
    required String userName,
  }) async {
    try {
      // Check if we're in mock mode
      final isMockMode = _isMockMode(orderResponse.key);

      if (isMockMode) {
        appLogger.payment('Mock mode detected - simulating payment');
        return await _simulateMockPayment(orderResponse);
      }

      // Save payment state for recovery
      await _savePaymentState(
        orderId: orderResponse.internalOrderId,
        razorpayOrderId: orderResponse.orderId,
        amount: orderResponse.amount / 100, // Convert from paisa to rupees
      );

      _currentOrderId = orderResponse.internalOrderId;
      _currentRazorpayOrderId = orderResponse.orderId;

      // Create payment completer
      _paymentCompleter = Completer<PaymentResult>();

      // Update payment status
      _paymentStatusController.add(PaymentStatus.processing);

      // Check if UPI intent URL is available for direct UPI app launch
      if (orderResponse.upiIntentUrl != null) {
        final launched = await _launchUpiApp(orderResponse.upiIntentUrl!);
        if (!launched) {
          // Fallback to Razorpay checkout if UPI app launch fails
          await _openRazorpayCheckout(orderResponse, userEmail, userPhone, userName);
        }
      } else {
        // Open Razorpay checkout
        await _openRazorpayCheckout(orderResponse, userEmail, userPhone, userName);
      }

      // Wait for payment completion
      return await _paymentCompleter!.future;

    } catch (e) {
      appLogger.payment('Payment start failed', error: e.toString());
      _paymentStatusController.add(PaymentStatus.failed);
      throw PaymentException('Failed to start payment: ${e.toString()}');
    }
  }

  /// Launch UPI app directly using intent URL
  Future<bool> _launchUpiApp(String upiIntentUrl) async {
    try {
      final uri = Uri.parse(upiIntentUrl);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        appLogger.payment('UPI app launched successfully');
        return true;
      } else {
        appLogger.payment('Cannot launch UPI app', error: 'UPI app not available');
        return false;
      }
    } catch (e) {
      appLogger.payment('UPI app launch failed', error: e.toString());
      return false;
    }
  }

  /// Open Razorpay checkout
  Future<void> _openRazorpayCheckout(
    RazorpayOrderResponse orderResponse,
    String userEmail,
    String userPhone,
    String userName,
  ) async {
    final options = {
      'key': orderResponse.key,
      'amount': orderResponse.amount,
      'currency': orderResponse.currency,
      'order_id': orderResponse.orderId,
      'name': AppConstants.appName,
      'description': 'Order payment for ${orderResponse.internalOrderId}',
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#4CAF50', // Green theme matching app
      },
      'modal': {
        'ondismiss': () {
          appLogger.payment('Payment modal dismissed');
          _handlePaymentCancellation();
        },
      },
      'timeout': 900, // 15 minutes timeout
    };

    try {
      _razorpay.open(options);
      appLogger.payment('Razorpay checkout opened');
    } catch (e) {
      appLogger.payment('Failed to open checkout', error: e.toString());
      throw const PaymentException('Failed to open payment checkout');
    }
  }

  /// Handle payment success
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    appLogger.payment('Payment success', paymentId: response.paymentId, status: 'completed');

    final result = PaymentResult(
      success: true,
      paymentId: response.paymentId,
      orderId: _currentOrderId ?? '',
      razorpayOrderId: response.orderId,
      signature: response.signature,
    );

    _paymentStatusController.add(PaymentStatus.completed);
    _paymentCompleter?.complete(result);
    _clearPaymentState();
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    appLogger.payment('Payment error', status: 'failed', error: response.message);

    final result = PaymentResult(
      success: false,
      orderId: _currentOrderId ?? '',
      razorpayOrderId: _currentRazorpayOrderId,
      errorCode: response.code.toString(),
      errorMessage: response.message ?? 'Payment failed',
    );

    _paymentStatusController.add(PaymentStatus.failed);
    _paymentCompleter?.complete(result);
    _clearPaymentState();
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    appLogger.payment('External wallet selected', status: 'processing');

    // For external wallets, we need to handle the flow differently
    // This is typically for wallets like Paytm, PhonePe, etc.
    _paymentStatusController.add(PaymentStatus.processing);
  }

  /// Handle payment cancellation
  void _handlePaymentCancellation() {
    appLogger.payment('Payment cancelled by user', status: 'cancelled');

    final result = PaymentResult(
      success: false,
      orderId: _currentOrderId ?? '',
      razorpayOrderId: _currentRazorpayOrderId,
      errorCode: 'USER_CANCELLED',
      errorMessage: 'Payment cancelled by user',
    );

    _paymentStatusController.add(PaymentStatus.failed);
    _paymentCompleter?.complete(result);
    _clearPaymentState();
  }

  /// Save payment state for recovery
  Future<void> _savePaymentState({
    required String orderId,
    required String razorpayOrderId,
    required double amount,
  }) async {
    final paymentState = {
      'order_id': orderId,
      'razorpay_order_id': razorpayOrderId,
      'amount': amount,
      'initiated_at': DateTime.now().toIso8601String(),
      'status': 'pending',
    };
    
    await _secureStorage.write(
      key: 'pending_payment',
      value: jsonEncode(paymentState),
    );
  }

  /// Check for pending payments on app start
  Future<Map<String, dynamic>?> checkPendingPayment() async {
    try {
      final stateJson = await _secureStorage.read(key: 'pending_payment');
      if (stateJson != null) {
        return jsonDecode(stateJson);
      }
    } catch (e) {
      appLogger.service('RazorpayService', 'Error checking pending payment: ${e.toString()}', level: Level.error);
    }
    return null;
  }

  /// Clear payment state
  Future<void> _clearPaymentState() async {
    try {
      await _secureStorage.delete(key: 'pending_payment');
      _currentOrderId = null;
      _currentRazorpayOrderId = null;
      _paymentCompleter = null;
    } catch (e) {
      appLogger.service('RazorpayService', 'Error clearing payment state: ${e.toString()}', level: Level.error);
    }
  }

  /// Check if we're in mock mode
  bool _isMockMode(String razorpayKey) {
    return razorpayKey.contains('mock') ||
           razorpayKey.startsWith('rzp_test_mock');
  }

  /// Simulate mock payment for testing without backend
  Future<PaymentResult> _simulateMockPayment(RazorpayOrderResponse orderResponse) async {
    try {
      appLogger.payment('Starting mock payment simulation', orderId: orderResponse.internalOrderId);

      // Update payment status to processing
      _paymentStatusController.add(PaymentStatus.processing);

      // Simulate payment processing delay (2-4 seconds)
      await Future.delayed(Duration(seconds: 2 + (DateTime.now().millisecond % 3)));

      // Simulate different payment outcomes (90% success rate)
      final random = DateTime.now().millisecond;
      final isSuccess = random % 10 != 0; // 90% success rate

      if (isSuccess) {
        appLogger.payment('Mock payment successful', orderId: orderResponse.internalOrderId, status: 'completed');
        _paymentStatusController.add(PaymentStatus.completed);

        return PaymentResult(
          success: true,
          paymentId: 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
          orderId: orderResponse.internalOrderId,
          razorpayOrderId: orderResponse.orderId,
          signature: 'mock_signature_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        appLogger.payment('Mock payment failed', orderId: orderResponse.internalOrderId, status: 'failed', error: 'insufficient funds');
        _paymentStatusController.add(PaymentStatus.failed);

        return PaymentResult(
          success: false,
          orderId: orderResponse.internalOrderId,
          errorMessage: 'Mock payment failed - insufficient funds',
        );
      }

    } catch (e) {
      appLogger.payment('Mock payment simulation error', orderId: orderResponse.internalOrderId, error: e.toString());
      _paymentStatusController.add(PaymentStatus.failed);

      return PaymentResult(
        success: false,
        orderId: orderResponse.internalOrderId,
        errorMessage: 'Mock payment simulation failed: ${e.toString()}',
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _razorpay.clear();
    _paymentStatusController.close();
    _clearPaymentState();
  }
}

/// Payment result model
class PaymentResult {
  final bool success;
  final String? paymentId;
  final String orderId;
  final String? razorpayOrderId;
  final String? signature;
  final String? errorCode;
  final String? errorMessage;

  PaymentResult({
    required this.success,
    this.paymentId,
    required this.orderId,
    this.razorpayOrderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'payment_id': paymentId,
    'order_id': orderId,
    'razorpay_order_id': razorpayOrderId,
    'signature': signature,
    'error_code': errorCode,
    'error_message': errorMessage,
  };
}
