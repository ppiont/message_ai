import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';

/// Use case for watching authentication state changes
class WatchAuthState {

  WatchAuthState(this._repository);
  final AuthRepository _repository;

  /// Stream of authentication state changes
  ///
  /// Emits [User?] whenever the authentication state changes
  /// Returns [User] when signed in, null when signed out
  Stream<User?> call() => _repository.authStateChanges();
}
