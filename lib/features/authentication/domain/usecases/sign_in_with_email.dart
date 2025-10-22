import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing in an existing user with email and password
class SignInWithEmail {

  SignInWithEmail(this._repository);
  final AuthRepository _repository;

  /// Signs in an existing user
  ///
  /// [email] user's email address
  /// [password] user's password
  /// Returns [Right(User)] on success or [Left(Failure)] on error
  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    // Basic validation
    if (email.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Email is required',
          fieldErrors: {'email': 'Email cannot be empty'},
        ),
      );
    }

    if (password.isEmpty) {
      return const Left(
        ValidationFailure(
          message: 'Password is required',
          fieldErrors: {'password': 'Password cannot be empty'},
        ),
      );
    }

    return _repository.signInWithEmail(email: email, password: password);
  }
}
