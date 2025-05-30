import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/payment_method.dart';
import '../../repositories/payment_method_repository.dart';

class AddPaymentMethodUseCase implements UseCase<PaymentMethod, PaymentMethod> {
  final PaymentMethodRepository repository;

  AddPaymentMethodUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentMethod>> call(PaymentMethod paymentMethod) {
    return repository.addPaymentMethod(paymentMethod);
  }
} 