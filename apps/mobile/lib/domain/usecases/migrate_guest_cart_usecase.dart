import 'package:dartz/dartz.dart';

import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

/// Use case for migrating guest cart to authenticated user cart
/// This is called when user logs in or signs up to preserve their cart items
class MigrateGuestCartUseCase implements UseCase<bool, NoParams> {
  final CartRepository repository;

  MigrateGuestCartUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call([NoParams? params]) async {
    return await repository.migrateGuestCartToUser();
  }
}
