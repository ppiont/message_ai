import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for getting the currently signed-in user
class GetCurrentUser {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  /// Gets the current user
  ///
  /// Returns [Right(User)] if signed in, [Right(null)] if not signed in,
  /// or [Left(Failure)] on error
  Either<Failure, User?> call() {
    return _repository.getCurrentUser();
  }
}
