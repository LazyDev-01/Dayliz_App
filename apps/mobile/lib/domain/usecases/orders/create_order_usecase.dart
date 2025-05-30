import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/order.dart' as domain;
import '../../repositories/order_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Use case for creating a new order
class CreateOrderUseCase implements UseCase<domain.Order, CreateOrderParams> {
  final OrderRepository repository;

  CreateOrderUseCase(this.repository);

  /// Execute the use case
  @override
  Future<Either<Failure, domain.Order>> call(CreateOrderParams params) {
    return repository.createOrder(params.order);
  }
}

/// Parameters for CreateOrderUseCase
class CreateOrderParams extends Equatable {
  final domain.Order order;

  const CreateOrderParams({required this.order});

  @override
  List<Object> get props => [order];
} 