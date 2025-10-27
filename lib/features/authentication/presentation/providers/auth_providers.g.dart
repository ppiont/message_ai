// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for Firebase Auth instance

@ProviderFor(firebaseAuth)
const firebaseAuthProvider = FirebaseAuthProvider._();

/// Provider for Firebase Auth instance

final class FirebaseAuthProvider
    extends
        $FunctionalProvider<
          firebase_auth.FirebaseAuth,
          firebase_auth.FirebaseAuth,
          firebase_auth.FirebaseAuth
        >
    with $Provider<firebase_auth.FirebaseAuth> {
  /// Provider for Firebase Auth instance
  const FirebaseAuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseAuthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseAuthHash();

  @$internal
  @override
  $ProviderElement<firebase_auth.FirebaseAuth> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  firebase_auth.FirebaseAuth create(Ref ref) {
    return firebaseAuth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(firebase_auth.FirebaseAuth value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<firebase_auth.FirebaseAuth>(value),
    );
  }
}

String _$firebaseAuthHash() => r'073d2de7c8941748647f37dbb00de1c08ef8758b';

/// Provider for authentication remote data source

@ProviderFor(authRemoteDataSource)
const authRemoteDataSourceProvider = AuthRemoteDataSourceProvider._();

/// Provider for authentication remote data source

final class AuthRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          AuthRemoteDataSource,
          AuthRemoteDataSource,
          AuthRemoteDataSource
        >
    with $Provider<AuthRemoteDataSource> {
  /// Provider for authentication remote data source
  const AuthRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<AuthRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AuthRemoteDataSource create(Ref ref) {
    return authRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRemoteDataSource>(value),
    );
  }
}

String _$authRemoteDataSourceHash() =>
    r'5bf6f62826baf17f9cfd2e894daed3b4d15e00d3';

/// Provider for authentication repository

@ProviderFor(authRepository)
const authRepositoryProvider = AuthRepositoryProvider._();

/// Provider for authentication repository

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  /// Provider for authentication repository
  const AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'43e05b07a705006cf920b080f78421ecc8bab1d9';

/// Provider for sign up with email use case

@ProviderFor(signUpWithEmailUseCase)
const signUpWithEmailUseCaseProvider = SignUpWithEmailUseCaseProvider._();

/// Provider for sign up with email use case

final class SignUpWithEmailUseCaseProvider
    extends
        $FunctionalProvider<SignUpWithEmail, SignUpWithEmail, SignUpWithEmail>
    with $Provider<SignUpWithEmail> {
  /// Provider for sign up with email use case
  const SignUpWithEmailUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signUpWithEmailUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signUpWithEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignUpWithEmail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignUpWithEmail create(Ref ref) {
    return signUpWithEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignUpWithEmail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignUpWithEmail>(value),
    );
  }
}

String _$signUpWithEmailUseCaseHash() =>
    r'5d782fccd7952c35baefab2d32a02a2f9a78fd58';

/// Provider for sign in with email use case

@ProviderFor(signInWithEmailUseCase)
const signInWithEmailUseCaseProvider = SignInWithEmailUseCaseProvider._();

/// Provider for sign in with email use case

final class SignInWithEmailUseCaseProvider
    extends
        $FunctionalProvider<SignInWithEmail, SignInWithEmail, SignInWithEmail>
    with $Provider<SignInWithEmail> {
  /// Provider for sign in with email use case
  const SignInWithEmailUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signInWithEmailUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signInWithEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignInWithEmail> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignInWithEmail create(Ref ref) {
    return signInWithEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignInWithEmail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignInWithEmail>(value),
    );
  }
}

String _$signInWithEmailUseCaseHash() =>
    r'64f1848ae888f1e6cfd3d0334bdb6b19051e82bf';

/// Provider for sign out use case

@ProviderFor(signOutUseCase)
const signOutUseCaseProvider = SignOutUseCaseProvider._();

/// Provider for sign out use case

final class SignOutUseCaseProvider
    extends $FunctionalProvider<SignOut, SignOut, SignOut>
    with $Provider<SignOut> {
  /// Provider for sign out use case
  const SignOutUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'signOutUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$signOutUseCaseHash();

  @$internal
  @override
  $ProviderElement<SignOut> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SignOut create(Ref ref) {
    return signOutUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SignOut value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SignOut>(value),
    );
  }
}

String _$signOutUseCaseHash() => r'ac928a2ce7ed2b117473e5c7edaecede4f8e137f';

/// Provider for get current user use case

@ProviderFor(getCurrentUserUseCase)
const getCurrentUserUseCaseProvider = GetCurrentUserUseCaseProvider._();

/// Provider for get current user use case

final class GetCurrentUserUseCaseProvider
    extends $FunctionalProvider<GetCurrentUser, GetCurrentUser, GetCurrentUser>
    with $Provider<GetCurrentUser> {
  /// Provider for get current user use case
  const GetCurrentUserUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getCurrentUserUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getCurrentUserUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCurrentUser> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetCurrentUser create(Ref ref) {
    return getCurrentUserUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCurrentUser value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCurrentUser>(value),
    );
  }
}

String _$getCurrentUserUseCaseHash() =>
    r'4df090fb839426c4252c45ef2fef4dd2d8af4591';

/// Provider for send password reset email use case

@ProviderFor(sendPasswordResetEmailUseCase)
const sendPasswordResetEmailUseCaseProvider =
    SendPasswordResetEmailUseCaseProvider._();

/// Provider for send password reset email use case

final class SendPasswordResetEmailUseCaseProvider
    extends
        $FunctionalProvider<
          SendPasswordResetEmail,
          SendPasswordResetEmail,
          SendPasswordResetEmail
        >
    with $Provider<SendPasswordResetEmail> {
  /// Provider for send password reset email use case
  const SendPasswordResetEmailUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendPasswordResetEmailUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendPasswordResetEmailUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendPasswordResetEmail> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SendPasswordResetEmail create(Ref ref) {
    return sendPasswordResetEmailUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendPasswordResetEmail value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendPasswordResetEmail>(value),
    );
  }
}

String _$sendPasswordResetEmailUseCaseHash() =>
    r'f15e1b549e1ead1f3b6d5cf451801fa4c8203fb7';

/// Provider for watch auth state use case

@ProviderFor(watchAuthStateUseCase)
const watchAuthStateUseCaseProvider = WatchAuthStateUseCaseProvider._();

/// Provider for watch auth state use case

final class WatchAuthStateUseCaseProvider
    extends $FunctionalProvider<WatchAuthState, WatchAuthState, WatchAuthState>
    with $Provider<WatchAuthState> {
  /// Provider for watch auth state use case
  const WatchAuthStateUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchAuthStateUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchAuthStateUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchAuthState> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchAuthState create(Ref ref) {
    return watchAuthStateUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchAuthState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchAuthState>(value),
    );
  }
}

String _$watchAuthStateUseCaseHash() =>
    r'7a2993a826f20989a395f8f8428fe6158b26caea';

/// Provider for update user profile use case

@ProviderFor(updateUserProfileUseCase)
const updateUserProfileUseCaseProvider = UpdateUserProfileUseCaseProvider._();

/// Provider for update user profile use case

final class UpdateUserProfileUseCaseProvider
    extends
        $FunctionalProvider<
          UpdateUserProfile,
          UpdateUserProfile,
          UpdateUserProfile
        >
    with $Provider<UpdateUserProfile> {
  /// Provider for update user profile use case
  const UpdateUserProfileUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateUserProfileUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateUserProfileUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateUserProfile> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UpdateUserProfile create(Ref ref) {
    return updateUserProfileUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateUserProfile value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateUserProfile>(value),
    );
  }
}

String _$updateUserProfileUseCaseHash() =>
    r'25d7bb671eedfe64bd1717f693cc65227f845cdf';

/// Provider for sync user to Firestore use case (creates OR updates)

@ProviderFor(syncUserToFirestoreUseCase)
const syncUserToFirestoreUseCaseProvider =
    SyncUserToFirestoreUseCaseProvider._();

/// Provider for sync user to Firestore use case (creates OR updates)

final class SyncUserToFirestoreUseCaseProvider
    extends
        $FunctionalProvider<
          SyncUserToFirestore,
          SyncUserToFirestore,
          SyncUserToFirestore
        >
    with $Provider<SyncUserToFirestore> {
  /// Provider for sync user to Firestore use case (creates OR updates)
  const SyncUserToFirestoreUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncUserToFirestoreUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncUserToFirestoreUseCaseHash();

  @$internal
  @override
  $ProviderElement<SyncUserToFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SyncUserToFirestore create(Ref ref) {
    return syncUserToFirestoreUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncUserToFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncUserToFirestore>(value),
    );
  }
}

String _$syncUserToFirestoreUseCaseHash() =>
    r'e6a796754bcf8a348b142c49a6a5f13eff9d5093';

/// Provider for ensure user exists in Firestore use case (creates only if missing)

@ProviderFor(ensureUserExistsInFirestoreUseCase)
const ensureUserExistsInFirestoreUseCaseProvider =
    EnsureUserExistsInFirestoreUseCaseProvider._();

/// Provider for ensure user exists in Firestore use case (creates only if missing)

final class EnsureUserExistsInFirestoreUseCaseProvider
    extends
        $FunctionalProvider<
          EnsureUserExistsInFirestore,
          EnsureUserExistsInFirestore,
          EnsureUserExistsInFirestore
        >
    with $Provider<EnsureUserExistsInFirestore> {
  /// Provider for ensure user exists in Firestore use case (creates only if missing)
  const EnsureUserExistsInFirestoreUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ensureUserExistsInFirestoreUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$ensureUserExistsInFirestoreUseCaseHash();

  @$internal
  @override
  $ProviderElement<EnsureUserExistsInFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EnsureUserExistsInFirestore create(Ref ref) {
    return ensureUserExistsInFirestoreUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EnsureUserExistsInFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EnsureUserExistsInFirestore>(value),
    );
  }
}

String _$ensureUserExistsInFirestoreUseCaseHash() =>
    r'7146858a9fe504b9f93dedf8224ccd36fec801ff';

/// Provider for current authenticated user
///
/// Returns [User?] - the current user if signed in, null otherwise
/// This is a stream provider that automatically updates when auth state changes

@ProviderFor(authState)
const authStateProvider = AuthStateProvider._();

/// Provider for current authenticated user
///
/// Returns [User?] - the current user if signed in, null otherwise
/// This is a stream provider that automatically updates when auth state changes

final class AuthStateProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, Stream<User?>>
    with $FutureModifier<User?>, $StreamProvider<User?> {
  /// Provider for current authenticated user
  ///
  /// Returns [User?] - the current user if signed in, null otherwise
  /// This is a stream provider that automatically updates when auth state changes
  const AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<User?> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'89b1b3ab6a1d599da3cec3b546172497b9bd5ace';

/// Provider for current user (synchronous) from Firebase Auth
///
/// ⚠️ WARNING: This only returns basic Firebase Auth data with hardcoded preferredLanguage: 'en'
/// For full user data including preferredLanguage from Firestore, use currentUserWithFirestoreProvider
///
/// Returns [User?] - the current user if signed in, null otherwise
/// This provides immediate access to the current user without waiting for a stream

@ProviderFor(currentUser)
const currentUserProvider = CurrentUserProvider._();

/// Provider for current user (synchronous) from Firebase Auth
///
/// ⚠️ WARNING: This only returns basic Firebase Auth data with hardcoded preferredLanguage: 'en'
/// For full user data including preferredLanguage from Firestore, use currentUserWithFirestoreProvider
///
/// Returns [User?] - the current user if signed in, null otherwise
/// This provides immediate access to the current user without waiting for a stream

final class CurrentUserProvider extends $FunctionalProvider<User?, User?, User?>
    with $Provider<User?> {
  /// Provider for current user (synchronous) from Firebase Auth
  ///
  /// ⚠️ WARNING: This only returns basic Firebase Auth data with hardcoded preferredLanguage: 'en'
  /// For full user data including preferredLanguage from Firestore, use currentUserWithFirestoreProvider
  ///
  /// Returns [User?] - the current user if signed in, null otherwise
  /// This provides immediate access to the current user without waiting for a stream
  const CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  User? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$currentUserHash() => r'0a9484b64a908e46ac7d5d011ab5da4c487e5cce';

/// Provider for current user WITH full Firestore data (including preferredLanguage)
///
/// This is the RECOMMENDED provider for getting current user data
/// Returns [User?] with actual preferredLanguage from Firestore, not hardcoded 'en'
///
/// Falls back to Firebase Auth user if Firestore fetch fails

@ProviderFor(currentUserWithFirestore)
const currentUserWithFirestoreProvider = CurrentUserWithFirestoreProvider._();

/// Provider for current user WITH full Firestore data (including preferredLanguage)
///
/// This is the RECOMMENDED provider for getting current user data
/// Returns [User?] with actual preferredLanguage from Firestore, not hardcoded 'en'
///
/// Falls back to Firebase Auth user if Firestore fetch fails

final class CurrentUserWithFirestoreProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, FutureOr<User?>>
    with $FutureModifier<User?>, $FutureProvider<User?> {
  /// Provider for current user WITH full Firestore data (including preferredLanguage)
  ///
  /// This is the RECOMMENDED provider for getting current user data
  /// Returns [User?] with actual preferredLanguage from Firestore, not hardcoded 'en'
  ///
  /// Falls back to Firebase Auth user if Firestore fetch fails
  const CurrentUserWithFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserWithFirestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserWithFirestoreHash();

  @$internal
  @override
  $FutureProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<User?> create(Ref ref) {
    return currentUserWithFirestore(ref);
  }
}

String _$currentUserWithFirestoreHash() =>
    r'aa8c6d41d7e0172ad2df4ba8ce15f8446c94860e';

/// Provider to check if user is authenticated

@ProviderFor(isAuthenticated)
const isAuthenticatedProvider = IsAuthenticatedProvider._();

/// Provider to check if user is authenticated

final class IsAuthenticatedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Provider to check if user is authenticated
  const IsAuthenticatedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isAuthenticatedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isAuthenticatedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isAuthenticated(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isAuthenticatedHash() => r'ec341d95b490bda54e8278477e26f7b345844931';

/// Automatically manages user presence based on auth state.
///
/// **Simple pattern**:
/// - User signs in (or already signed in on startup) → Set online
/// - User signs out → Clear presence
/// - App lifecycle observer handles foreground/background

@ProviderFor(presenceController)
const presenceControllerProvider = PresenceControllerProvider._();

/// Automatically manages user presence based on auth state.
///
/// **Simple pattern**:
/// - User signs in (or already signed in on startup) → Set online
/// - User signs out → Clear presence
/// - App lifecycle observer handles foreground/background

final class PresenceControllerProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Automatically manages user presence based on auth state.
  ///
  /// **Simple pattern**:
  /// - User signs in (or already signed in on startup) → Set online
  /// - User signs out → Clear presence
  /// - App lifecycle observer handles foreground/background
  const PresenceControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presenceControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presenceControllerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return presenceController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$presenceControllerHash() =>
    r'2df10798962da55f1ca08c3d9eba607b35750e1a';
