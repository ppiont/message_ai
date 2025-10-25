/// Use case for syncing Firebase Auth user to Firestore
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/user_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/ensure_user_exists_in_firestore.dart'
    show EnsureUserExistsInFirestore;

/// Syncs a Firebase Auth user to Firestore users collection.
///
/// **This use case ALWAYS updates the Firestore document**, creating it if missing.
///
/// Use cases:
/// - Sign up: Create initial Firestore document ✅
/// - Profile updates: Update existing Firestore document ✅
/// - Manual profile edits: Update display name, photo, etc. ✅
///
/// **Do NOT use for sign-in flows** - use [EnsureUserExistsInFirestore] instead,
/// which only creates if missing (avoids unnecessary writes).
class SyncUserToFirestore {
  SyncUserToFirestore(this._userRepository);
  final UserRepository _userRepository;

  /// Sync user data to Firestore
  ///
  /// Creates a new user document if it doesn't exist,
  /// or updates the existing one if it does.
  Future<Either<Failure, User>> call(User user) async {
    // Check if user already exists in Firestore
    final existsResult = await _userRepository.userExists(user.uid);

    return existsResult.fold(Left.new, (exists) async {
      if (exists) {
        // Update existing user
        return _userRepository.updateUser(user);
      } else {
        // Create new user
        return _userRepository.createUser(user);
      }
    });
  }
}
