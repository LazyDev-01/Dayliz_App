import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

/// Use case to register a new user
class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Execute the use case with the given parameters
  /// Returns a [Either] with a [Failure] or a [User] entity
  Future<Either<Failure, User>> call(RegisterParams params) async {
    print('RegisterUseCase: Executing with params: ${params.email}, ${params.name}');
    print('RegisterUseCase: repository instance: $repository');

    try {
      print('RegisterUseCase: Calling repository.register');
      final result = await repository.register(
        name: params.name,
        email: params.email,
        password: params.password,
        phone: params.phone,
      );
      print('RegisterUseCase: repository.register completed');
      print('RegisterUseCase: result is ${result.isRight() ? "Right" : "Left"}');
      return result;
    } catch (e) {
      print('RegisterUseCase: Error in repository.register: $e');
      rethrow;
    }
  }
}

/// Parameters for the RegisterUseCase
class RegisterParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String? phone;

  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  @override
  List<Object?> get props => [name, email, password, phone];
}