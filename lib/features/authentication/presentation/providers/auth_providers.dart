import 'package:firebase_auth/firebase_auth.dart' as firebase_auth hide User;
import 'package:flutter/foundation.dart';
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
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

// ========== Data Layer Providers ==========

/// Provider for Firebase Auth instance
@riverpod
firebase_auth.FirebaseAuth firebaseAuth(Ref ref) =>
    firebase_auth.FirebaseAuth.instance;

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

/// Provider for current user (synchronous) from Firebase Auth
///
/// ⚠️ WARNING: This only returns basic Firebase Auth data with hardcoded preferredLanguage: 'en'
/// For full user data including preferredLanguage from Firestore, use currentUserWithFirestoreProvider
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

/// Provider for current user WITH full Firestore data (including preferredLanguage)
///
/// This is the RECOMMENDED provider for getting current user data
/// Returns [User?] with actual preferredLanguage from Firestore, not hardcoded 'en'
///
/// Falls back to Firebase Auth user if Firestore fetch fails
@riverpod
Future<User?> currentUserWithFirestore(Ref ref) async {
  // Get basic user from Firebase Auth first
  final authUser = ref.watch(currentUserProvider);
  if (authUser == null) {
    return null;
  }

  // Fetch full user data from Firestore with preferredLanguage
  try {
    final userRepository = ref.watch(userRepositoryProvider);
    final result = await userRepository.getUserById(authUser.uid);

    return result.fold((failure) {
      debugPrint(
        '⚠️ Failed to fetch Firestore user data, using Auth user: ${failure.message}',
      );
      return authUser; // Fallback to auth user
    }, (firestoreUser) => firestoreUser);
  } catch (e) {
    debugPrint('⚠️ Error fetching Firestore user data: $e');
    return authUser; // Fallback to auth user
  }
}

/// Provider to check if user is authenticated
@riverpod
bool isAuthenticated(Ref ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
}

// ========== Presence Management ==========

/// Automatically manages user presence based on auth state.
///
/// **Simple pattern**:
/// - User signs in (or already signed in on startup) → Set online
/// - User signs out → Clear presence
/// - App lifecycle observer handles foreground/background
@Riverpod(keepAlive: true)
void presenceController(Ref ref) {
  final presenceService = ref.watch(presenceServiceProvider);

  // Handle initial state (user already signed in on app startup)
  final initialAuthState = ref.read(authStateProvider);
  initialAuthState.whenData((user) async {
    if (user != null) {
      debugPrint('✅ Presence: Initial sign in detected, setting ONLINE');
      await presenceService.setOnline(
        userId: user.uid,
        userName: user.displayName,
      );
    }
  });

  // Watch for auth changes (sign in/out)
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((user) async {
      if (user != null && previous?.value == null) {
        // User just signed in - set online
        debugPrint('✅ Presence: User signed in, setting ONLINE');
        await presenceService.setOnline(
          userId: user.uid,
          userName: user.displayName,
        );
      } else if (user == null && previous?.value != null) {
        // User just signed out - clear presence
        final prevUser = previous!.value!;
        debugPrint('🔴 Presence: User signed out, clearing presence');
        await presenceService.clearPresence(userId: prevUser.uid);
      }
    });
  });
}
