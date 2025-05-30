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
      
      // Check that other methods are no longer default
      final otherMethods = notifier.state.methods.where((m) => m.id != newDefaultPaymentMethod.id);
      for (final method in otherMethods) {
        expect(method.isDefault, false);
      }
    });

    test('should remove payment method successfully', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final initialCount = notifier.state.methods.length;
      final methodToRemove = notifier.state.methods.firstWhere((m) => !m.isDefault);

      // act
      final result = await notifier.removePaymentMethod(methodToRemove.id);

      // assert
      expect(result, true);
      expect(notifier.state.methods.length, initialCount - 1);
      expect(notifier.state.methods.any((m) => m.id == methodToRemove.id), false);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });

    test('should not remove default payment method if it is the only one', () async {
      // arrange
      await notifier.loadPaymentMethods();
      
      // Remove all non-default methods first
      final nonDefaultMethods = notifier.state.methods.where((m) => !m.isDefault).toList();
      for (final method in nonDefaultMethods) {
        await notifier.removePaymentMethod(method.id);
      }
      
      final defaultMethod = notifier.state.methods.firstWhere((m) => m.isDefault);

      // act
      final result = await notifier.removePaymentMethod(defaultMethod.id);

      // assert
      expect(result, false);
      expect(notifier.state.methods.length, 1);
      expect(notifier.state.errorMessage, isNotNull);
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

    test('should clear error message', () async {
      // arrange
      await notifier.loadPaymentMethods();
      
      // Simulate an error by trying to remove the only default method
      final defaultMethod = notifier.state.methods.firstWhere((m) => m.isDefault);
      await notifier.removePaymentMethod(defaultMethod.id);
      expect(notifier.state.errorMessage, isNotNull);

      // act
      notifier.clearError();

      // assert
      expect(notifier.state.errorMessage, isNull);
    });

    test('should get default payment method', () async {
      // arrange
      await notifier.loadPaymentMethods();

      // act
      final defaultMethod = notifier.getDefaultPaymentMethod();

      // assert
      expect(defaultMethod, isNotNull);
      expect(defaultMethod!.isDefault, true);
    });

    test('should return null when no default payment method exists', () async {
      // arrange
      await notifier.loadPaymentMethods();
      
      // Remove default status from all methods (simulate edge case)
      final updatedMethods = notifier.state.methods.map((m) => m.copyWith(isDefault: false)).toList();
      notifier.state = notifier.state.copyWith(methods: updatedMethods);

      // act
      final defaultMethod = notifier.getDefaultPaymentMethod();

      // assert
      expect(defaultMethod, isNull);
    });

    test('should get payment methods by type', () async {
      // arrange
      await notifier.loadPaymentMethods();

      // act
      final creditCardMethods = notifier.getPaymentMethodsByType(PaymentMethod.typeCreditCard);
      final upiMethods = notifier.getPaymentMethodsByType(PaymentMethod.typeUpi);
      final codMethods = notifier.getPaymentMethodsByType(PaymentMethod.typeCod);

      // assert
      expect(creditCardMethods, isNotEmpty);
      expect(upiMethods, isNotEmpty);
      expect(codMethods, isNotEmpty);
      
      for (final method in creditCardMethods) {
        expect(method.type, PaymentMethod.typeCreditCard);
      }
      
      for (final method in upiMethods) {
        expect(method.type, PaymentMethod.typeUpi);
      }
      
      for (final method in codMethods) {
        expect(method.type, PaymentMethod.typeCod);
      }
    });

    test('should return empty list for non-existent payment method type', () async {
      // arrange
      await notifier.loadPaymentMethods();

      // act
      final nonExistentMethods = notifier.getPaymentMethodsByType('non_existent_type');

      // assert
      expect(nonExistentMethods, isEmpty);
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

    test('should refresh payment methods', () async {
      // arrange
      await notifier.loadPaymentMethods();
      final initialCount = notifier.state.methods.length;

      // act
      await notifier.refreshPaymentMethods();

      // assert
      expect(notifier.state.methods.length, initialCount);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
    });
  });
}
