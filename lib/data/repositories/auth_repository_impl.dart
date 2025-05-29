import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_local_data_source.dart';



/// Implementation of [AuthRepository] that manages the authentication process
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource remoteDataSource;
  final AuthDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, domain.User>> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        debugPrint('🔄 [AuthRepository] Attempting login for email: $email');
        // Note: We're not passing rememberMe to the data source yet
        // This would require updating the data source interface
        final user = await remoteDataSource.login(email, password);

        // Only cache the user if rememberMe is true
        if (rememberMe) {
          await localDataSource.cacheUser(user);
        }

        debugPrint('✅ [AuthRepository] Login successful');
        return Right(user);
      } on AuthException catch (e) {
        debugPrint('🔍 [AuthRepository] Caught AuthException: ${e.message}');
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        debugPrint('🔍 [AuthRepository] Caught ServerException: ${e.message}');
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        debugPrint('🔍 [AuthRepository] Caught generic exception: ${e.toString()}');
        debugPrint('🔍 [AuthRepository] Exception type: ${e.runtimeType}');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, domain.User>> signInWithGoogle() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.signInWithGoogle();

        // Cache the user locally
        await localDataSource.cacheUser(user);

        return Right(user);
      } on UserCancellationException catch (e) {
        // CRITICAL FIX: Handle user cancellation gracefully
        return Left(UserCancellationFailure(message: e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, domain.User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await remoteDataSource.register(email, password, name, phone: phone);

        // Cache user locally if remote registration was successful
        if (localDataSource is AuthLocalDataSourceImpl) {
          await (localDataSource as AuthLocalDataSourceImpl).cacheUser(user);
        }
        return Right(user);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      debugPrint('🔄 [AuthRepositoryImpl] Starting logout process');
      debugPrint('🔄 [AuthRepositoryImpl] Calling remote data source logout');
      await remoteDataSource.logout();
      debugPrint('✅ [AuthRepositoryImpl] Remote logout successful');

      debugPrint('🔄 [AuthRepositoryImpl] Calling local data source logout');
      await localDataSource.logout();
      debugPrint('✅ [AuthRepositoryImpl] Local logout successful');

      debugPrint('✅ [AuthRepositoryImpl] Logout completed successfully, returning true');
      return const Right(true);
    } catch (e) {
      debugPrint('❌ [AuthRepositoryImpl] Logout failed: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, domain.User>> getCurrentUser() async {
    try {
      // First try to get user from local storage
      final localUser = await localDataSource.getCurrentUser();
      if (localUser != null) {
        return Right(localUser);
      }

      // If no local user and we have network, try to get from remote
      if (await networkInfo.isConnected) {
        final remoteUser = await remoteDataSource.getCurrentUser();
        if (remoteUser != null) {
          // Cache user locally if remote fetch was successful
          if (localDataSource is AuthLocalDataSourceImpl) {
            await (localDataSource as AuthLocalDataSourceImpl).cacheUser(remoteUser);
          }
          return Right(remoteUser);
        }
      }

      // No user found, throw error
      return const Left(AuthFailure(message: "No authenticated user found"));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      // First check local storage
      final isLocalAuthenticated = await localDataSource.isAuthenticated();
      if (isLocalAuthenticated) {
        return true;
      }

      // If not authenticated locally and we have network, check remote
      if (await networkInfo.isConnected) {
        final isRemoteAuthenticated = await remoteDataSource.isAuthenticated();
        return isRemoteAuthenticated;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, bool>> forgotPassword({required String email}) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.forgotPassword(email);
        return const Right(true);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailExists({required String email}) async {
    if (await networkInfo.isConnected) {
      try {
        final exists = await remoteDataSource.checkEmailExists(email);
        return Right(exists);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.resetPassword(
          token: token,
          newPassword: newPassword,
        );
        return Right(result);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );
        return Right(result);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    if (await networkInfo.isConnected) {
      try {
        final token = await remoteDataSource.refreshToken();
        return Right(token);
      } on AuthException catch (e) {
        return Left(AuthFailure(message: e.message));
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return const Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}