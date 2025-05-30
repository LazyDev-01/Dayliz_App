import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/payment_method.dart';
import '../../repositories/payment_method_repository.dart';

class SetDefaultPaymentMethodUseCase implements UseCase<PaymentMethod, SetDefaultParams> {
  final PaymentMethodRepository repository;

  SetDefaultPaymentMethodUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentMethod>> call(SetDefaultParams params) {
    return repository.setDefaultPaymentMethod(params.paymentMethodId, params.userId);
  }
}

class SetDefaultParams extends Equatable {
  final String paymentMethodId;
  final String userId;

  const SetDefaultParams({
    required this.paymentMethodId,
    required this.userId,
  });

  @override
  List<Object> get props => [paymentMethodId, userId];
} 