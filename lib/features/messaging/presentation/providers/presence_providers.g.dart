// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [RtdbPresenceService] instance for presence tracking.
///
/// Uses Firebase Realtime Database with automatic offline detection via
/// onDisconnect() callbacks. No heartbeat mechanism needed.

@ProviderFor(presenceService)
const presenceServiceProvider = PresenceServiceProvider._();

/// Provides the [RtdbPresenceService] instance for presence tracking.
///
/// Uses Firebase Realtime Database with automatic offline detection via
/// onDisconnect() callbacks. No heartbeat mechanism needed.

final class PresenceServiceProvider
    extends
        $FunctionalProvider<
          RtdbPresenceService,
          RtdbPresenceService,
          RtdbPresenceService
        >
    with $Provider<RtdbPresenceService> {
  /// Provides the [RtdbPresenceService] instance for presence tracking.
  ///
  /// Uses Firebase Realtime Database with automatic offline detection via
  /// onDisconnect() callbacks. No heartbeat mechanism needed.
  const PresenceServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'presenceServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$presenceServiceHash();

  @$internal
  @override
  $ProviderElement<RtdbPresenceService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RtdbPresenceService create(Ref ref) {
    return presenceService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RtdbPresenceService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RtdbPresenceService>(value),
    );
  }
}

String _$presenceServiceHash() => r'bde75b02ef096e975b3fda4b4401b36a43492711';

/// Provides the [FCMService] instance for push notifications.

@ProviderFor(fcmService)
const fcmServiceProvider = FcmServiceProvider._();

/// Provides the [FCMService] instance for push notifications.

final class FcmServiceProvider
    extends $FunctionalProvider<FCMService, FCMService, FCMService>
    with $Provider<FCMService> {
  /// Provides the [FCMService] instance for push notifications.
  const FcmServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fcmServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fcmServiceHash();

  @$internal
  @override
  $ProviderElement<FCMService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FCMService create(Ref ref) {
    return fcmService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FCMService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FCMService>(value),
    );
  }
}

String _$fcmServiceHash() => r'f44dd3cee344080597815373251c1d1017a61507';

/// Watches presence status for a specific user.
///
/// Returns a stream of presence data including:
/// - isOnline: true if user is currently online
/// - lastSeen: timestamp of last activity
/// - userName: display name

@ProviderFor(userPresence)
const userPresenceProvider = UserPresenceFamily._();

/// Watches presence status for a specific user.
///
/// Returns a stream of presence data including:
/// - isOnline: true if user is currently online
/// - lastSeen: timestamp of last activity
/// - userName: display name

final class UserPresenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          Stream<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $StreamProvider<Map<String, dynamic>?> {
  /// Watches presence status for a specific user.
  ///
  /// Returns a stream of presence data including:
  /// - isOnline: true if user is currently online
  /// - lastSeen: timestamp of last activity
  /// - userName: display name
  const UserPresenceProvider._({
    required UserPresenceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userPresenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userPresenceHash();

  @override
  String toString() {
    return r'userPresenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as String;
    return userPresence(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserPresenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userPresenceHash() => r'b49e76812a23aaac3acf6a1a3ad87634fc5c3584';

/// Watches presence status for a specific user.
///
/// Returns a stream of presence data including:
/// - isOnline: true if user is currently online
/// - lastSeen: timestamp of last activity
/// - userName: display name

final class UserPresenceFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, dynamic>?>, String> {
  const UserPresenceFamily._()
    : super(
        retry: null,
        name: r'userPresenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watches presence status for a specific user.
  ///
  /// Returns a stream of presence data including:
  /// - isOnline: true if user is currently online
  /// - lastSeen: timestamp of last activity
  /// - userName: display name

  UserPresenceProvider call(String userId) =>
      UserPresenceProvider._(argument: userId, from: this);

  @override
  String toString() => r'userPresenceProvider';
}

/// Batch presence lookup for multiple users (optimized for conversation lists).
///
/// **Performance Optimization:**
/// Instead of creating N individual stream subscriptions (one per conversation),
/// this provider creates a single subscription that watches all user IDs at once.
///
/// **Usage:**
/// ```dart
/// // In ConversationListPage: extract all user IDs from visible conversations
/// final allUserIds = conversations
///     .expand((conv) => conv['participants'] as List)
///     .map((p) => p['uid'] as String)
///     .toSet()
///     .toList();
///
/// // Watch batch presence (1 subscription instead of N)
/// final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));
///
/// // Pass to child widgets as prop
/// ConversationListItem(
///   presenceMap: presenceMapAsync.value ?? {},
///   ...
/// )
/// ```
///
/// **Returns:**
/// Map of userId -> presence data:
/// - 'isOnline': bool
/// - 'lastSeen': DateTime?
/// - 'userName': String

@ProviderFor(batchUserPresence)
const batchUserPresenceProvider = BatchUserPresenceFamily._();

/// Batch presence lookup for multiple users (optimized for conversation lists).
///
/// **Performance Optimization:**
/// Instead of creating N individual stream subscriptions (one per conversation),
/// this provider creates a single subscription that watches all user IDs at once.
///
/// **Usage:**
/// ```dart
/// // In ConversationListPage: extract all user IDs from visible conversations
/// final allUserIds = conversations
///     .expand((conv) => conv['participants'] as List)
///     .map((p) => p['uid'] as String)
///     .toSet()
///     .toList();
///
/// // Watch batch presence (1 subscription instead of N)
/// final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));
///
/// // Pass to child widgets as prop
/// ConversationListItem(
///   presenceMap: presenceMapAsync.value ?? {},
///   ...
/// )
/// ```
///
/// **Returns:**
/// Map of userId -> presence data:
/// - 'isOnline': bool
/// - 'lastSeen': DateTime?
/// - 'userName': String

final class BatchUserPresenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, Map<String, dynamic>>>,
          Map<String, Map<String, dynamic>>,
          Stream<Map<String, Map<String, dynamic>>>
        >
    with
        $FutureModifier<Map<String, Map<String, dynamic>>>,
        $StreamProvider<Map<String, Map<String, dynamic>>> {
  /// Batch presence lookup for multiple users (optimized for conversation lists).
  ///
  /// **Performance Optimization:**
  /// Instead of creating N individual stream subscriptions (one per conversation),
  /// this provider creates a single subscription that watches all user IDs at once.
  ///
  /// **Usage:**
  /// ```dart
  /// // In ConversationListPage: extract all user IDs from visible conversations
  /// final allUserIds = conversations
  ///     .expand((conv) => conv['participants'] as List)
  ///     .map((p) => p['uid'] as String)
  ///     .toSet()
  ///     .toList();
  ///
  /// // Watch batch presence (1 subscription instead of N)
  /// final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));
  ///
  /// // Pass to child widgets as prop
  /// ConversationListItem(
  ///   presenceMap: presenceMapAsync.value ?? {},
  ///   ...
  /// )
  /// ```
  ///
  /// **Returns:**
  /// Map of userId -> presence data:
  /// - 'isOnline': bool
  /// - 'lastSeen': DateTime?
  /// - 'userName': String
  const BatchUserPresenceProvider._({
    required BatchUserPresenceFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'batchUserPresenceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$batchUserPresenceHash();

  @override
  String toString() {
    return r'batchUserPresenceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return batchUserPresence(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BatchUserPresenceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$batchUserPresenceHash() => r'c2487646c6d68dba07b6eece8129a192ca985e54';

/// Batch presence lookup for multiple users (optimized for conversation lists).
///
/// **Performance Optimization:**
/// Instead of creating N individual stream subscriptions (one per conversation),
/// this provider creates a single subscription that watches all user IDs at once.
///
/// **Usage:**
/// ```dart
/// // In ConversationListPage: extract all user IDs from visible conversations
/// final allUserIds = conversations
///     .expand((conv) => conv['participants'] as List)
///     .map((p) => p['uid'] as String)
///     .toSet()
///     .toList();
///
/// // Watch batch presence (1 subscription instead of N)
/// final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));
///
/// // Pass to child widgets as prop
/// ConversationListItem(
///   presenceMap: presenceMapAsync.value ?? {},
///   ...
/// )
/// ```
///
/// **Returns:**
/// Map of userId -> presence data:
/// - 'isOnline': bool
/// - 'lastSeen': DateTime?
/// - 'userName': String

final class BatchUserPresenceFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<Map<String, Map<String, dynamic>>>,
          List<String>
        > {
  const BatchUserPresenceFamily._()
    : super(
        retry: null,
        name: r'batchUserPresenceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Batch presence lookup for multiple users (optimized for conversation lists).
  ///
  /// **Performance Optimization:**
  /// Instead of creating N individual stream subscriptions (one per conversation),
  /// this provider creates a single subscription that watches all user IDs at once.
  ///
  /// **Usage:**
  /// ```dart
  /// // In ConversationListPage: extract all user IDs from visible conversations
  /// final allUserIds = conversations
  ///     .expand((conv) => conv['participants'] as List)
  ///     .map((p) => p['uid'] as String)
  ///     .toSet()
  ///     .toList();
  ///
  /// // Watch batch presence (1 subscription instead of N)
  /// final presenceMapAsync = ref.watch(batchUserPresenceProvider(allUserIds));
  ///
  /// // Pass to child widgets as prop
  /// ConversationListItem(
  ///   presenceMap: presenceMapAsync.value ?? {},
  ///   ...
  /// )
  /// ```
  ///
  /// **Returns:**
  /// Map of userId -> presence data:
  /// - 'isOnline': bool
  /// - 'lastSeen': DateTime?
  /// - 'userName': String

  BatchUserPresenceProvider call(List<String> userIds) =>
      BatchUserPresenceProvider._(argument: userIds, from: this);

  @override
  String toString() => r'batchUserPresenceProvider';
}

/// Provides aggregated online status for a group conversation.
///
/// Returns a map with:
/// - 'onlineCount': Number of members currently online
/// - 'totalCount': Total number of members
/// - 'onlineMembers': List of online member IDs
/// - 'displayText': Human-readable status (e.g., "3/5 online")

@ProviderFor(groupPresenceStatus)
const groupPresenceStatusProvider = GroupPresenceStatusFamily._();

/// Provides aggregated online status for a group conversation.
///
/// Returns a map with:
/// - 'onlineCount': Number of members currently online
/// - 'totalCount': Total number of members
/// - 'onlineMembers': List of online member IDs
/// - 'displayText': Human-readable status (e.g., "3/5 online")

final class GroupPresenceStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>>,
          Map<String, dynamic>,
          Stream<Map<String, dynamic>>
        >
    with
        $FutureModifier<Map<String, dynamic>>,
        $StreamProvider<Map<String, dynamic>> {
  /// Provides aggregated online status for a group conversation.
  ///
  /// Returns a map with:
  /// - 'onlineCount': Number of members currently online
  /// - 'totalCount': Total number of members
  /// - 'onlineMembers': List of online member IDs
  /// - 'displayText': Human-readable status (e.g., "3/5 online")
  const GroupPresenceStatusProvider._({
    required GroupPresenceStatusFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'groupPresenceStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupPresenceStatusHash();

  @override
  String toString() {
    return r'groupPresenceStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, dynamic>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, dynamic>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return groupPresenceStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupPresenceStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupPresenceStatusHash() =>
    r'1548d5c934a736b4300a8bd4413af5418fafc4f6';

/// Provides aggregated online status for a group conversation.
///
/// Returns a map with:
/// - 'onlineCount': Number of members currently online
/// - 'totalCount': Total number of members
/// - 'onlineMembers': List of online member IDs
/// - 'displayText': Human-readable status (e.g., "3/5 online")

final class GroupPresenceStatusFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Map<String, dynamic>>, List<String>> {
  const GroupPresenceStatusFamily._()
    : super(
        retry: null,
        name: r'groupPresenceStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides aggregated online status for a group conversation.
  ///
  /// Returns a map with:
  /// - 'onlineCount': Number of members currently online
  /// - 'totalCount': Total number of members
  /// - 'onlineMembers': List of online member IDs
  /// - 'displayText': Human-readable status (e.g., "3/5 online")

  GroupPresenceStatusProvider call(List<String> participantIds) =>
      GroupPresenceStatusProvider._(argument: participantIds, from: this);

  @override
  String toString() => r'groupPresenceStatusProvider';
}
