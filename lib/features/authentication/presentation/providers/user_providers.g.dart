// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for FirebaseFirestore instance

@ProviderFor(firebaseFirestore)
const firebaseFirestoreProvider = FirebaseFirestoreProvider._();

/// Provider for FirebaseFirestore instance

final class FirebaseFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  /// Provider for FirebaseFirestore instance
  const FirebaseFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'firebaseFirestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$firebaseFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return firebaseFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$firebaseFirestoreHash() => r'eca974fdc891fcd3f9586742678f47582b20adec';

/// Provider for UserRemoteDataSource

@ProviderFor(userRemoteDataSource)
const userRemoteDataSourceProvider = UserRemoteDataSourceProvider._();

/// Provider for UserRemoteDataSource

final class UserRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          UserRemoteDataSource,
          UserRemoteDataSource,
          UserRemoteDataSource
        >
    with $Provider<UserRemoteDataSource> {
  /// Provider for UserRemoteDataSource
  const UserRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<UserRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserRemoteDataSource create(Ref ref) {
    return userRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRemoteDataSource>(value),
    );
  }
}

String _$userRemoteDataSourceHash() =>
    r'a8b6b2ac3ced165d2c717519327aff64f5728a1a';

/// Provider for UserRepository

@ProviderFor(userRepository)
const userRepositoryProvider = UserRepositoryProvider._();

/// Provider for UserRepository

final class UserRepositoryProvider
    extends $FunctionalProvider<UserRepository, UserRepository, UserRepository>
    with $Provider<UserRepository> {
  /// Provider for UserRepository
  const UserRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userRepositoryHash();

  @$internal
  @override
  $ProviderElement<UserRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserRepository create(Ref ref) {
    return userRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserRepository>(value),
    );
  }
}

String _$userRepositoryHash() => r'1eb8cb73007185b68f0a29688a0d7b50de81219d';

/// Provider for UserCacheService

@ProviderFor(userCacheService)
const userCacheServiceProvider = UserCacheServiceProvider._();

/// Provider for UserCacheService

final class UserCacheServiceProvider
    extends
        $FunctionalProvider<
          UserCacheService,
          UserCacheService,
          UserCacheService
        >
    with $Provider<UserCacheService> {
  /// Provider for UserCacheService
  const UserCacheServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userCacheServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userCacheServiceHash();

  @$internal
  @override
  $ProviderElement<UserCacheService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserCacheService create(Ref ref) {
    return userCacheService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserCacheService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserCacheService>(value),
    );
  }
}

String _$userCacheServiceHash() => r'5bce65efd92207c72af9f4165436ac66d1f31828';
