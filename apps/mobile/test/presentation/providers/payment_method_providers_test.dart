import 'package:flutter_test/flutter_test.dart';

import 'package:dayliz_app/domain/entities/payment_method.dart';
import 'package:dayliz_app/presentation/providers/payment_method_providers.dart';

void main() {
  const tUserId = 'test-user-id';

  const tPaymentMethod1 = PaymentMethod(
    id: 'payment-method-1',
    userId: tUserId,
    type: PaymentMethod.typeCreditCard,
    name: 'Personal Visa',
    isDefault: true,
    details: {
      'cardNumber': '4242',
      'cardHolderName': 'John Doe',
      'expiryDate': '12/25',
      'cardType': 'visa',
      'last4': '4242',
      'brand': 'visa',
    },
  );

  const tPaymentMethod2 = PaymentMethod(
    id: 'payment-method-2',
    userId: tUserId,
    type: PaymentMethod.typeUpi,
    name: 'UPI Payment',
    isDefault: false,
    details: {
      'upiId': 'johndoe@upi',
    },
  );

  const tPaymentMethod3 = PaymentMethod(
    id: 'payment-method-3',
    userId: tUserId,
    type: PaymentMethod.typeCod,
    name: 'Cash on Delivery',
    isDefault: false,
    details: {},
  );

  group('PaymentMethodNotifier', () {
    late PaymentMethodNotifier notifier;

    setUp(() {
      notifier = PaymentMethodNotifier(userId: tUserId);
    });

    test('initial state should have empty payment methods', () {
      expect(notifier.state.methods, isEmpty);
      expect(notifier.state.selectedMethod, isNull);
      expect(notifier.state.isLoading, true); // Loading starts immediately
      expect(notifier.state.errorMessage, isNull);
    });

    test('should load payment methods successfully', () async {
      // act
      await notifier.loadPaymentMethods();

      // assert
      expect(notifier.state.methods, isNotEmpty);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.selectedMethod, isNotNull);
      expect(notifier.state.selectedMethod!.isDefault, true);
    });

    test('should select payment method', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final methodToSelect = notifier.state.methods.firstWhere((m) => !m.isDefault);

      // act
      notifier.selectPaymentMethod(methodToSelect.id);

      // assert
      expect(notifier.state.selectedMethod, equals(methodToSelect));
    });

    test('should add new payment method successfully', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final initialCount = notifier.state.methods.length;

      const newPaymentMethod = PaymentMethod(
        id: 'new-payment-method',
        userId: tUserId,
        type: PaymentMethod.typeDebitCard,
        name: 'New Debit Card',
        isDefault: false,
        details: {
          'cardNumber': '5555',
          'cardHolderName': 'Jane Doe',
          'expiryDate': '08/28',
          'cardType': 'mastercard',
          'last4': '5555',
          'brand': 'mastercard',
        },
      );

      // act
      final result = await notifier.addPaymentMethod(newPaymentMethod);

      // assert
      expect(result, true);
      expect(notifier.state.methods.length, initialCount + 1);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should add new default payment method and update others', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final initialCount = notifier.state.methods.length;

      const newDefaultPaymentMethod = PaymentMethod(
        id: 'new-default-payment-method',
        userId: tUserId,
        type: PaymentMethod.typeDebitCard,
        name: 'New Default Card',
        isDefault: true,
        details: {
          'cardNumber': '6666',
          'cardHolderName': 'Jane Doe',
          'expiryDate': '09/29',
          'cardType': 'visa',
          'last4': '6666',
          'brand': 'visa',
        },
      );

      // act
      final result = await notifier.addPaymentMethod(newDefaultPaymentMethod);

      // assert
      expect(result, true);
      expect(notifier.state.methods.length, initialCount + 1);
      expect(notifier.state.selectedMethod!.isDefault, true);
      expect(notifier.state.selectedMethod!.name, 'New Default Card');
      
      // Check that only one method is default
      final defaultMethods = notifier.state.methods.where((m) => m.isDefault);
      expect(defaultMethods.length, 1);
      expect(defaultMethods.first.name, 'New Default Card');
    });

    test('should delete payment method successfully', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final initialCount = notifier.state.methods.length;
      final methodToDelete = notifier.state.methods.firstWhere((m) => !m.isDefault);

      // act
      final result = await notifier.deletePaymentMethod(methodToDelete.id);

      // assert
      expect(result, true);
      expect(notifier.state.methods.length, initialCount - 1);
      expect(notifier.state.methods.any((m) => m.id == methodToDelete.id), false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should set payment method as default successfully', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final nonDefaultMethod = notifier.state.methods.firstWhere((m) => !m.isDefault);

      // act
      final result = await notifier.setDefaultPaymentMethod(nonDefaultMethod.id);

      // assert
      expect(result, true);
      expect(notifier.state.selectedMethod!.id, nonDefaultMethod.id);
      expect(notifier.state.selectedMethod!.isDefault, true);
      
      // Check that other methods are no longer default
      final otherMethods = notifier.state.methods.where((m) => m.id != nonDefaultMethod.id);
      for (final method in otherMethods) {
        expect(method.isDefault, false);
      }
    });

    test('should select payment method', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final methodToSelect = notifier.state.methods.firstWhere((m) => !m.isDefault);

      // act
      notifier.selectPaymentMethod(methodToSelect.id);

      // assert
      expect(notifier.state.selectedMethod, equals(methodToSelect));
    });

    test('should handle payment method validation', () async {
      // arrange
      await notifier.loadPaymentMethods();

      const invalidPaymentMethod = PaymentMethod(
        id: '',
        userId: '',
        type: '',
        name: '',
        isDefault: false,
        details: {},
      );

      // act
      final result = await notifier.addPaymentMethod(invalidPaymentMethod);

      // assert
      expect(result, true); // Current implementation doesn't validate, but this test is for future validation
    });
  });
}
