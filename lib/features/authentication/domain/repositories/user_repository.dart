/// Repository interface for user profile operations
library;

import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';

/// Repository for managing user profiles in Firestore
abstract class UserRepository {
  /// Create a new user profile in Firestore
  Future<Either<Failure, User>> createUser(User user);

  /// Get a user by their ID
  Future<Either<Failure, User>> getUserById(String userId);

  /// Get a user by their email
  Future<Either<Failure, User?>> getUserByEmail(String email);

  /// Get a user by their phone number
  Future<Either<Failure, User?>> getUserByPhoneNumber(String phoneNumber);

  /// Update a user profile
  Future<Either<Failure, User>> updateUser(User user);

  /// Update user's online status
  Future<Either<Failure, void>> updateUserOnlineStatus(
    String userId,
    bool isOnline,
  );

  /// Update user's last seen timestamp
  Future<Either<Failure, void>> updateUserLastSeen(
    String userId,
    DateTime lastSeen,
  );

  /// Update user's FCM token
  Future<Either<Failure, void>> updateUserFcmToken(
    String userId,
    String fcmToken,
  );

  /// Delete a user profile (soft delete)
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Watch user changes in real-time
  Stream<Either<Failure, User>> watchUser(String userId);

  /// Check if a user exists
  Future<Either<Failure, bool>> userExists(String userId);
}
