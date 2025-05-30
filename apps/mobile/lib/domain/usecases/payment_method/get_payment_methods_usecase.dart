import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/payment_method.dart';
import '../../repositories/payment_method_repository.dart';

class GetPaymentMethodsUseCase implements UseCase<List<PaymentMethod>, String> {
  final PaymentMethodRepository repository;

  GetPaymentMethodsUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentMethod>>> call(String userId) {
    return repository.getPaymentMethods(userId);
  }
} 