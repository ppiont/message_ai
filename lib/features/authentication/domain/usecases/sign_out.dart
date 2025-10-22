import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for signing out the current user
class SignOut {

  SignOut(this._repository);
  final AuthRepository _repository;

  /// Signs out the current user
  ///
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> call() async => _repository.signOut();
}
