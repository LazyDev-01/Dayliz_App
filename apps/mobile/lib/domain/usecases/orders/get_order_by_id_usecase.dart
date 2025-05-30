import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/order.dart' as domain;
import '../../repositories/order_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Use case for getting an order by ID
class GetOrderByIdUseCase implements UseCase<domain.Order, GetOrderByIdParams> {
  final OrderRepository repository;

  GetOrderByIdUseCase(this.repository);

  /// Execute the use case
  @override
  Future<Either<Failure, domain.Order>> call(GetOrderByIdParams params) {
    return repository.getOrderById(params.orderId);
  }
}

/// Parameters for GetOrderByIdUseCase
class GetOrderByIdParams extends Equatable {
  final String orderId;

  const GetOrderByIdParams({required this.orderId});

  @override
  List<Object> get props => [orderId];
} 