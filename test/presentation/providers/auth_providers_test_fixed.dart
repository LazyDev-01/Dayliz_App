import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/user.dart' as domain;
import 'package:dayliz_app/domain/usecases/register_usecase.dart';
import 'package:dayliz_app/domain/usecases/login_usecase.dart';
import 'package:dayliz_app/domain/usecases/logout_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_current_user_usecase.dart';
import 'package:dayliz_app/domain/usecases/is_authenticated_usecase.dart';
import 'package:dayliz_app/presentation/providers/auth_providers.dart';
import 'package:dayliz_app/injection_container.dart' as di;

// Create mock classes manually
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockIsAuthenticatedUseCase extends Mock implements IsAuthenticatedUseCase {}

void main() {
  late ProviderContainer container;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockIsAuthenticatedUseCase mockIsAuthenticatedUseCase;
  
  setUp(() {
    mockRegisterUseCase = MockRegisterUseCase();
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockIsAuthenticatedUseCase = MockIsAuthenticatedUseCase();
    
    // Override the service locator to return our mocks
    di.sl.registerLazySingleton<RegisterUseCase>(() => mockRegisterUseCase, dispose: (_) {});
    di.sl.registerLazySingleton<LoginUseCase>(() => mockLoginUseCase, dispose: (_) {});
    di.sl.registerLazySingleton<LogoutUseCase>(() => mockLogoutUseCase, dispose: (_) {});
    di.sl.registerLazySingleton<GetCurrentUserUseCase>(() => mockGetCurrentUserUseCase, dispose: (_) {});
    di.sl.registerLazySingleton<IsAuthenticatedUseCase>(() => mockIsAuthenticatedUseCase, dispose: (_) {});
    
    // Create a ProviderContainer with overrides
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  final tEmail = 'test@example.com';
  final tPassword = 'Password123!';
  final tName = 'Test User';
  final tPhone = '1234567890';
  
  final tUser = domain.User(
    id: 'test-id',
    email: tEmail,
    name: tName,
    phone: tPhone,
    isEmailVerified: false,
  );

  group('register', () {
    test('should update state to loading when register is called', () async {
      // arrange
      when(mockRegisterUseCase(any)).thenAnswer((_) async => Right(tUser));
      
      // act
      final authNotifier = container.read(authNotifierProvider.notifier);
      authNotifier.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      expect(container.read(authNotifierProvider).isLoading, true);
    });

    test('should update state to authenticated when register is successful', () async {
      // arrange
      when(mockRegisterUseCase(any)).thenAnswer((_) async => Right(tUser));
      
      // act
      final authNotifier = container.read(authNotifierProvider.notifier);
      await authNotifier.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, true);
      expect(state.user, tUser);
      expect(state.isLoading, false);
      expect(state.errorMessage, null);
      
      verify(mockRegisterUseCase(RegisterParams(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      )));
    });

    test('should update state with error when register fails', () async {
      // arrange
      final tFailure = ServerFailure(message: 'Registration failed');
      when(mockRegisterUseCase(any)).thenAnswer((_) async => Left(tFailure));
      when(mockGetCurrentUserUseCase()).thenAnswer((_) async => Left(tFailure));
      
      // act
      final authNotifier = container.read(authNotifierProvider.notifier);
      await authNotifier.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      final state = container.read(authNotifierProvider);
      expect(state.isAuthenticated, false);
      expect(state.user, null);
      expect(state.isLoading, false);
      expect(state.errorMessage, 'Server error occurred. Please try again later.');
      
      verify(mockRegisterUseCase(RegisterParams(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      )));
    });
  });
}
