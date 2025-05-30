import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';
import '../datasources/payment_method_local_data_source.dart';
import '../datasources/payment_method_remote_data_source.dart';
import '../models/payment_method_model.dart';

class PaymentMethodRepositoryImpl implements PaymentMethodRepository {
  final PaymentMethodRemoteDataSource remoteDataSource;
  final PaymentMethodLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PaymentMethodRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PaymentMethod>>> getPaymentMethods(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMethods = await remoteDataSource.getPaymentMethods(userId);
        await localDataSource.cachePaymentMethods(userId, remoteMethods);
        return Right(remoteMethods);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localMethods = await localDataSource.getPaymentMethods(userId);
        return Right(localMethods);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> getPaymentMethod(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteMethod = await remoteDataSource.getPaymentMethod(id);
        await localDataSource.cachePaymentMethod(remoteMethod);
        return Right(remoteMethod);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localMethod = await localDataSource.getPaymentMethod(id);
        return Right(localMethod);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, PaymentMethod?>> getDefaultPaymentMethod(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final defaultMethod = await remoteDataSource.getDefaultPaymentMethod(userId);
        if (defaultMethod != null) {
          await localDataSource.cachePaymentMethod(defaultMethod);
        }
        return Right(defaultMethod);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final defaultMethod = await localDataSource.getDefaultPaymentMethod(userId);
        return Right(defaultMethod);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> addPaymentMethod(PaymentMethod paymentMethod) async {
    if (await networkInfo.isConnected) {
      try {
        final methodModel = PaymentMethodModel.fromEntity(paymentMethod);
        final addedMethod = await remoteDataSource.addPaymentMethod(methodModel);
        await localDataSource.cachePaymentMethod(addedMethod);
        return Right(addedMethod);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> updatePaymentMethod(PaymentMethod paymentMethod) async {
    if (await networkInfo.isConnected) {
      try {
        final methodModel = PaymentMethodModel.fromEntity(paymentMethod);
        final updatedMethod = await remoteDataSource.updatePaymentMethod(methodModel);
        await localDataSource.cachePaymentMethod(updatedMethod);
        return Right(updatedMethod);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> deletePaymentMethod(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.deletePaymentMethod(id);
        if (result) {
          await localDataSource.removePaymentMethod(id);
        }
        return Right(result);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, PaymentMethod>> setDefaultPaymentMethod(String id, String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedMethod = await remoteDataSource.setDefaultPaymentMethod(id, userId);
        await localDataSource.cachePaymentMethod(updatedMethod);
        
        // Update cached payment methods to reflect the change
        final allMethods = await localDataSource.getPaymentMethods(userId);
        final updatedMethods = allMethods.map((method) {
          if (method.id != id && method.userId == userId) {
            return PaymentMethodModel.fromEntity(method).copyWithModel(isDefault: false);
          }
          return method;
        }).toList();
        await localDataSource.cachePaymentMethods(userId, updatedMethods);
        
        return Right(updatedMethod);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }
} 