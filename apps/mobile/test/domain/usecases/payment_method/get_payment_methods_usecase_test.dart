import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/payment_method.dart';
import 'package:dayliz_app/domain/repositories/payment_method_repository.dart';
import 'package:dayliz_app/domain/usecases/payment_method/get_payment_methods_usecase.dart';

// Manual mock class
class MockPaymentMethodRepository extends Mock implements PaymentMethodRepository {}

void main() {
  late GetPaymentMethodsUseCase usecase;
  late MockPaymentMethodRepository mockPaymentMethodRepository;

  setUp(() {
    mockPaymentMethodRepository = MockPaymentMethodRepository();
    usecase = GetPaymentMethodsUseCase(mockPaymentMethodRepository);
  });

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

  const tPaymentMethods = [tPaymentMethod1, tPaymentMethod2];

  test('should get payment methods from the repository', () async {
    // arrange
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Right(tPaymentMethods));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right(tPaymentMethods));
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should return failure when repository call fails', () async {
    // arrange
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Server error')));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Server error')));
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should return empty list when no payment methods found', () async {
    // arrange
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right([]));
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should return network failure when device is offline', () async {
    // arrange
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Left(NetworkFailure(message: 'No internet connection')));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(NetworkFailure(message: 'No internet connection')));
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should return cache failure when no cached data available', () async {
    // arrange
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Left(CacheFailure(message: 'No cached payment methods')));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Left(CacheFailure(message: 'No cached payment methods')));
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should handle different payment method types', () async {
    // arrange
    const tCodPaymentMethod = PaymentMethod(
      id: 'payment-method-3',
      userId: tUserId,
      type: PaymentMethod.typeCod,
      name: 'Cash on Delivery',
      isDefault: false,
      details: {},
    );

    const tDebitCardPaymentMethod = PaymentMethod(
      id: 'payment-method-4',
      userId: tUserId,
      type: PaymentMethod.typeDebitCard,
      name: 'Work Debit Card',
      isDefault: false,
      details: {
        'cardNumber': '5353',
        'cardHolderName': 'John Doe',
        'expiryDate': '10/26',
        'cardType': 'mastercard',
        'last4': '5353',
        'brand': 'mastercard',
      },
    );

    const tMixedPaymentMethods = [
      tPaymentMethod1,
      tPaymentMethod2,
      tCodPaymentMethod,
      tDebitCardPaymentMethod,
    ];

    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Right(tMixedPaymentMethods));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right(tMixedPaymentMethods));
    result.fold(
      (failure) => fail('Should return payment methods'),
      (methods) {
        expect(methods.length, 4);
        expect(methods[0].type, PaymentMethod.typeCreditCard);
        expect(methods[1].type, PaymentMethod.typeUpi);
        expect(methods[2].type, PaymentMethod.typeCod);
        expect(methods[3].type, PaymentMethod.typeDebitCard);
      },
    );
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should handle payment methods with default status', () async {
    // arrange
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Right(tPaymentMethods));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right(tPaymentMethods));
    result.fold(
      (failure) => fail('Should return payment methods'),
      (methods) {
        expect(methods.length, 2);
        expect(methods[0].isDefault, true);
        expect(methods[1].isDefault, false);
      },
    );
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should handle payment methods with different card details', () async {
    // arrange
    const tPaymentMethodWithDetails = PaymentMethod(
      id: 'payment-method-detailed',
      userId: tUserId,
      type: PaymentMethod.typeCreditCard,
      name: 'Premium Card',
      isDefault: false,
      details: {
        'cardNumber': '1234',
        'cardHolderName': 'Jane Smith',
        'expiryDate': '06/27',
        'cardType': 'amex',
        'last4': '1234',
        'brand': 'american_express',
        'cvv': '123',
      },
    );

    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => Right([tPaymentMethodWithDetails]));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, Right([tPaymentMethodWithDetails]));
    result.fold(
      (failure) => fail('Should return payment methods'),
      (methods) {
        expect(methods.length, 1);
        expect(methods[0].details['cardHolderName'], 'Jane Smith');
        expect(methods[0].details['brand'], 'american_express');
        expect(methods[0].maskedCardNumber, '**** **** **** 1234');
      },
    );
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should handle empty user id', () async {
    // arrange
    const emptyUserId = '';
    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid user ID')));

    // act
    final result = await usecase(emptyUserId);

    // assert
    expect(result, const Left(ServerFailure(message: 'Invalid user ID')));
    verify(mockPaymentMethodRepository.getPaymentMethods(emptyUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });

  test('should handle payment methods with UPI details', () async {
    // arrange
    const tUpiPaymentMethod = PaymentMethod(
      id: 'upi-payment-method',
      userId: tUserId,
      type: PaymentMethod.typeUpi,
      name: 'Primary UPI',
      isDefault: true,
      details: {
        'upiId': 'user@paytm',
        'provider': 'paytm',
      },
    );

    when(mockPaymentMethodRepository.getPaymentMethods(any))
        .thenAnswer((_) async => const Right([tUpiPaymentMethod]));

    // act
    final result = await usecase(tUserId);

    // assert
    expect(result, const Right([tUpiPaymentMethod]));
    result.fold(
      (failure) => fail('Should return payment methods'),
      (methods) {
        expect(methods.length, 1);
        expect(methods[0].type, PaymentMethod.typeUpi);
        expect(methods[0].upiId, 'user@paytm');
        expect(methods[0].isDefault, true);
      },
    );
    verify(mockPaymentMethodRepository.getPaymentMethods(tUserId));
    verifyNoMoreInteractions(mockPaymentMethodRepository);
  });
}
