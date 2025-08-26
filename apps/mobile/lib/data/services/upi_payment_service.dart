import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/error/exceptions.dart';
import '../models/upi_payment_model.dart';

/// Service for UPI payment integration with FastAPI backend
class UpiPaymentService {
  final http.Client client;
  final String baseUrl;

  UpiPaymentService({
    required this.client,
    String? baseUrl,
  }) : baseUrl = baseUrl ?? AppConfig.fastApiBaseUrl;

  /// Create order with payment method selection
  Future<OrderCreationResponse> createOrderWithPayment({
    required OrderWithPaymentRequest request,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/payments/create-order-with-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return OrderCreationResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Authentication failed');
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['detail'] ?? 'Order creation failed',
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error occurred');
    }
  }

  /// Get payment status for an order
  Future<PaymentStatusResponse> getPaymentStatus({
    required String orderId,
    required String authToken,
  }) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/api/v1/payments/status/$orderId'),
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentStatusResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Authentication failed');
      } else if (response.statusCode == 404) {
        throw const NotFoundException(message: 'Order not found');
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['detail'] ?? 'Failed to get payment status',
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error occurred');
    }
  }

  /// Retry payment for a failed order
  Future<Map<String, dynamic>> retryPayment({
    required PaymentRetryRequest request,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/payments/retry/${request.orderId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw const AuthException('Authentication failed');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['detail'] ?? 'Payment retry not allowed',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['detail'] ?? 'Payment retry failed',
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error occurred');
    }
  }

  /// Verify payment with Razorpay
  Future<PaymentResponse> verifyPayment({
    required PaymentVerificationRequest request,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/payments/razorpay/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Authentication failed');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['detail'] ?? 'Payment verification failed',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['detail'] ?? 'Payment verification failed',
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error occurred');
    }
  }

  /// Process Cash on Delivery payment
  Future<PaymentResponse> processCodPayment({
    required String orderId,
    required String authToken,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/payments/cod/process'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({'order_id': orderId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Authentication failed');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['detail'] ?? 'COD payment processing failed',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['detail'] ?? 'COD payment processing failed',
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error occurred');
    }
  }

  /// Create Razorpay order (legacy endpoint for compatibility)
  Future<RazorpayOrderResponse> createRazorpayOrder({
    required String internalOrderId,
    required double amount,
    required String authToken,
    UpiApp? upiApp,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/api/v1/payments/razorpay/create-order'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'internal_order_id': internalOrderId,
          'amount': amount,
          'upi_app': upiApp?.value,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RazorpayOrderResponse.fromJson(data);
      } else if (response.statusCode == 401) {
        throw const AuthException('Authentication failed');
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['detail'] ?? 'Invalid payment amount',
        );
      } else {
        final errorData = json.decode(response.body);
        throw ServerException(
          errorData['detail'] ?? 'Razorpay order creation failed',
        );
      }
    } on SocketException {
      throw NetworkException('No internet connection');
    } catch (e) {
      if (e is AppException) rethrow;
      throw ServerException('Unexpected error occurred');
    }
  }

  /// Check if UPI app is installed
  Future<bool> isUpiAppInstalled(UpiApp upiApp) async {
    // This would use platform-specific code to check if UPI apps are installed
    // For now, return true as a placeholder
    return true;
  }

  /// Get available UPI apps
  Future<List<UpiApp>> getAvailableUpiApps() async {
    // This would check which UPI apps are installed on the device
    // For now, return all apps as available
    return UpiApp.values;
  }

  /// Generate UPI intent URL
  String generateUpiIntentUrl({
    required String merchantVpa,
    required String merchantName,
    required double amount,
    required String transactionNote,
    UpiApp? upiApp,
  }) {
    final baseUrl = 'upi://pay?pa=$merchantVpa&pn=$merchantName&am=$amount&cu=INR&tn=$transactionNote';
    
    switch (upiApp) {
      case UpiApp.googlepay:
        return 'tez://$baseUrl';
      case UpiApp.phonepe:
        return 'phonepe://$baseUrl';
      case UpiApp.paytm:
        return 'paytmmp://$baseUrl';
      default:
        return baseUrl;
    }
  }
}
