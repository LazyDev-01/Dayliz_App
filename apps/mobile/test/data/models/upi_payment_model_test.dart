import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/models/upi_payment_model.dart';

void main() {
  group('UPI Payment Models', () {
    group('PaymentMethodType', () {
      test('should have correct enum values', () {
        expect(PaymentMethodType.upi.value, equals('upi'));
        expect(PaymentMethodType.cod.value, equals('cod'));
        expect(PaymentMethodType.card.value, equals('card'));
        expect(PaymentMethodType.wallet.value, equals('wallet'));
      });
    });

    group('UpiApp', () {
      test('should have correct enum values', () {
        expect(UpiApp.googlepay.value, equals('googlepay'));
        expect(UpiApp.phonepe.value, equals('phonepe'));
        expect(UpiApp.paytm.value, equals('paytm'));
        expect(UpiApp.other.value, equals('other'));
      });

      test('should have correct display names', () {
        expect(UpiApp.googlepay.displayName, equals('Google Pay'));
        expect(UpiApp.phonepe.displayName, equals('PhonePe'));
        expect(UpiApp.paytm.displayName, equals('Paytm'));
        expect(UpiApp.other.displayName, equals('Other UPI'));
      });

      test('should have correct icon assets', () {
        expect(UpiApp.googlepay.iconAsset, contains('googlepay.png'));
        expect(UpiApp.phonepe.iconAsset, contains('phonepe.png'));
        expect(UpiApp.paytm.iconAsset, contains('paytm.png'));
        expect(UpiApp.other.iconAsset, contains('upi.png'));
      });
    });

    group('PaymentStatus', () {
      test('should have correct enum values', () {
        expect(PaymentStatus.pending.value, equals('pending'));
        expect(PaymentStatus.processing.value, equals('payment_processing'));
        expect(PaymentStatus.completed.value, equals('completed'));
        expect(PaymentStatus.failed.value, equals('payment_failed'));
        expect(PaymentStatus.timeout.value, equals('payment_timeout'));
        expect(PaymentStatus.refunded.value, equals('refunded'));
      });

      test('should identify status correctly', () {
        expect(PaymentStatus.completed.isCompleted, isTrue);
        expect(PaymentStatus.pending.isCompleted, isFalse);

        expect(PaymentStatus.failed.isFailed, isTrue);
        expect(PaymentStatus.timeout.isFailed, isTrue);
        expect(PaymentStatus.completed.isFailed, isFalse);

        expect(PaymentStatus.processing.isProcessing, isTrue);
        expect(PaymentStatus.pending.isProcessing, isFalse);

        expect(PaymentStatus.failed.canRetry, isTrue);
        expect(PaymentStatus.timeout.canRetry, isTrue);
        expect(PaymentStatus.completed.canRetry, isFalse);
      });
    });

    group('RazorpayOrderResponse', () {
      test('should create valid order response', () {
        // Arrange & Act
        final order = RazorpayOrderResponse(
          orderId: 'rzp_test_123',
          currency: 'INR',
          amount: 10000,
          key: 'rzp_test_key',
          internalOrderId: 'internal_123',
          upiIntentUrl: 'upi://pay?pa=test@upi',
          timeoutAt: DateTime.now().add(const Duration(minutes: 15)),
        );

        // Assert
        expect(order.orderId, equals('rzp_test_123'));
        expect(order.currency, equals('INR'));
        expect(order.amount, equals(10000));
        expect(order.key, equals('rzp_test_key'));
        expect(order.internalOrderId, equals('internal_123'));
        expect(order.upiIntentUrl, equals('upi://pay?pa=test@upi'));
        expect(order.timeoutAt, isA<DateTime>());
      });

      test('should handle null upi_intent_url', () {
        // Arrange & Act
        final order = RazorpayOrderResponse(
          orderId: 'rzp_test_123',
          currency: 'INR',
          amount: 10000,
          key: 'rzp_test_key',
          internalOrderId: 'internal_123',
          upiIntentUrl: null,
          timeoutAt: DateTime.now().add(const Duration(minutes: 15)),
        );

        // Assert
        expect(order.upiIntentUrl, isNull);
      });
    });

    group('OrderWithPaymentRequest', () {
      test('should create valid UPI request', () {
        // Arrange & Act
        final request = OrderWithPaymentRequest(
          cartItems: [
            {
              'product_id': 'prod_123',
              'name': 'Test Product',
              'quantity': 2,
              'price': 150.0,
              'image_url': 'https://example.com/image.jpg',
            }
          ],
          shippingAddressId: 'addr_123',
          paymentMethod: PaymentMethodType.upi,
          upiApp: UpiApp.googlepay,
          totalAmount: 300.0,
        );

        // Assert
        expect(request.cartItems.length, equals(1));
        expect(request.paymentMethod, equals(PaymentMethodType.upi));
        expect(request.upiApp, equals(UpiApp.googlepay));
        expect(request.totalAmount, equals(300.0));
      });

      test('should create valid COD request', () {
        // Arrange & Act
        final request = OrderWithPaymentRequest(
          cartItems: [
            {
              'product_id': 'prod_123',
              'name': 'Test Product',
              'quantity': 1,
              'price': 200.0,
              'image_url': 'https://example.com/image.jpg',
            }
          ],
          shippingAddressId: 'addr_123',
          paymentMethod: PaymentMethodType.cod,
          upiApp: null,
          totalAmount: 200.0,
        );

        // Assert
        expect(request.paymentMethod, equals(PaymentMethodType.cod));
        expect(request.upiApp, isNull);
      });

      test('should serialize to JSON correctly', () {
        // Arrange
        final request = OrderWithPaymentRequest(
          cartItems: [
            {
              'product_id': 'prod_123',
              'name': 'Test Product',
              'quantity': 2,
              'price': 150.0,
              'image_url': 'https://example.com/image.jpg',
            }
          ],
          shippingAddressId: 'addr_123',
          paymentMethod: PaymentMethodType.upi,
          upiApp: UpiApp.googlepay,
          totalAmount: 300.0,
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['cart_items'], isA<List>());
        expect(json['shipping_address_id'], equals('addr_123'));
        expect(json['payment_method'], equals('upi'));
        expect(json['upi_app'], equals('googlepay'));
        expect(json['total_amount'], equals(300.0));
      });


    });

    group('PaymentVerificationRequest', () {
      test('should create valid verification request', () {
        // Arrange & Act
        final request = PaymentVerificationRequest(
          razorpayOrderId: 'rzp_test_123',
          razorpayPaymentId: 'pay_test_456',
          razorpaySignature: 'valid_signature_hash',
        );

        // Assert
        expect(request.razorpayOrderId, equals('rzp_test_123'));
        expect(request.razorpayPaymentId, equals('pay_test_456'));
        expect(request.razorpaySignature, equals('valid_signature_hash'));
      });

      test('should serialize to JSON correctly', () {
        // Arrange
        final request = PaymentVerificationRequest(
          razorpayOrderId: 'rzp_test_123',
          razorpayPaymentId: 'pay_test_456',
          razorpaySignature: 'valid_signature_hash',
        );

        // Act
        final json = request.toJson();

        // Assert
        expect(json['razorpay_order_id'], equals('rzp_test_123'));
        expect(json['razorpay_payment_id'], equals('pay_test_456'));
        expect(json['razorpay_signature'], equals('valid_signature_hash'));
      });
    });
  });
}
