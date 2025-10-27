import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/messaging/data/services/rtdb_presence_service.dart';

/// Use case for signing out the current user
///
/// **IMPORTANT**: Clears presence BEFORE signing out to avoid permission issues
class SignOut {
  SignOut(this._repository, this._presenceService);
  final AuthRepository _repository;
  final RtdbPresenceService _presenceService;

  /// Signs out the current user
  ///
  /// Steps:
  /// 1. Get current user
  /// 2. Clear presence (while still authenticated)
  /// 3. Sign out from Firebase Auth
  ///
  /// Returns [Right(Unit)] on success or [Left(Failure)] on error
  Future<Either<Failure, Unit>> call() async {
    // Get current user before signing out
    final userResult = _repository.getCurrentUser();

    // Clear presence while still authenticated (must await!)
    await userResult.fold(
      (failure) async {
        // No user to clear presence for, just continue
      },
      (user) async {
        if (user != null) {
          await _presenceService.clearPresence(userId: user.uid);
        }
      },
    );

    // Now sign out from Firebase Auth
    return _repository.signOut();
  }
}
