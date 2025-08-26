import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../lib/data/services/upi_payment_service.dart';
import '../../../lib/data/models/upi_payment_model.dart';

void main() {
  group('UpiPaymentService', () {
    late UpiPaymentService upiPaymentService;

    setUp(() {
      upiPaymentService = UpiPaymentService(client: http.Client());
    });

    group('Service Initialization', () {
      test('should create service with HTTP client', () {
        expect(upiPaymentService, isA<UpiPaymentService>());
      });
    });

    group('Request Models', () {
      test('should create valid OrderWithPaymentRequest for UPI', () {
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

        expect(request.cartItems.length, equals(1));
        expect(request.paymentMethod, equals(PaymentMethodType.upi));
        expect(request.upiApp, equals(UpiApp.googlepay));
        expect(request.totalAmount, equals(300.0));
      });

      test('should create valid OrderWithPaymentRequest for COD', () {
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

        expect(request.paymentMethod, equals(PaymentMethodType.cod));
        expect(request.upiApp, isNull);
        expect(request.totalAmount, equals(200.0));
      });

      test('should serialize OrderWithPaymentRequest to JSON', () {
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

        final json = request.toJson();

        expect(json['cart_items'], isA<List>());
        expect(json['shipping_address_id'], equals('addr_123'));
        expect(json['payment_method'], equals('upi'));
        expect(json['upi_app'], equals('googlepay'));
        expect(json['total_amount'], equals(300.0));
      });
    });

    group('Payment Verification Models', () {
      test('should create valid PaymentVerificationRequest', () {
        final request = PaymentVerificationRequest(
          razorpayOrderId: 'rzp_test_123',
          razorpayPaymentId: 'pay_test_456',
          razorpaySignature: 'valid_signature_hash',
        );

        expect(request.razorpayOrderId, equals('rzp_test_123'));
        expect(request.razorpayPaymentId, equals('pay_test_456'));
        expect(request.razorpaySignature, equals('valid_signature_hash'));
      });

      test('should serialize PaymentVerificationRequest to JSON', () {
        final request = PaymentVerificationRequest(
          razorpayOrderId: 'rzp_test_123',
          razorpayPaymentId: 'pay_test_456',
          razorpaySignature: 'valid_signature_hash',
        );

        final json = request.toJson();

        expect(json['razorpay_order_id'], equals('rzp_test_123'));
        expect(json['razorpay_payment_id'], equals('pay_test_456'));
        expect(json['razorpay_signature'], equals('valid_signature_hash'));
      });
    });
  });
}
