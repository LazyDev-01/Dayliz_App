import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/data/models/user_model.dart';
import 'package:dayliz_app/domain/entities/user.dart';
import 'package:dayliz_app/domain/repositories/auth_repository.dart';

// Create a fake implementation of AuthRepository for testing
class FakeAuthRepository implements AuthRepository {
  bool _isOnline = true;
  bool _shouldSucceed = true;

  void setNetworkStatus(bool isOnline) {
    _isOnline = isOnline;
  }

  void setShouldSucceed(bool shouldSucceed) {
    _shouldSucceed = shouldSucceed;
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    if (!_isOnline) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    if (!_shouldSucceed) {
      return Left(ServerFailure(message: 'Server error'));
    }

    final user = UserModel(
      id: 'test-id',
      email: email,
      name: name,
      phone: phone,
      isEmailVerified: false,
    );

    return Right(user);
  }

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    if (!_isOnline) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    if (!_shouldSucceed) {
      return Left(ServerFailure(message: 'Server error'));
    }

    final user = UserModel(
      id: 'test-id',
      email: email,
      name: 'Test User',
      isEmailVerified: false,
    );

    return Right(user);
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    return Right(const UserModel(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      isEmailVerified: false,
    ));
  }

  @override
  Future<bool> isAuthenticated() async {
    return false;
  }

  @override
  Future<Either<Failure, bool>> forgotPassword({required String email}) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    return const Right('fake-token');
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    return Right(const UserModel(
      id: 'google-id',
      email: 'google@example.com',
      name: 'Google User',
      isEmailVerified: true,
    ));
  }
}

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  group('register', () {
    const tEmail = 'test@example.com';
    const tPassword = 'Password123!';
    const tName = 'Test User';
    const tPhone = '1234567890';

    test('should return user when registration is successful', () async {
      // arrange
      repository.setShouldSucceed(true);
      repository.setNetworkStatus(true);

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (user) {
          expect(user.email, equals(tEmail));
          expect(user.name, equals(tName));
          expect(user.phone, equals(tPhone));
        },
      );
    });

    test('should return server failure when registration fails', () async {
      // arrange
      repository.setShouldSucceed(false);
      repository.setNetworkStatus(true);

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Server error'));
        },
        (user) => fail('Should not return user'),
      );
    });

    test('should return network failure when device is offline', () async {
      // arrange
      repository.setNetworkStatus(false);

      // act
      final result = await repository.register(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      );

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.message, equals('No internet connection'));
        },
        (user) => fail('Should not return user'),
      );
    });
  });
}
