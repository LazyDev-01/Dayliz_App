import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:dayliz_app/data/datasources/auth_local_data_source.dart';
import 'package:dayliz_app/domain/entities/user.dart';

void main() {
  group('AuthLocalDataSourceImpl - Secure Storage Integration', () {
    late AuthLocalDataSourceImpl dataSource;

    setUp(() {
      // Use a test-specific secure storage configuration
      const secureStorage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );
      dataSource = AuthLocalDataSourceImpl(secureStorage: secureStorage);
    });

    const testUser = User(
      id: 'test-id',
      email: 'test@example.com',
      name: 'Test User',
      phone: '+1234567890',
      profileImageUrl: 'https://example.com/avatar.jpg',
      isEmailVerified: true,
      metadata: {'role': 'user'},
    );

    const testToken = 'test-auth-token';

    test('should cache and retrieve user data successfully', () async {
      // Cache user
      final cacheResult = await dataSource.cacheUser(testUser);
      expect(cacheResult, true);

      // Retrieve user
      final retrievedUser = await dataSource.getCachedUser();
      expect(retrievedUser, isNotNull);
      expect(retrievedUser!.id, testUser.id);
      expect(retrievedUser.email, testUser.email);
      expect(retrievedUser.name, testUser.name);
    });

    test('should cache and retrieve token successfully', () async {
      // Cache token
      final cacheResult = await dataSource.cacheToken(testToken);
      expect(cacheResult, true);

      // Retrieve token
      final retrievedToken = await dataSource.getCachedTokenAsync();
      expect(retrievedToken, testToken);
    });

    test('should check authentication status correctly', () async {
      // Initially not authenticated
      final initialAuth = await dataSource.isAuthenticated();
      expect(initialAuth, false);

      // Cache token
      await dataSource.cacheToken(testToken);

      // Now should be authenticated
      final authAfterToken = await dataSource.isAuthenticated();
      expect(authAfterToken, true);
    });

    test('should clear data successfully', () async {
      // Cache data first
      await dataSource.cacheUser(testUser);
      await dataSource.cacheToken(testToken);

      // Clear token
      final clearTokenResult = await dataSource.clearToken();
      expect(clearTokenResult, true);

      // Clear user
      final clearUserResult = await dataSource.clearUser();
      expect(clearUserResult, true);

      // Verify data is cleared
      final retrievedUser = await dataSource.getCachedUser();
      expect(retrievedUser, isNull);

      final retrievedToken = await dataSource.getCachedTokenAsync();
      expect(retrievedToken, isNull);
    });

    test('should logout and clear all data', () async {
      // Cache data first
      await dataSource.cacheUser(testUser);
      await dataSource.cacheToken(testToken);

      // Logout
      final logoutResult = await dataSource.logout();
      expect(logoutResult, true);

      // Verify all data is cleared
      final retrievedUser = await dataSource.getCachedUser();
      expect(retrievedUser, isNull);

      final retrievedToken = await dataSource.getCachedTokenAsync();
      expect(retrievedToken, isNull);

      final isAuth = await dataSource.isAuthenticated();
      expect(isAuth, false);
    });
  });
}
