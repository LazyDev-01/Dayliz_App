import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../entities/order.dart' as domain;
import '../../repositories/order_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Use case for getting orders by status
class GetOrdersByStatusUseCase implements UseCase<List<domain.Order>, GetOrdersByStatusParams> {
  final OrderRepository repository;

  GetOrdersByStatusUseCase(this.repository);

  /// Execute the use case
  @override
  Future<Either<Failure, List<domain.Order>>> call(GetOrdersByStatusParams params) {
    return repository.getOrdersByStatus(params.status);
  }
}

/// Parameters for GetOrdersByStatusUseCase
class GetOrdersByStatusParams extends Equatable {
  final String status;

  const GetOrdersByStatusParams({required this.status});

  @override
  List<Object> get props => [status];
} 