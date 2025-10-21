/// Use case for ensuring a user exists in Firestore
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';

/// Ensures a user document exists in Firestore without updating if it already exists.
///
/// This is optimized for sign-in scenarios where we only want to create missing
/// documents (e.g., for existing Firebase Auth users migrating to Firestore),
/// but don't want to perform unnecessary updates.
class EnsureUserExistsInFirestore {
  final UserRepository _userRepository;

  EnsureUserExistsInFirestore(this._userRepository);

  /// Ensures user exists in Firestore.
  ///
  /// Returns:
  /// - Right(user) if a new document was created
  /// - Right(null) if the document already existed (no action taken)
  /// - Left(failure) if an error occurred
  Future<Either<Failure, User?>> call(User user) async {
    final existsResult = await _userRepository.userExists(user.uid);

    return existsResult.fold(
      (failure) => Left(failure),
      (exists) async {
        if (exists) {
          // User already exists, no action needed
          return const Right(null);
        } else {
          // Create new user document
          final createResult = await _userRepository.createUser(user);
          return createResult.fold(
            (failure) => Left(failure),
            (createdUser) => Right(createdUser),
          );
        }
      },
    );
  }
}
