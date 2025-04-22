import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/order_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Use case for cancelling an order
class CancelOrderUseCase implements UseCase<bool, CancelOrderParams> {
  final OrderRepository repository;

  CancelOrderUseCase(this.repository);

  /// Execute the use case
  @override
  Future<Either<Failure, bool>> call(CancelOrderParams params) {
    return repository.cancelOrder(params.orderId, reason: params.reason);
  }
}

/// Parameters for CancelOrderUseCase
class CancelOrderParams extends Equatable {
  final String orderId;
  final String? reason;

  const CancelOrderParams({
    required this.orderId,
    this.reason,
  });

  @override
  List<Object?> get props => [orderId, reason];
} 