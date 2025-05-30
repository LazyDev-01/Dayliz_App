import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/order.dart' as domain;
import '../../repositories/order_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Use case for getting all orders for the current user
class GetOrdersUseCase implements UseCase<List<domain.Order>, NoParams> {
  final OrderRepository repository;

  GetOrdersUseCase(this.repository);

  /// Execute the use case
  @override
  Future<Either<Failure, List<domain.Order>>> call(NoParams params) {
    return repository.getOrders();
  }
} 