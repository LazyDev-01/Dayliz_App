import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/user.dart' as domain;
import 'package:dayliz_app/domain/usecases/register_usecase.dart';
import 'package:dayliz_app/domain/usecases/login_usecase.dart';
import 'package:dayliz_app/domain/usecases/logout_usecase.dart';
import 'package:dayliz_app/domain/usecases/get_current_user_usecase.dart';
import 'package:dayliz_app/domain/usecases/is_authenticated_usecase.dart';
import 'package:dayliz_app/domain/usecases/forgot_password_usecase.dart';
import 'package:dayliz_app/domain/usecases/reset_password_usecase.dart';
import 'package:dayliz_app/domain/usecases/change_password_usecase.dart';
import 'package:dayliz_app/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:dayliz_app/presentation/providers/auth_providers.dart';

@GenerateMocks([
  RegisterUseCase,
  LoginUseCase,
  LogoutUseCase,
  GetCurrentUserUseCase,
  IsAuthenticatedUseCase,
  ForgotPasswordUseCase,
  ResetPasswordUseCase,
  ChangePasswordUseCase,
  SignInWithGoogleUseCase,
])
import 'auth_providers_test.mocks.dart';

void main() {
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockIsAuthenticatedUseCase mockIsAuthenticatedUseCase;
  late MockForgotPasswordUseCase mockForgotPasswordUseCase;
  late MockResetPasswordUseCase mockResetPasswordUseCase;
  late MockChangePasswordUseCase mockChangePasswordUseCase;
  late MockSignInWithGoogleUseCase mockSignInWithGoogleUseCase;
  
  late AuthNotifier authNotifier;
  
  setUp(() {
    mockRegisterUseCase = MockRegisterUseCase();
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockIsAuthenticatedUseCase = MockIsAuthenticatedUseCase();
    mockForgotPasswordUseCase = MockForgotPasswordUseCase();
    mockResetPasswordUseCase = MockResetPasswordUseCase();
    mockChangePasswordUseCase = MockChangePasswordUseCase();
    mockSignInWithGoogleUseCase = MockSignInWithGoogleUseCase();
    
    authNotifier = AuthNotifier(
      registerUseCase: mockRegisterUseCase,
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
      isAuthenticatedUseCase: mockIsAuthenticatedUseCase,
      forgotPasswordUseCase: mockForgotPasswordUseCase,
      resetPasswordUseCase: mockResetPasswordUseCase,
      changePasswordUseCase: mockChangePasswordUseCase,
      signInWithGoogleUseCase: mockSignInWithGoogleUseCase,
    );
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
      authNotifier.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      expect(authNotifier.state.isLoading, true);
    });

    test('should update state to authenticated when register is successful', () async {
      // arrange
      when(mockRegisterUseCase(any)).thenAnswer((_) async => Right(tUser));
      
      // act
      await authNotifier.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      expect(authNotifier.state.isAuthenticated, true);
      expect(authNotifier.state.user, tUser);
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.errorMessage, null);
      
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
      await authNotifier.register(tEmail, tPassword, tName, phone: tPhone);
      
      // assert
      expect(authNotifier.state.isAuthenticated, false);
      expect(authNotifier.state.user, null);
      expect(authNotifier.state.isLoading, false);
      expect(authNotifier.state.errorMessage, 'Server error occurred. Please try again later.');
      
      verify(mockRegisterUseCase(RegisterParams(
        email: tEmail,
        password: tPassword,
        name: tName,
        phone: tPhone,
      )));
    });
  });
}
