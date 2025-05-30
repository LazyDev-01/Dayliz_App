import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/order_repository.dart';
import '../../../core/usecases/usecase.dart';

/// Use case for tracking an order's shipping status
class TrackOrderUseCase implements UseCase<Map<String, dynamic>, TrackOrderParams> {
  final OrderRepository repository;

  TrackOrderUseCase(this.repository);

  /// Execute the use case
  @override
  Future<Either<Failure, Map<String, dynamic>>> call(TrackOrderParams params) {
    return repository.trackOrder(params.orderId);
  }
}

/// Parameters for TrackOrderUseCase
class TrackOrderParams extends Equatable {
  final String orderId;

  const TrackOrderParams({required this.orderId});

  @override
  List<Object> get props => [orderId];
} 