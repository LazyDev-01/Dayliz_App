import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/payment_method.dart';

// Get the service locator instance
final sl = GetIt.instance;

/// Payment method state class to manage payment method-related state
class PaymentMethodState {
  final bool isLoading;
  final String? errorMessage;
  final List<PaymentMethod> methods;
  final PaymentMethod? selectedMethod;

  PaymentMethodState({
    this.isLoading = false,
    this.errorMessage,
    this.methods = const [],
    this.selectedMethod,
  });

  PaymentMethodState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<PaymentMethod>? methods,
    PaymentMethod? selectedMethod,
  }) {
    return PaymentMethodState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      methods: methods ?? this.methods,
      selectedMethod: selectedMethod ?? this.selectedMethod,
    );
  }
}

/// Payment method notifier for handling payment method operations
class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  final String userId;

  PaymentMethodNotifier({
    required this.userId,
  }) : super(PaymentMethodState()) {
    // Initialize payment method data
    loadPaymentMethods();
  }

  /// Load all payment methods for the user
  Future<void> loadPaymentMethods() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // Simulated data for now
    // TODO: Replace with actual repository call
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final methods = [
        PaymentMethod(
          id: '1',
          userId: userId,
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
        ),
        PaymentMethod(
          id: '2',
          userId: userId,
          type: PaymentMethod.typeCreditCard,
          name: 'Work Mastercard',
          isDefault: false,
          details: {
            'cardNumber': '5353',
            'cardHolderName': 'John Doe',
            'expiryDate': '10/26',
            'cardType': 'mastercard',
            'last4': '5353',
            'brand': 'mastercard',
          },
        ),
        PaymentMethod(
          id: '3',
          userId: userId,
          type: PaymentMethod.typeUpi,
          name: 'UPI Payment',
          isDefault: false,
          details: {
            'upiId': 'johndoe@upi',
          },
        ),
        PaymentMethod(
          id: '4',
          userId: userId,
          type: PaymentMethod.typeCod,
          name: 'Cash on Delivery',
          isDefault: false,
          details: {},
        ),
      ];

      // Set default selected method
      final defaultMethod = methods.firstWhere(
        (method) => method.isDefault,
        orElse: () => methods.first
      );

      state = state.copyWith(
        isLoading: false,
        methods: methods,
        selectedMethod: defaultMethod,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load payment methods: $e',
      );
    }
  }

  /// Add a new payment method
  Future<bool> addPaymentMethod(PaymentMethod method) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // TODO: Replace with actual repository call
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      // Simulate adding a new method
      final newMethod = PaymentMethod(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: method.userId,
        type: method.type,
        name: method.name,
        isDefault: method.isDefault,
        details: method.details,
      );

      // If this is the first method or set as default, update other methods
      final updatedMethods = [...state.methods];
      if (newMethod.isDefault) {
        for (var i = 0; i < updatedMethods.length; i++) {
          if (updatedMethods[i].isDefault) {
            updatedMethods[i] = updatedMethods[i].copyWith(isDefault: false);
          }
        }
      }

      updatedMethods.add(newMethod);

      state = state.copyWith(
        isLoading: false,
        methods: updatedMethods,
        selectedMethod: newMethod.isDefault ? newMethod : state.selectedMethod,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to add payment method: $e',
      );
      return false;
    }
  }

  /// Delete a payment method
  Future<bool> deletePaymentMethod(String methodId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // TODO: Replace with actual repository call
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final updatedMethods = state.methods.where((m) => m.id != methodId).toList();

      // If we deleted the selected method, select a new one
      PaymentMethod? newSelectedMethod = state.selectedMethod;
      if (state.selectedMethod?.id == methodId) {
        newSelectedMethod = updatedMethods.isNotEmpty ? updatedMethods.first : null;
      }

      state = state.copyWith(
        isLoading: false,
        methods: updatedMethods,
        selectedMethod: newSelectedMethod,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete payment method: $e',
      );
      return false;
    }
  }

  /// Set a payment method as selected
  void selectPaymentMethod(String methodId) {
    final method = state.methods.firstWhere((m) => m.id == methodId);
    state = state.copyWith(selectedMethod: method);
  }

  /// Set a payment method as default
  Future<bool> setDefaultPaymentMethod(String methodId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    // TODO: Replace with actual repository call
    await Future.delayed(const Duration(milliseconds: 800));

    try {
      final updatedMethods = [...state.methods];

      for (var i = 0; i < updatedMethods.length; i++) {
        if (updatedMethods[i].id == methodId) {
          updatedMethods[i] = updatedMethods[i].copyWith(isDefault: true);
        } else if (updatedMethods[i].isDefault) {
          updatedMethods[i] = updatedMethods[i].copyWith(isDefault: false);
        }
      }

      // Find the new default method
      final defaultMethod = updatedMethods.firstWhere((m) => m.id == methodId);

      state = state.copyWith(
        isLoading: false,
        methods: updatedMethods,
        selectedMethod: defaultMethod,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to set default payment method: $e',
      );
      return false;
    }
  }
}

/// Helper to map failures to user-friendly messages
String _mapFailureToMessage(Failure failure) {
  switch (failure.runtimeType) {
    case ServerFailure:
      return 'Server error occurred. Please try again later.';
    case NetworkFailure:
      return 'Network error. Please check your internet connection.';
    case CacheFailure:
      return 'Error retrieving local data. Please restart the app.';
    default:
      return failure.message;
  }
}

/// Payment method providers

/// Main payment method state provider (dependent on user ID)
final paymentMethodNotifierProvider = StateNotifierProvider.family<PaymentMethodNotifier, PaymentMethodState, String>(
  (ref, userId) => PaymentMethodNotifier(userId: userId),
);

/// Payment methods list provider
final paymentMethodsProvider = Provider.family<List<PaymentMethod>, String>((ref, userId) {
  return ref.watch(paymentMethodNotifierProvider(userId)).methods;
});

/// Selected payment method provider
final selectedPaymentMethodProvider = Provider.family<PaymentMethod?, String>((ref, userId) {
  return ref.watch(paymentMethodNotifierProvider(userId)).selectedMethod;
});

/// Payment method loading state provider
final paymentMethodLoadingProvider = Provider.family<bool, String>((ref, userId) {
  return ref.watch(paymentMethodNotifierProvider(userId)).isLoading;
});

/// Payment method error message provider
final paymentMethodErrorProvider = Provider.family<String?, String>((ref, userId) {
  return ref.watch(paymentMethodNotifierProvider(userId)).errorMessage;
});