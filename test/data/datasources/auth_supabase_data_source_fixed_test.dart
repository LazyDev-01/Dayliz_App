import 'package:flutter_test/flutter_test.dart';

import 'package:dayliz_app/core/errors/exceptions.dart';
import 'package:dayliz_app/data/datasources/auth_data_source.dart';
import 'package:dayliz_app/data/models/user_model.dart';
import 'package:dayliz_app/domain/entities/user.dart';

// Create a fake implementation of AuthDataSource for testing
class FakeAuthDataSource implements AuthRemoteDataSource {
  bool _shouldSucceed = true;
  bool _emailExists = false;

  void setShouldSucceed(bool shouldSucceed) {
    _shouldSucceed = shouldSucceed;
  }

  void setEmailExists(bool emailExists) {
    _emailExists = emailExists;
  }

  @override
  Future<UserModel> register(String email, String password, String name, {String? phone}) async {
    if (_emailExists) {
      throw ServerException(message: 'This email is already registered');
    }

    if (!_shouldSucceed) {
      throw ServerException(message: 'Registration failed');
    }

    return const UserModel(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      phone: '1234567890',
      isEmailVerified: false,
    );
  }

  @override
  Future<UserModel> login(String email, String password) async {
    if (!_shouldSucceed) {
      throw ServerException(message: 'Invalid credentials');
    }

    return const UserModel(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      isEmailVerified: false,
    );
  }

  @override
  Future<bool> logout() async {
    return true;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (!_shouldSucceed) {
      return null;
    }

    return const UserModel(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      isEmailVerified: false,
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    return _shouldSucceed;
  }

  @override
  Future<void> forgotPassword(String email) async {
    if (!_shouldSucceed) {
      throw ServerException(message: 'Failed to send reset email');
    }
  }

  @override
  Future<bool> resetPassword({required String token, required String newPassword}) async {
    if (!_shouldSucceed) {
      throw ServerException(message: 'Failed to reset password');
    }

    return true;
  }

  @override
  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    if (!_shouldSucceed) {
      throw ServerException(message: 'Failed to change password');
    }

    return true;
  }

  @override
  Future<String> refreshToken() async {
    if (!_shouldSucceed) {
      throw ServerException(message: 'Failed to refresh token');
    }

    return 'fake-token';
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!_shouldSucceed) {
      throw ServerException(message: 'Google sign-in failed');
    }

    return const UserModel(
      id: 'google-id',
      email: 'google@example.com',
      name: 'Google User',
      isEmailVerified: true,
    );
  }

  @override
  Future<void> cacheUser(User user) async {
    // Do nothing for this test
  }
}

void main() {
  late FakeAuthDataSource dataSource;

  setUp(() {
    dataSource = FakeAuthDataSource();
  });

  group('register', () {
    const tEmail = 'test@example.com';
    const tPassword = 'Password123!';
    const tName = 'Test User';
    const tPhone = '1234567890';

    test('should return user model when registration is successful', () async {
      // arrange
      dataSource.setShouldSucceed(true);
      dataSource.setEmailExists(false);

      // act
      final result = await dataSource.register(tEmail, tPassword, tName, phone: tPhone);

      // assert
      expect(result, isA<UserModel>());
      expect(result.email, equals('test@example.com'));
    });

    test('should throw ServerException when email already exists', () async {
      // arrange
      dataSource.setEmailExists(true);

      // act & assert
      expect(
        () => dataSource.register(tEmail, tPassword, tName, phone: tPhone),
        throwsA(isA<ServerException>()),
      );
    });

    test('should throw ServerException when registration fails', () async {
      // arrange
      dataSource.setShouldSucceed(false);
      dataSource.setEmailExists(false);

      // act & assert
      expect(
        () => dataSource.register(tEmail, tPassword, tName, phone: tPhone),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
