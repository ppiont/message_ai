import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:message_ai/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:message_ai/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/authentication/domain/repositories/auth_repository.dart';
import 'package:message_ai/features/authentication/domain/usecases/ensure_user_exists_in_firestore.dart';
import 'package:message_ai/features/authentication/domain/usecases/get_current_user.dart';
import 'package:message_ai/features/authentication/domain/usecases/send_password_reset_email.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_in_with_email.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_out.dart';
import 'package:message_ai/features/authentication/domain/usecases/sign_up_with_email.dart';
import 'package:message_ai/features/authentication/domain/usecases/sync_user_to_firestore.dart';
import 'package:message_ai/features/authentication/domain/usecases/update_user_profile.dart';
import 'package:message_ai/features/authentication/domain/usecases/watch_auth_state.dart';
import 'package:message_ai/features/authentication/presentation/providers/user_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

// ========== Data Layer Providers ==========

/// Provider for Firebase Auth instance
@riverpod
firebase_auth.FirebaseAuth firebaseAuth(Ref ref) {
  return firebase_auth.FirebaseAuth.instance;
}

/// Provider for authentication remote data source
@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRemoteDataSourceImpl(firebaseAuth);
}

/// Provider for authentication repository
@riverpod
AuthRepository authRepository(Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
}

// ========== Use Case Providers ==========

/// Provider for sign up with email use case
@riverpod
SignUpWithEmail signUpWithEmailUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpWithEmail(repository);
}

/// Provider for sign in with email use case
@riverpod
SignInWithEmail signInWithEmailUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmail(repository);
}

/// Provider for sign out use case
@riverpod
SignOut signOutUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
}

/// Provider for get current user use case
@riverpod
GetCurrentUser getCurrentUserUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetCurrentUser(repository);
}

/// Provider for send password reset email use case
@riverpod
SendPasswordResetEmail sendPasswordResetEmailUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordResetEmail(repository);
}

/// Provider for watch auth state use case
@riverpod
WatchAuthState watchAuthStateUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return WatchAuthState(repository);
}

/// Provider for update user profile use case
@riverpod
UpdateUserProfile updateUserProfileUseCase(Ref ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateUserProfile(repository);
}

/// Provider for sync user to Firestore use case (creates OR updates)
@riverpod
SyncUserToFirestore syncUserToFirestoreUseCase(Ref ref) {
  final repository = ref.watch(userRepositoryProvider);
  return SyncUserToFirestore(repository);
}

/// Provider for ensure user exists in Firestore use case (creates only if missing)
@riverpod
EnsureUserExistsInFirestore ensureUserExistsInFirestoreUseCase(Ref ref) {
  final repository = ref.watch(userRepositoryProvider);
  return EnsureUserExistsInFirestore(repository);
}

// ========== State Providers ==========

/// Provider for current authenticated user
///
/// Returns [User?] - the current user if signed in, null otherwise
/// This is a stream provider that automatically updates when auth state changes
@riverpod
Stream<User?> authState(Ref ref) {
  final watchAuthStateUseCase = ref.watch(watchAuthStateUseCaseProvider);
  return watchAuthStateUseCase();
}

/// Provider for current user (synchronous)
///
/// Returns [User?] - the current user if signed in, null otherwise
/// This provides immediate access to the current user without waiting for a stream
@riverpod
User? currentUser(Ref ref) {
  final getCurrentUserUseCase = ref.watch(getCurrentUserUseCaseProvider);
  return getCurrentUserUseCase().fold(
    (failure) => null, // Return null on failure
    (user) => user,
  );
}

/// Provider to check if user is authenticated
@riverpod
bool isAuthenticated(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
}
