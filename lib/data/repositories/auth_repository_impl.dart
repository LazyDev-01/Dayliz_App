import 'package:dartz/dartz.dart';
import '../../core/error/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../datasources/auth_local_data_source.dart';

// Add a class for the missing AuthException
class AuthException implements Exception {
  final String message;

  AuthException(this.message);
}

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
        // Note: We're not passing rememberMe to the data source yet
        // This would require updating the data source interface
        final user = await remoteDataSource.login(email, password);

        // Only cache the user if rememberMe is true
        if (rememberMe) {
          await localDataSource.cacheUser(user);
        }

        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
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
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, domain.User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    print('AuthRepositoryImpl: Starting registration for $email');
    print('AuthRepositoryImpl: remoteDataSource = $remoteDataSource');
    print('AuthRepositoryImpl: localDataSource = $localDataSource');
    print('AuthRepositoryImpl: networkInfo = $networkInfo');

    final isConnected = await networkInfo.isConnected;
    print('AuthRepositoryImpl: Network is connected: $isConnected');

    if (isConnected) {
      try {
        print('AuthRepositoryImpl: Calling remoteDataSource.register');
        final user = await remoteDataSource.register(email, password, name, phone: phone);
        print('AuthRepositoryImpl: Registration successful, user ID: ${user.id}');
        print('AuthRepositoryImpl: User details: email=${user.email}, name=${user.name}');

        // Cache user locally if remote registration was successful
        if (localDataSource is AuthLocalDataSourceImpl) {
          print('AuthRepositoryImpl: Caching user locally');
          await (localDataSource as AuthLocalDataSourceImpl).cacheUser(user);
          print('AuthRepositoryImpl: User cached successfully');
        } else {
          print('AuthRepositoryImpl: localDataSource is not AuthLocalDataSourceImpl, skipping caching');
        }
        return Right(user);
      } on ServerException catch (e, stackTrace) {
        print('AuthRepositoryImpl: ServerException: ${e.message}');
        print('AuthRepositoryImpl: Stack trace: $stackTrace');
        return Left(ServerFailure(message: e.message));
      } catch (e, stackTrace) {
        print('AuthRepositoryImpl: Unexpected error: ${e.toString()}');
        print('AuthRepositoryImpl: Stack trace: $stackTrace');
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      print('AuthRepositoryImpl: No internet connection');
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.logout();
      return const Right(true);
    } catch (e) {
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
      return Left(AuthFailure(message: "No authenticated user found"));
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
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
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
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
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
      return Left(NetworkFailure(message: 'No internet connection'));
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
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}