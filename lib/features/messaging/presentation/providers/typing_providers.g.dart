// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typing_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [RtdbTypingService] instance for typing indicators.
///
/// Uses Firebase Realtime Database with automatic cleanup via onDisconnect()
/// callbacks when user disconnects or app is closed.

@ProviderFor(typingIndicatorService)
const typingIndicatorServiceProvider = TypingIndicatorServiceProvider._();

/// Provides the [RtdbTypingService] instance for typing indicators.
///
/// Uses Firebase Realtime Database with automatic cleanup via onDisconnect()
/// callbacks when user disconnects or app is closed.

final class TypingIndicatorServiceProvider
    extends
        $FunctionalProvider<
          RtdbTypingService,
          RtdbTypingService,
          RtdbTypingService
        >
    with $Provider<RtdbTypingService> {
  /// Provides the [RtdbTypingService] instance for typing indicators.
  ///
  /// Uses Firebase Realtime Database with automatic cleanup via onDisconnect()
  /// callbacks when user disconnects or app is closed.
  const TypingIndicatorServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'typingIndicatorServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$typingIndicatorServiceHash();

  @$internal
  @override
  $ProviderElement<RtdbTypingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RtdbTypingService create(Ref ref) {
    return typingIndicatorService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RtdbTypingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RtdbTypingService>(value),
    );
  }
}

String _$typingIndicatorServiceHash() =>
    r'dd411505bc3f881c8b040e02e0c558f92396bc62';

/// Watches typing users for a specific conversation.

@ProviderFor(conversationTypingUsers)
const conversationTypingUsersProvider = ConversationTypingUsersFamily._();

/// Watches typing users for a specific conversation.

final class ConversationTypingUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TypingUser>>,
          List<TypingUser>,
          Stream<List<TypingUser>>
        >
    with $FutureModifier<List<TypingUser>>, $StreamProvider<List<TypingUser>> {
  /// Watches typing users for a specific conversation.
  const ConversationTypingUsersProvider._({
    required ConversationTypingUsersFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationTypingUsersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationTypingUsersHash();

  @override
  String toString() {
    return r'conversationTypingUsersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<TypingUser>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TypingUser>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationTypingUsers(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationTypingUsersProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationTypingUsersHash() =>
    r'e44bf7227cb75dbf07b826d8c34689c7589d1dd5';

/// Watches typing users for a specific conversation.

final class ConversationTypingUsersFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TypingUser>>, (String, String)> {
  const ConversationTypingUsersFamily._()
    : super(
        retry: null,
        name: r'conversationTypingUsersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Watches typing users for a specific conversation.

  ConversationTypingUsersProvider call(
    String conversationId,
    String currentUserId,
  ) => ConversationTypingUsersProvider._(
    argument: (conversationId, currentUserId),
    from: this,
  );

  @override
  String toString() => r'conversationTypingUsersProvider';
}
