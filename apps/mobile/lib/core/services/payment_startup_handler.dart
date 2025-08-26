import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/razorpay_service.dart';
import '../../presentation/screens/payment/payment_status_recovery_screen.dart';
import 'app_logger.dart';
import 'package:logger/logger.dart';

/// Payment startup handler for checking pending payments on app launch
class PaymentStartupHandler {
  static PaymentStartupHandler? _instance;
  static PaymentStartupHandler get instance => _instance ??= PaymentStartupHandler._();
  
  PaymentStartupHandler._();

  /// Check for pending payments and handle recovery
  Future<Widget?> checkPendingPaymentOnStartup() async {
    try {
      // Check if there's a pending payment
      final pendingPayment = await RazorpayService.instance.checkPendingPayment();
      
      if (pendingPayment != null) {
        appLogger.payment('Found pending payment', orderId: pendingPayment['order_id']);

        // Check if payment is still within timeout window
        final initiatedAt = DateTime.parse(pendingPayment['initiated_at']);
        final now = DateTime.now();
        final timeDifference = now.difference(initiatedAt);

        // If payment was initiated more than 20 minutes ago, consider it expired
        if (timeDifference.inMinutes > 20) {
          appLogger.payment('Payment expired, clearing state', orderId: pendingPayment['order_id']);
          await _clearExpiredPayment();
          return null;
        }
        
        // Return payment recovery screen
        return PaymentStatusRecoveryScreen(
          pendingPayment: pendingPayment,
        );
      }
      
      return null;
      
    } catch (e) {
      appLogger.service('PaymentStartupHandler', 'Error checking pending payment: ${e.toString()}', level: Level.error);
      // Clear any corrupted payment state
      await _clearExpiredPayment();
      return null;
    }
  }

  /// Clear expired or corrupted payment state
  Future<void> _clearExpiredPayment() async {
    try {
      // Clear the pending payment state
      await RazorpayService.instance.checkPendingPayment();
    } catch (e) {
      appLogger.service('PaymentStartupHandler', 'Error clearing expired payment: ${e.toString()}', level: Level.error);
    }
  }

  /// Initialize Razorpay service if needed
  Future<void> initializePaymentService() async {
    try {
      await RazorpayService.instance.initialize();
      appLogger.service('PaymentStartupHandler', 'Razorpay service initialized');
    } catch (e) {
      appLogger.service('PaymentStartupHandler', 'Failed to initialize Razorpay service: ${e.toString()}', level: Level.error);
    }
  }
}

/// Provider for payment startup handler
final paymentStartupHandlerProvider = Provider<PaymentStartupHandler>((ref) {
  return PaymentStartupHandler.instance;
});
