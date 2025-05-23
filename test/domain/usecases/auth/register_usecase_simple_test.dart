import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:dayliz_app/domain/entities/user.dart';
import 'package:dayliz_app/domain/repositories/auth_repository.dart';
import 'package:dayliz_app/domain/usecases/register_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late RegisterUseCase usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = RegisterUseCase(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'Password123!';
  const tName = 'Test User';
  const tPhone = '1234567890';

  final tUser = User(
    id: 'test-id',
    email: tEmail,
    name: tName,
    phone: tPhone,
    isEmailVerified: false,
  );

  test('should register user from the repository', () async {
    // arrange
    when(mockAuthRepository.register(
      email: tEmail,
      password: tPassword,
      name: tName,
      phone: tPhone,
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
}
