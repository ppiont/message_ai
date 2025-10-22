// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the FirebaseFirestore instance for messaging operations.

@ProviderFor(messagingFirestore)
const messagingFirestoreProvider = MessagingFirestoreProvider._();

/// Provides the FirebaseFirestore instance for messaging operations.

final class MessagingFirestoreProvider
    extends
        $FunctionalProvider<
          FirebaseFirestore,
          FirebaseFirestore,
          FirebaseFirestore
        >
    with $Provider<FirebaseFirestore> {
  /// Provides the FirebaseFirestore instance for messaging operations.
  const MessagingFirestoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messagingFirestoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messagingFirestoreHash();

  @$internal
  @override
  $ProviderElement<FirebaseFirestore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFirestore create(Ref ref) {
    return messagingFirestore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFirestore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFirestore>(value),
    );
  }
}

String _$messagingFirestoreHash() =>
    r'075f59e78a7b16cab126cf43dfd452c86998e781';

/// Provides the [MessageRemoteDataSource] implementation.

@ProviderFor(messageRemoteDataSource)
const messageRemoteDataSourceProvider = MessageRemoteDataSourceProvider._();

/// Provides the [MessageRemoteDataSource] implementation.

final class MessageRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          MessageRemoteDataSource,
          MessageRemoteDataSource,
          MessageRemoteDataSource
        >
    with $Provider<MessageRemoteDataSource> {
  /// Provides the [MessageRemoteDataSource] implementation.
  const MessageRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<MessageRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageRemoteDataSource create(Ref ref) {
    return messageRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRemoteDataSource>(value),
    );
  }
}

String _$messageRemoteDataSourceHash() =>
    r'3bf4eecac4b81321a843d236e9c2fa7abc9e0655';

/// Provides the [MessageLocalDataSource] implementation.

@ProviderFor(messageLocalDataSource)
const messageLocalDataSourceProvider = MessageLocalDataSourceProvider._();

/// Provides the [MessageLocalDataSource] implementation.

final class MessageLocalDataSourceProvider
    extends
        $FunctionalProvider<
          MessageLocalDataSource,
          MessageLocalDataSource,
          MessageLocalDataSource
        >
    with $Provider<MessageLocalDataSource> {
  /// Provides the [MessageLocalDataSource] implementation.
  const MessageLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<MessageLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageLocalDataSource create(Ref ref) {
    return messageLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageLocalDataSource>(value),
    );
  }
}

String _$messageLocalDataSourceHash() =>
    r'29a9bae4c8e610a25a4fa71861ed85a6333236b9';

/// Provides the [ConversationRemoteDataSource] implementation.

@ProviderFor(conversationRemoteDataSource)
const conversationRemoteDataSourceProvider =
    ConversationRemoteDataSourceProvider._();

/// Provides the [ConversationRemoteDataSource] implementation.

final class ConversationRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          ConversationRemoteDataSource,
          ConversationRemoteDataSource,
          ConversationRemoteDataSource
        >
    with $Provider<ConversationRemoteDataSource> {
  /// Provides the [ConversationRemoteDataSource] implementation.
  const ConversationRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<ConversationRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConversationRemoteDataSource create(Ref ref) {
    return conversationRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationRemoteDataSource>(value),
    );
  }
}

String _$conversationRemoteDataSourceHash() =>
    r'56b43642c6ec61a3d0fc58f25afa73afe00fb395';

/// Provides the [ConversationLocalDataSource] implementation.

@ProviderFor(conversationLocalDataSource)
const conversationLocalDataSourceProvider =
    ConversationLocalDataSourceProvider._();

/// Provides the [ConversationLocalDataSource] implementation.

final class ConversationLocalDataSourceProvider
    extends
        $FunctionalProvider<
          ConversationLocalDataSource,
          ConversationLocalDataSource,
          ConversationLocalDataSource
        >
    with $Provider<ConversationLocalDataSource> {
  /// Provides the [ConversationLocalDataSource] implementation.
  const ConversationLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<ConversationLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConversationLocalDataSource create(Ref ref) {
    return conversationLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationLocalDataSource>(value),
    );
  }
}

String _$conversationLocalDataSourceHash() =>
    r'16adb86e3a19354308c75cf70b385c36f91e18e1';

/// Provides the [MessageRepository] implementation (offline-first).

@ProviderFor(messageRepository)
const messageRepositoryProvider = MessageRepositoryProvider._();

/// Provides the [MessageRepository] implementation (offline-first).

final class MessageRepositoryProvider
    extends
        $FunctionalProvider<
          MessageRepository,
          MessageRepository,
          MessageRepository
        >
    with $Provider<MessageRepository> {
  /// Provides the [MessageRepository] implementation (offline-first).
  const MessageRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageRepositoryHash();

  @$internal
  @override
  $ProviderElement<MessageRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageRepository create(Ref ref) {
    return messageRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageRepository>(value),
    );
  }
}

String _$messageRepositoryHash() => r'91f5830f711fdf5b0ed17302f62f4f88ba83b792';

/// Provides the [ConversationRepository] implementation (offline-first).

@ProviderFor(conversationRepository)
const conversationRepositoryProvider = ConversationRepositoryProvider._();

/// Provides the [ConversationRepository] implementation (offline-first).

final class ConversationRepositoryProvider
    extends
        $FunctionalProvider<
          ConversationRepository,
          ConversationRepository,
          ConversationRepository
        >
    with $Provider<ConversationRepository> {
  /// Provides the [ConversationRepository] implementation (offline-first).
  const ConversationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ConversationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ConversationRepository create(Ref ref) {
    return conversationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationRepository>(value),
    );
  }
}

String _$conversationRepositoryHash() =>
    r'8980f472f4ad7a535e5d9eeed7a15f96ef8e703c';

/// Provides the [SendMessage] use case.

@ProviderFor(sendMessageUseCase)
const sendMessageUseCaseProvider = SendMessageUseCaseProvider._();

/// Provides the [SendMessage] use case.

final class SendMessageUseCaseProvider
    extends $FunctionalProvider<SendMessage, SendMessage, SendMessage>
    with $Provider<SendMessage> {
  /// Provides the [SendMessage] use case.
  const SendMessageUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendMessageUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendMessageUseCaseHash();

  @$internal
  @override
  $ProviderElement<SendMessage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SendMessage create(Ref ref) {
    return sendMessageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SendMessage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SendMessage>(value),
    );
  }
}

String _$sendMessageUseCaseHash() =>
    r'2b6b870b83db4a8595417b1fc34aac82e028946f';

/// Provides the [WatchMessages] use case.

@ProviderFor(watchMessagesUseCase)
const watchMessagesUseCaseProvider = WatchMessagesUseCaseProvider._();

/// Provides the [WatchMessages] use case.

final class WatchMessagesUseCaseProvider
    extends $FunctionalProvider<WatchMessages, WatchMessages, WatchMessages>
    with $Provider<WatchMessages> {
  /// Provides the [WatchMessages] use case.
  const WatchMessagesUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchMessagesUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchMessagesUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchMessages> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WatchMessages create(Ref ref) {
    return watchMessagesUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchMessages value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchMessages>(value),
    );
  }
}

String _$watchMessagesUseCaseHash() =>
    r'4a3ab70629345d8b337ae861ecd52bdc3f27abb9';

/// Provides the [MarkMessageAsRead] use case.

@ProviderFor(markMessageAsReadUseCase)
const markMessageAsReadUseCaseProvider = MarkMessageAsReadUseCaseProvider._();

/// Provides the [MarkMessageAsRead] use case.

final class MarkMessageAsReadUseCaseProvider
    extends
        $FunctionalProvider<
          MarkMessageAsRead,
          MarkMessageAsRead,
          MarkMessageAsRead
        >
    with $Provider<MarkMessageAsRead> {
  /// Provides the [MarkMessageAsRead] use case.
  const MarkMessageAsReadUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markMessageAsReadUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markMessageAsReadUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkMessageAsRead> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarkMessageAsRead create(Ref ref) {
    return markMessageAsReadUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkMessageAsRead value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkMessageAsRead>(value),
    );
  }
}

String _$markMessageAsReadUseCaseHash() =>
    r'd240148f0e42fc9777e039ef4f83e9ed6f06d9cc';

/// Provides the [FindOrCreateDirectConversation] use case.

@ProviderFor(findOrCreateDirectConversationUseCase)
const findOrCreateDirectConversationUseCaseProvider =
    FindOrCreateDirectConversationUseCaseProvider._();

/// Provides the [FindOrCreateDirectConversation] use case.

final class FindOrCreateDirectConversationUseCaseProvider
    extends
        $FunctionalProvider<
          FindOrCreateDirectConversation,
          FindOrCreateDirectConversation,
          FindOrCreateDirectConversation
        >
    with $Provider<FindOrCreateDirectConversation> {
  /// Provides the [FindOrCreateDirectConversation] use case.
  const FindOrCreateDirectConversationUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'findOrCreateDirectConversationUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$findOrCreateDirectConversationUseCaseHash();

  @$internal
  @override
  $ProviderElement<FindOrCreateDirectConversation> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FindOrCreateDirectConversation create(Ref ref) {
    return findOrCreateDirectConversationUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FindOrCreateDirectConversation value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FindOrCreateDirectConversation>(
        value,
      ),
    );
  }
}

String _$findOrCreateDirectConversationUseCaseHash() =>
    r'a30ca6add9625f26f6b792fff080718470667749';

/// Provides the [WatchConversations] use case.

@ProviderFor(watchConversationsUseCase)
const watchConversationsUseCaseProvider = WatchConversationsUseCaseProvider._();

/// Provides the [WatchConversations] use case.

final class WatchConversationsUseCaseProvider
    extends
        $FunctionalProvider<
          WatchConversations,
          WatchConversations,
          WatchConversations
        >
    with $Provider<WatchConversations> {
  /// Provides the [WatchConversations] use case.
  const WatchConversationsUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchConversationsUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchConversationsUseCaseHash();

  @$internal
  @override
  $ProviderElement<WatchConversations> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WatchConversations create(Ref ref) {
    return watchConversationsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchConversations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchConversations>(value),
    );
  }
}

String _$watchConversationsUseCaseHash() =>
    r'9e9b08916aac20170c0d723d96105e1b3e8d432a';

/// Provides the [GetConversationById] use case.

@ProviderFor(getConversationByIdUseCase)
const getConversationByIdUseCaseProvider =
    GetConversationByIdUseCaseProvider._();

/// Provides the [GetConversationById] use case.

final class GetConversationByIdUseCaseProvider
    extends
        $FunctionalProvider<
          GetConversationById,
          GetConversationById,
          GetConversationById
        >
    with $Provider<GetConversationById> {
  /// Provides the [GetConversationById] use case.
  const GetConversationByIdUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'getConversationByIdUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$getConversationByIdUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetConversationById> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GetConversationById create(Ref ref) {
    return getConversationByIdUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetConversationById value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetConversationById>(value),
    );
  }
}

String _$getConversationByIdUseCaseHash() =>
    r'85ddece595f8263280c1342b052f762599c2334f';

/// Stream provider for watching user's conversations in real-time.
///
/// Automatically updates when conversations change in Firestore.

@ProviderFor(userConversationsStream)
const userConversationsStreamProvider = UserConversationsStreamFamily._();

/// Stream provider for watching user's conversations in real-time.
///
/// Automatically updates when conversations change in Firestore.

final class UserConversationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  /// Stream provider for watching user's conversations in real-time.
  ///
  /// Automatically updates when conversations change in Firestore.
  const UserConversationsStreamProvider._({
    required UserConversationsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userConversationsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userConversationsStreamHash();

  @override
  String toString() {
    return r'userConversationsStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return userConversationsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserConversationsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userConversationsStreamHash() =>
    r'f08df48edec293a86a3b8c7f38a68ee527f2f634';

/// Stream provider for watching user's conversations in real-time.
///
/// Automatically updates when conversations change in Firestore.

final class UserConversationsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  const UserConversationsStreamFamily._()
    : super(
        retry: null,
        name: r'userConversationsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for watching user's conversations in real-time.
  ///
  /// Automatically updates when conversations change in Firestore.

  UserConversationsStreamProvider call(String userId) =>
      UserConversationsStreamProvider._(argument: userId, from: this);

  @override
  String toString() => r'userConversationsStreamProvider';
}

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.

@ProviderFor(conversationMessagesStream)
const conversationMessagesStreamProvider = ConversationMessagesStreamFamily._();

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.

final class ConversationMessagesStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  /// Stream provider for watching messages in a conversation in real-time.
  ///
  /// Automatically updates when messages change in Firestore.
  const ConversationMessagesStreamProvider._({
    required ConversationMessagesStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationMessagesStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationMessagesStreamHash();

  @override
  String toString() {
    return r'conversationMessagesStreamProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return conversationMessagesStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationMessagesStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationMessagesStreamHash() =>
    r'8bbc529177f3080a40ffbb8b07113d2bd20a9059';

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.

final class ConversationMessagesStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  const ConversationMessagesStreamFamily._()
    : super(
        retry: null,
        name: r'conversationMessagesStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for watching messages in a conversation in real-time.
  ///
  /// Automatically updates when messages change in Firestore.

  ConversationMessagesStreamProvider call(String conversationId) =>
      ConversationMessagesStreamProvider._(
        argument: conversationId,
        from: this,
      );

  @override
  String toString() => r'conversationMessagesStreamProvider';
}

/// Provides the [TypingIndicatorService] instance.

@ProviderFor(typingIndicatorService)
const typingIndicatorServiceProvider = TypingIndicatorServiceProvider._();

/// Provides the [TypingIndicatorService] instance.

final class TypingIndicatorServiceProvider
    extends
        $FunctionalProvider<
          TypingIndicatorService,
          TypingIndicatorService,
          TypingIndicatorService
        >
    with $Provider<TypingIndicatorService> {
  /// Provides the [TypingIndicatorService] instance.
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
  $ProviderElement<TypingIndicatorService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TypingIndicatorService create(Ref ref) {
    return typingIndicatorService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TypingIndicatorService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TypingIndicatorService>(value),
    );
  }
}

String _$typingIndicatorServiceHash() =>
    r'45cdd079e3cb4d9c74a2b184b234a6d7aa384aec';

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

/// Provides the [MessageSyncService] instance.
///
/// Handles background synchronization between local and remote storage.

@ProviderFor(messageSyncService)
const messageSyncServiceProvider = MessageSyncServiceProvider._();

/// Provides the [MessageSyncService] instance.
///
/// Handles background synchronization between local and remote storage.

final class MessageSyncServiceProvider
    extends
        $FunctionalProvider<
          MessageSyncService,
          MessageSyncService,
          MessageSyncService
        >
    with $Provider<MessageSyncService> {
  /// Provides the [MessageSyncService] instance.
  ///
  /// Handles background synchronization between local and remote storage.
  const MessageSyncServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageSyncServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageSyncServiceHash();

  @$internal
  @override
  $ProviderElement<MessageSyncService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageSyncService create(Ref ref) {
    return messageSyncService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageSyncService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageSyncService>(value),
    );
  }
}

String _$messageSyncServiceHash() =>
    r'b106c9e58b489f174052c88b24060e1743e49637';

/// Provides the [MessageQueue] instance.
///
/// Handles optimistic UI updates and background message processing.

@ProviderFor(messageQueue)
const messageQueueProvider = MessageQueueProvider._();

/// Provides the [MessageQueue] instance.
///
/// Handles optimistic UI updates and background message processing.

final class MessageQueueProvider
    extends $FunctionalProvider<MessageQueue, MessageQueue, MessageQueue>
    with $Provider<MessageQueue> {
  /// Provides the [MessageQueue] instance.
  ///
  /// Handles optimistic UI updates and background message processing.
  const MessageQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageQueueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageQueueHash();

  @$internal
  @override
  $ProviderElement<MessageQueue> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageQueue create(Ref ref) {
    return messageQueue(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageQueue value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageQueue>(value),
    );
  }
}

String _$messageQueueHash() => r'9b2185063af10745cd105b6528f0ead3e2b8d842';
