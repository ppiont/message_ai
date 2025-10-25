import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing up a new user with email and password
class SignUpWithEmail {

  SignUpWithEmail(this._repository);
  final AuthRepository _repository;

  /// Signs up a new user
  ///
  /// [email] must be a valid email address
  /// [password] must be at least 6 characters
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

    if (!_isValidEmail(email)) {
      return const Left(
        ValidationFailure(
          message: 'Invalid email format',
          fieldErrors: {'email': 'Please enter a valid email address'},
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

    if (password.length < 6) {
      return const Left(
        ValidationFailure(
          message: 'Password is too short',
          fieldErrors: {'password': 'Password must be at least 6 characters'},
        ),
      );
    }

    return _repository.signUpWithEmail(email: email, password: password);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
