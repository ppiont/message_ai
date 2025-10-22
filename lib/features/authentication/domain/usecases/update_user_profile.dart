import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for updating user profile information
///
/// This use case handles updating user profile data such as display name
/// and profile photo URL. It validates inputs and delegates to the repository.
class UpdateUserProfile {
  final AuthRepository _repository;

  UpdateUserProfile(this._repository);

  /// Updates the user's profile with optional display name and photo URL
  ///
  /// Returns [Either] [Failure] or updated [User]
  /// - Validates that at least one field is provided for update
  /// - Validates display name if provided (not empty, reasonable length)
  Future<Either<Failure, User>> call({
    String? displayName,
    String? photoURL,
  }) async {
    // Validate that at least one field is provided
    if (displayName == null && photoURL == null) {
      return const Left(
        ValidationFailure(
          message: 'At least one field must be provided for update',
          fieldErrors: {},
        ),
      );
    }

    // Validate display name if provided
    if (displayName != null) {
      if (displayName.trim().isEmpty) {
        return const Left(
          ValidationFailure(
            message: 'Display name cannot be empty',
            fieldErrors: {'displayName': 'Display name is required'},
          ),
        );
      }

      if (displayName.trim().length < 2) {
        return const Left(
          ValidationFailure(
            message: 'Display name must be at least 2 characters',
            fieldErrors: {
              'displayName': 'Display name must be at least 2 characters',
            },
          ),
        );
      }

      if (displayName.length > 50) {
        return const Left(
          ValidationFailure(
            message: 'Display name must be 50 characters or less',
            fieldErrors: {
              'displayName': 'Display name must be 50 characters or less',
            },
          ),
        );
      }
    }

    // Delegate to repository
    return _repository.updateUserProfile(
      displayName: displayName?.trim(),
      photoURL: photoURL,
    );
  }
}
