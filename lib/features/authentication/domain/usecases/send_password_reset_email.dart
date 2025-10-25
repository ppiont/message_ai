import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for sending a password reset email
class SendPasswordResetEmail {

  SendPasswordResetEmail(this._repository);
  final AuthRepository _repository;

  /// Sends a password reset email to the provided address
  ///
  /// [email] user's email address
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> call({required String email}) async {
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

    return _repository.sendPasswordResetEmail(email: email);
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
