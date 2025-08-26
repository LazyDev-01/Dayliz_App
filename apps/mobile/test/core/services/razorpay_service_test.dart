import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/services/razorpay_service.dart';
import '../../../lib/data/models/upi_payment_model.dart';

void main() {
  group('RazorpayService', () {
    late RazorpayService razorpayService;

    setUp(() {
      razorpayService = RazorpayService.instance;
    });

    group('Service Initialization', () {
      test('should create singleton instance', () {
        // Test singleton pattern
        final instance1 = RazorpayService.instance;
        final instance2 = RazorpayService.instance;
        expect(instance1, same(instance2));
      });

      test('should have payment status stream', () {
        // Test stream availability
        expect(razorpayService.paymentStatusStream, isA<Stream<PaymentStatus>>());
      });
    });

    group('Payment Models', () {
      test('should create valid RazorpayOrderResponse', () {
        // Test model creation
        final orderResponse = RazorpayOrderResponse(
          orderId: 'rzp_test_123',
          currency: 'INR',
          amount: 10000,
          key: 'rzp_test_key',
          internalOrderId: 'internal_123',
          upiIntentUrl: null,
          timeoutAt: DateTime.now().add(const Duration(minutes: 15)),
        );

        expect(orderResponse.orderId, equals('rzp_test_123'));
        expect(orderResponse.currency, equals('INR'));
        expect(orderResponse.amount, equals(10000));
      });

      test('should handle UPI intent URL', () {
        // Test UPI intent URL handling
        final orderResponse = RazorpayOrderResponse(
          orderId: 'rzp_test_123',
          currency: 'INR',
          amount: 10000,
          key: 'rzp_test_key',
          internalOrderId: 'internal_123',
          upiIntentUrl: 'upi://pay?pa=test@upi&pn=Test&am=100.00&cu=INR',
          timeoutAt: DateTime.now().add(const Duration(minutes: 15)),
        );

        expect(orderResponse.upiIntentUrl, isNotNull);
        expect(orderResponse.upiIntentUrl, contains('upi://pay'));
      });
    });

    group('Payment Status Enum', () {
      test('should have correct payment status values', () {
        expect(PaymentStatus.pending.value, equals('pending'));
        expect(PaymentStatus.processing.value, equals('payment_processing'));
        expect(PaymentStatus.completed.value, equals('completed'));
        expect(PaymentStatus.failed.value, equals('payment_failed'));
        expect(PaymentStatus.timeout.value, equals('payment_timeout'));
      });

      test('should identify completed status correctly', () {
        expect(PaymentStatus.completed.isCompleted, isTrue);
        expect(PaymentStatus.pending.isCompleted, isFalse);
        expect(PaymentStatus.failed.isCompleted, isFalse);
      });

      test('should identify failed status correctly', () {
        expect(PaymentStatus.failed.isFailed, isTrue);
        expect(PaymentStatus.timeout.isFailed, isTrue);
        expect(PaymentStatus.completed.isFailed, isFalse);
        expect(PaymentStatus.pending.isFailed, isFalse);
      });

      test('should identify retry eligibility', () {
        expect(PaymentStatus.failed.canRetry, isTrue);
        expect(PaymentStatus.timeout.canRetry, isTrue);
        expect(PaymentStatus.completed.canRetry, isFalse);
        expect(PaymentStatus.processing.canRetry, isFalse);
      });
    });

    group('UPI App Enum', () {
      test('should have correct UPI app values', () {
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

    group('Stream Management', () {
      test('should provide payment status stream', () {
        // Test stream availability
        expect(razorpayService.paymentStatusStream, isA<Stream<PaymentStatus>>());
      });

      test('should handle stream subscription', () async {
        // Test stream subscription
        final stream = razorpayService.paymentStatusStream;
        final subscription = stream.listen((status) {
          // Handle status updates
        });

        // Clean up
        await subscription.cancel();
      });
    });
  });
}
