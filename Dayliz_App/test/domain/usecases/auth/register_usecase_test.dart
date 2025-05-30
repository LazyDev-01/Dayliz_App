import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:dayliz_app/core/errors/failures.dart';
import 'package:dayliz_app/domain/entities/user.dart' as domain;
import 'package:dayliz_app/domain/repositories/auth_repository.dart';
import 'package:dayliz_app/domain/usecases/register_usecase.dart';

@GenerateMocks([AuthRepository])
import 'register_usecase_test.mocks.dart';

void main() {
  late RegisterUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterUseCase(mockAuthRepository);
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

  test('should register user with email, password, name, and phone', () async {
    // arrange
    when(mockAuthRepository.register(
      email: anyNamed('email'),
      password: anyNamed('password'),
      name: anyNamed('name'),
      phone: anyNamed('phone'),
    )).thenAnswer((_) async => Right(tUser));

    // act
    final result = await usecase(RegisterParams(
      email: tEmail,
      password: tPassword,
      name: tName,
      phone: tPhone,
    ));

    // assert
    expect(result, Right(tUser));
    verify(mockAuthRepository.register(
      email: tEmail,
      password: tPassword,
      name: tName,
      phone: tPhone,
    ));
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should register user without phone number', () async {
    // arrange
    when(mockAuthRepository.register(
      email: anyNamed('email'),
      password: anyNamed('password'),
      name: anyNamed('name'),
      phone: null,
    )).thenAnswer((_) async => Right(tUser));

    // act
    final result = await usecase(RegisterParams(
      email: tEmail,
      password: tPassword,
      name: tName,
    ));

    // assert
    expect(result, Right(tUser));
    verify(mockAuthRepository.register(
      email: tEmail,
      password: tPassword,
      name: tName,
      phone: null,
    ));
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return failure when registration fails', () async {
    // arrange
    final tFailure = ServerFailure(message: 'Registration failed');
    when(mockAuthRepository.register(
      email: anyNamed('email'),
      password: anyNamed('password'),
      name: anyNamed('name'),
      phone: anyNamed('phone'),
    )).thenAnswer((_) async => Left(tFailure));

    // act
    final result = await usecase(RegisterParams(
      email: tEmail,
      password: tPassword,
      name: tName,
      phone: tPhone,
    ));

    // assert
    expect(result, Left(tFailure));
    verify(mockAuthRepository.register(
      email: tEmail,
      password: tPassword,
      name: tName,
      phone: tPhone,
    ));
    verifyNoMoreInteractions(mockAuthRepository);
  });
}
