import 'package:dartz/dartz.dart';

import '../entities/payment_method.dart';
import '../../core/errors/failures.dart';

/// Repository interface for payment method operations
abstract class PaymentMethodRepository {
  /// Retrieves all payment methods for a specific user
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods(String userId);
  
  /// Gets a payment method by id
  Future<Either<Failure, PaymentMethod>> getPaymentMethod(String id);
  
  /// Gets the default payment method for a user
  Future<Either<Failure, PaymentMethod?>> getDefaultPaymentMethod(String userId);
  
  /// Adds a new payment method
  /// If isDefault is true, updates other payment methods to be non-default
  Future<Either<Failure, PaymentMethod>> addPaymentMethod(PaymentMethod paymentMethod);
  
  /// Updates an existing payment method
  Future<Either<Failure, PaymentMethod>> updatePaymentMethod(PaymentMethod paymentMethod);
  
  /// Deletes a payment method by id
  Future<Either<Failure, bool>> deletePaymentMethod(String id);
  
  /// Sets a payment method as the default for a user
  /// Returns the updated payment method
  Future<Either<Failure, PaymentMethod>> setDefaultPaymentMethod(String id, String userId);
} 