// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_lookup_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory cache for user lookups to avoid repeated Firestore queries
///
/// This provider implements the proper pattern for chat apps:
/// - Messages store only senderId (not senderName)
/// - UI looks up display names on-demand
/// - Results are cached in memory with real-time updates
/// - Single source of truth (users collection)
///
/// Benefits:
/// - Name changes appear instantly everywhere via Firestore listeners
/// - Zero writes to messages when name changes
/// - Scalable (no need to update millions of message documents)

@ProviderFor(UserLookupCache)
const userLookupCacheProvider = UserLookupCacheProvider._();

/// In-memory cache for user lookups to avoid repeated Firestore queries
///
/// This provider implements the proper pattern for chat apps:
/// - Messages store only senderId (not senderName)
/// - UI looks up display names on-demand
/// - Results are cached in memory with real-time updates
/// - Single source of truth (users collection)
///
/// Benefits:
/// - Name changes appear instantly everywhere via Firestore listeners
/// - Zero writes to messages when name changes
/// - Scalable (no need to update millions of message documents)
final class UserLookupCacheProvider
    extends $NotifierProvider<UserLookupCache, Map<String, CachedUser>> {
  /// In-memory cache for user lookups to avoid repeated Firestore queries
  ///
  /// This provider implements the proper pattern for chat apps:
  /// - Messages store only senderId (not senderName)
  /// - UI looks up display names on-demand
  /// - Results are cached in memory with real-time updates
  /// - Single source of truth (users collection)
  ///
  /// Benefits:
  /// - Name changes appear instantly everywhere via Firestore listeners
  /// - Zero writes to messages when name changes
  /// - Scalable (no need to update millions of message documents)
  const UserLookupCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLookupCacheProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLookupCacheHash();

  @$internal
  @override
  UserLookupCache create() => UserLookupCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, CachedUser> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, CachedUser>>(value),
    );
  }
}

String _$userLookupCacheHash() => r'dd884c8c5f2b55c86047fc025a67a3720d41da39';

/// In-memory cache for user lookups to avoid repeated Firestore queries
///
/// This provider implements the proper pattern for chat apps:
/// - Messages store only senderId (not senderName)
/// - UI looks up display names on-demand
/// - Results are cached in memory with real-time updates
/// - Single source of truth (users collection)
///
/// Benefits:
/// - Name changes appear instantly everywhere via Firestore listeners
/// - Zero writes to messages when name changes
/// - Scalable (no need to update millions of message documents)

abstract class _$UserLookupCache extends $Notifier<Map<String, CachedUser>> {
  Map<String, CachedUser> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<Map<String, CachedUser>, Map<String, CachedUser>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, CachedUser>, Map<String, CachedUser>>,
              Map<String, CachedUser>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for looking up a single user by ID
///
/// This is a convenience provider that other widgets can watch
/// for reactive updates when user data changes

@ProviderFor(userById)
const userByIdProvider = UserByIdFamily._();

/// Provider for looking up a single user by ID
///
/// This is a convenience provider that other widgets can watch
/// for reactive updates when user data changes

final class UserByIdProvider
    extends $FunctionalProvider<AsyncValue<User?>, User?, FutureOr<User?>>
    with $FutureModifier<User?>, $FutureProvider<User?> {
  /// Provider for looking up a single user by ID
  ///
  /// This is a convenience provider that other widgets can watch
  /// for reactive updates when user data changes
  const UserByIdProvider._({
    required UserByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userByIdHash();

  @override
  String toString() {
    return r'userByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<User?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<User?> create(Ref ref) {
    final argument = this.argument as String;
    return userById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userByIdHash() => r'd5984cec518e30e9271cea529d45002fbdc8f0fe';

/// Provider for looking up a single user by ID
///
/// This is a convenience provider that other widgets can watch
/// for reactive updates when user data changes

final class UserByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<User?>, String> {
  const UserByIdFamily._()
    : super(
        retry: null,
        name: r'userByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for looking up a single user by ID
  ///
  /// This is a convenience provider that other widgets can watch
  /// for reactive updates when user data changes

  UserByIdProvider call(String userId) =>
      UserByIdProvider._(argument: userId, from: this);

  @override
  String toString() => r'userByIdProvider';
}

/// Provider for getting a user's display name by ID
///
/// Returns 'Unknown' if user not found
/// Most commonly used in message UI components

@ProviderFor(userDisplayName)
const userDisplayNameProvider = UserDisplayNameFamily._();

/// Provider for getting a user's display name by ID
///
/// Returns 'Unknown' if user not found
/// Most commonly used in message UI components

final class UserDisplayNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// Provider for getting a user's display name by ID
  ///
  /// Returns 'Unknown' if user not found
  /// Most commonly used in message UI components
  const UserDisplayNameProvider._({
    required UserDisplayNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userDisplayNameProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userDisplayNameHash();

  @override
  String toString() {
    return r'userDisplayNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return userDisplayName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserDisplayNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userDisplayNameHash() => r'181f9bca1962a0720398b9a5624073274523b58f';

/// Provider for getting a user's display name by ID
///
/// Returns 'Unknown' if user not found
/// Most commonly used in message UI components

final class UserDisplayNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  const UserDisplayNameFamily._()
    : super(
        retry: null,
        name: r'userDisplayNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting a user's display name by ID
  ///
  /// Returns 'Unknown' if user not found
  /// Most commonly used in message UI components

  UserDisplayNameProvider call(String userId) =>
      UserDisplayNameProvider._(argument: userId, from: this);

  @override
  String toString() => r'userDisplayNameProvider';
}
