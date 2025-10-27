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
    r'4ff31a34ec4cb93c8424dba92ae379f9738a20a2';

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
    r'378a4681c47ad445b50e9bb2fbc58dd36fcc76c5';

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
    r'06d5ff0827d5087461a4c7119653be7caa07571b';

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

String _$messageRepositoryHash() => r'291bcb3f4687aa1af4400e2ec9c4e0ffb4778295';

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
    r'd2156b8fbd2bc2788083f7a39cbaeb4404020224';

/// Provides Firebase Functions instance for message context analysis

@ProviderFor(messageContextFunctions)
const messageContextFunctionsProvider = MessageContextFunctionsProvider._();

/// Provides Firebase Functions instance for message context analysis

final class MessageContextFunctionsProvider
    extends
        $FunctionalProvider<
          FirebaseFunctions,
          FirebaseFunctions,
          FirebaseFunctions
        >
    with $Provider<FirebaseFunctions> {
  /// Provides Firebase Functions instance for message context analysis
  const MessageContextFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageContextFunctionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageContextFunctionsHash();

  @$internal
  @override
  $ProviderElement<FirebaseFunctions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FirebaseFunctions create(Ref ref) {
    return messageContextFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FirebaseFunctions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FirebaseFunctions>(value),
    );
  }
}

String _$messageContextFunctionsHash() =>
    r'ab7ffaf1990d0a9902e31897a7bbbcf0605ed4bd';

/// Provides the [MessageContextService] for analyzing message cultural context, formality, and idioms

@ProviderFor(messageContextService)
const messageContextServiceProvider = MessageContextServiceProvider._();

/// Provides the [MessageContextService] for analyzing message cultural context, formality, and idioms

final class MessageContextServiceProvider
    extends
        $FunctionalProvider<
          MessageContextService,
          MessageContextService,
          MessageContextService
        >
    with $Provider<MessageContextService> {
  /// Provides the [MessageContextService] for analyzing message cultural context, formality, and idioms
  const MessageContextServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageContextServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageContextServiceHash();

  @$internal
  @override
  $ProviderElement<MessageContextService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MessageContextService create(Ref ref) {
    return messageContextService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageContextService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageContextService>(value),
    );
  }
}

String _$messageContextServiceHash() =>
    r'114aed6960eab3ef822125bef7440c05cb675eeb';

/// Provides the [SendMessage] use case with language detection.
///
/// Note: messageQueue removed - WorkManager handles background sync now
/// Note: embeddingGenerator removed - Firestore triggers handle embeddings server-side

@ProviderFor(sendMessageUseCase)
const sendMessageUseCaseProvider = SendMessageUseCaseProvider._();

/// Provides the [SendMessage] use case with language detection.
///
/// Note: messageQueue removed - WorkManager handles background sync now
/// Note: embeddingGenerator removed - Firestore triggers handle embeddings server-side

final class SendMessageUseCaseProvider
    extends $FunctionalProvider<SendMessage, SendMessage, SendMessage>
    with $Provider<SendMessage> {
  /// Provides the [SendMessage] use case with language detection.
  ///
  /// Note: messageQueue removed - WorkManager handles background sync now
  /// Note: embeddingGenerator removed - Firestore triggers handle embeddings server-side
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
    r'd2eff0e069317ba222183fd88cc05f4b3d816f82';

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
    r'08f7a2c8b077e97a1cd91d95f256880fc0499977';

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
    r'40a03533ebecc618d57ae6bdff8606ca24659090';

/// Provides the [MarkMessageAsDelivered] use case.

@ProviderFor(markMessageAsDeliveredUseCase)
const markMessageAsDeliveredUseCaseProvider =
    MarkMessageAsDeliveredUseCaseProvider._();

/// Provides the [MarkMessageAsDelivered] use case.

final class MarkMessageAsDeliveredUseCaseProvider
    extends
        $FunctionalProvider<
          MarkMessageAsDelivered,
          MarkMessageAsDelivered,
          MarkMessageAsDelivered
        >
    with $Provider<MarkMessageAsDelivered> {
  /// Provides the [MarkMessageAsDelivered] use case.
  const MarkMessageAsDeliveredUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'markMessageAsDeliveredUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$markMessageAsDeliveredUseCaseHash();

  @$internal
  @override
  $ProviderElement<MarkMessageAsDelivered> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MarkMessageAsDelivered create(Ref ref) {
    return markMessageAsDeliveredUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MarkMessageAsDelivered value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MarkMessageAsDelivered>(value),
    );
  }
}

String _$markMessageAsDeliveredUseCaseHash() =>
    r'd26b20788d054c599348614af10ef12cb06ea2b4';

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
    r'8f744e9e5ec488d0f79a5df6794bd0186911ca72';

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
    r'08ca32dd807ecf413e4c65a86def58979009ca71';

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
    r'8a0f31798d243e977b2b928bee5cf0ad2a79dbce';

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
    r'e6d24bd008f733f914d8a14362edb96172c9953a';

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

/// Cached provider for conversation participant IDs.
///
/// Fetches once and caches to avoid repeated fetches during stream rebuilds.

@ProviderFor(conversationParticipantIds)
const conversationParticipantIdsProvider = ConversationParticipantIdsFamily._();

/// Cached provider for conversation participant IDs.
///
/// Fetches once and caches to avoid repeated fetches during stream rebuilds.

final class ConversationParticipantIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Cached provider for conversation participant IDs.
  ///
  /// Fetches once and caches to avoid repeated fetches during stream rebuilds.
  const ConversationParticipantIdsProvider._({
    required ConversationParticipantIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationParticipantIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationParticipantIdsHash();

  @override
  String toString() {
    return r'conversationParticipantIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    final argument = this.argument as String;
    return conversationParticipantIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationParticipantIdsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationParticipantIdsHash() =>
    r'fa804986da868a3a86888732f03eab0dad4e12e1';

/// Cached provider for conversation participant IDs.
///
/// Fetches once and caches to avoid repeated fetches during stream rebuilds.

final class ConversationParticipantIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<String>>, String> {
  const ConversationParticipantIdsFamily._()
    : super(
        retry: null,
        name: r'conversationParticipantIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Cached provider for conversation participant IDs.
  ///
  /// Fetches once and caches to avoid repeated fetches during stream rebuilds.

  ConversationParticipantIdsProvider call(String conversationId) =>
      ConversationParticipantIdsProvider._(
        argument: conversationId,
        from: this,
      );

  @override
  String toString() => r'conversationParticipantIdsProvider';
}

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.
/// Returns messages with computed status from Firestore.
///
/// Uses real-time listeners for BOTH messages AND status subcollections.
/// When receiver marks delivered/read, sender sees it instantly via WebSocket.

@ProviderFor(conversationMessagesStream)
const conversationMessagesStreamProvider = ConversationMessagesStreamFamily._();

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.
/// Returns messages with computed status from Firestore.
///
/// Uses real-time listeners for BOTH messages AND status subcollections.
/// When receiver marks delivered/read, sender sees it instantly via WebSocket.

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
  /// Returns messages with computed status from Firestore.
  ///
  /// Uses real-time listeners for BOTH messages AND status subcollections.
  /// When receiver marks delivered/read, sender sees it instantly via WebSocket.
  const ConversationMessagesStreamProvider._({
    required ConversationMessagesStreamFamily super.from,
    required (String, String) super.argument,
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
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return conversationMessagesStream(ref, argument.$1, argument.$2);
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
    r'a27693bfa6937bb0b9c64b3f938f830bcf287460';

/// Stream provider for watching messages in a conversation in real-time.
///
/// Automatically updates when messages change in Firestore.
/// Returns messages with computed status from Firestore.
///
/// Uses real-time listeners for BOTH messages AND status subcollections.
/// When receiver marks delivered/read, sender sees it instantly via WebSocket.

final class ConversationMessagesStreamFamily extends $Family
    with
        $FunctionalFamilyOverride<
          Stream<List<Map<String, dynamic>>>,
          (String, String)
        > {
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
  /// Returns messages with computed status from Firestore.
  ///
  /// Uses real-time listeners for BOTH messages AND status subcollections.
  /// When receiver marks delivered/read, sender sees it instantly via WebSocket.

  ConversationMessagesStreamProvider call(
    String conversationId,
    String currentUserId,
  ) => ConversationMessagesStreamProvider._(
    argument: (conversationId, currentUserId),
    from: this,
  );

  @override
  String toString() => r'conversationMessagesStreamProvider';
}

/// Auto-marks incoming messages as read when the conversation is open.
///
/// This provider should be watched in the chat page to automatically
/// mark messages as read. It runs as a side effect separate from the
/// message stream to avoid feedback loops.

@ProviderFor(ConversationReadMarker)
const conversationReadMarkerProvider = ConversationReadMarkerFamily._();

/// Auto-marks incoming messages as read when the conversation is open.
///
/// This provider should be watched in the chat page to automatically
/// mark messages as read. It runs as a side effect separate from the
/// message stream to avoid feedback loops.
final class ConversationReadMarkerProvider
    extends $NotifierProvider<ConversationReadMarker, void> {
  /// Auto-marks incoming messages as read when the conversation is open.
  ///
  /// This provider should be watched in the chat page to automatically
  /// mark messages as read. It runs as a side effect separate from the
  /// message stream to avoid feedback loops.
  const ConversationReadMarkerProvider._({
    required ConversationReadMarkerFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'conversationReadMarkerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationReadMarkerHash();

  @override
  String toString() {
    return r'conversationReadMarkerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ConversationReadMarker create() => ConversationReadMarker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationReadMarkerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationReadMarkerHash() =>
    r'03aa950d13ddc340e73cda2beeaccb5f05b94a3d';

/// Auto-marks incoming messages as read when the conversation is open.
///
/// This provider should be watched in the chat page to automatically
/// mark messages as read. It runs as a side effect separate from the
/// message stream to avoid feedback loops.

final class ConversationReadMarkerFamily extends $Family
    with
        $ClassFamilyOverride<
          ConversationReadMarker,
          void,
          void,
          void,
          (String, String)
        > {
  const ConversationReadMarkerFamily._()
    : super(
        retry: null,
        name: r'conversationReadMarkerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Auto-marks incoming messages as read when the conversation is open.
  ///
  /// This provider should be watched in the chat page to automatically
  /// mark messages as read. It runs as a side effect separate from the
  /// message stream to avoid feedback loops.

  ConversationReadMarkerProvider call(
    String conversationId,
    String currentUserId,
  ) => ConversationReadMarkerProvider._(
    argument: (conversationId, currentUserId),
    from: this,
  );

  @override
  String toString() => r'conversationReadMarkerProvider';
}

/// Auto-marks incoming messages as read when the conversation is open.
///
/// This provider should be watched in the chat page to automatically
/// mark messages as read. It runs as a side effect separate from the
/// message stream to avoid feedback loops.

abstract class _$ConversationReadMarker extends $Notifier<void> {
  late final _$args = ref.$arg as (String, String);
  String get conversationId => _$args.$1;
  String get currentUserId => _$args.$2;

  void build(String conversationId, String currentUserId);
  @$mustCallSuper
  @override
  void runBuild() {
    build(_$args.$1, _$args.$2);
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}

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
///
/// The service handles permission errors gracefully (returns empty list),
/// so no auth guard is needed here.

@ProviderFor(conversationTypingUsers)
const conversationTypingUsersProvider = ConversationTypingUsersFamily._();

/// Watches typing users for a specific conversation.
///
/// The service handles permission errors gracefully (returns empty list),
/// so no auth guard is needed here.

final class ConversationTypingUsersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TypingUser>>,
          List<TypingUser>,
          Stream<List<TypingUser>>
        >
    with $FutureModifier<List<TypingUser>>, $StreamProvider<List<TypingUser>> {
  /// Watches typing users for a specific conversation.
  ///
  /// The service handles permission errors gracefully (returns empty list),
  /// so no auth guard is needed here.
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
///
/// The service handles permission errors gracefully (returns empty list),
/// so no auth guard is needed here.

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
  ///
  /// The service handles permission errors gracefully (returns empty list),
  /// so no auth guard is needed here.

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

/// Provides the [AutoDeliveryMarker] service.
///
/// Automatically marks incoming messages as delivered for all conversations.

@ProviderFor(autoDeliveryMarker)
const autoDeliveryMarkerProvider = AutoDeliveryMarkerProvider._();

/// Provides the [AutoDeliveryMarker] service.
///
/// Automatically marks incoming messages as delivered for all conversations.

final class AutoDeliveryMarkerProvider
    extends
        $FunctionalProvider<
          AutoDeliveryMarker?,
          AutoDeliveryMarker?,
          AutoDeliveryMarker?
        >
    with $Provider<AutoDeliveryMarker?> {
  /// Provides the [AutoDeliveryMarker] service.
  ///
  /// Automatically marks incoming messages as delivered for all conversations.
  const AutoDeliveryMarkerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'autoDeliveryMarkerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$autoDeliveryMarkerHash();

  @$internal
  @override
  $ProviderElement<AutoDeliveryMarker?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AutoDeliveryMarker? create(Ref ref) {
    return autoDeliveryMarker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AutoDeliveryMarker? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AutoDeliveryMarker?>(value),
    );
  }
}

String _$autoDeliveryMarkerHash() =>
    r'df83ba6c61fcf8a41585782cd90d68ee8cea85cb';

/// Marks all messages in a conversation as delivered for the current user.
///
/// Simple approach: Writes directly to Firestore subcollections.
/// Sender listens to these subcollections for instant status updates.
///
/// Flow:
/// 1. Get all messages not sent by current user
/// 2. Write "delivered" to Firestore: conversations/{convId}/messages/{msgId}/status/{userId}
/// 3. Sender's listener picks it up instantly

@ProviderFor(markMessagesDelivered)
const markMessagesDeliveredProvider = MarkMessagesDeliveredFamily._();

/// Marks all messages in a conversation as delivered for the current user.
///
/// Simple approach: Writes directly to Firestore subcollections.
/// Sender listens to these subcollections for instant status updates.
///
/// Flow:
/// 1. Get all messages not sent by current user
/// 2. Write "delivered" to Firestore: conversations/{convId}/messages/{msgId}/status/{userId}
/// 3. Sender's listener picks it up instantly

final class MarkMessagesDeliveredProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// Marks all messages in a conversation as delivered for the current user.
  ///
  /// Simple approach: Writes directly to Firestore subcollections.
  /// Sender listens to these subcollections for instant status updates.
  ///
  /// Flow:
  /// 1. Get all messages not sent by current user
  /// 2. Write "delivered" to Firestore: conversations/{convId}/messages/{msgId}/status/{userId}
  /// 3. Sender's listener picks it up instantly
  const MarkMessagesDeliveredProvider._({
    required MarkMessagesDeliveredFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'markMessagesDeliveredProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$markMessagesDeliveredHash();

  @override
  String toString() {
    return r'markMessagesDeliveredProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    final argument = this.argument as (String, String);
    return markMessagesDelivered(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MarkMessagesDeliveredProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$markMessagesDeliveredHash() =>
    r'9fb8e3e633273e8003767120eef8fe36ebd18f2f';

/// Marks all messages in a conversation as delivered for the current user.
///
/// Simple approach: Writes directly to Firestore subcollections.
/// Sender listens to these subcollections for instant status updates.
///
/// Flow:
/// 1. Get all messages not sent by current user
/// 2. Write "delivered" to Firestore: conversations/{convId}/messages/{msgId}/status/{userId}
/// 3. Sender's listener picks it up instantly

final class MarkMessagesDeliveredFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<void>, (String, String)> {
  const MarkMessagesDeliveredFamily._()
    : super(
        retry: null,
        name: r'markMessagesDeliveredProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Marks all messages in a conversation as delivered for the current user.
  ///
  /// Simple approach: Writes directly to Firestore subcollections.
  /// Sender listens to these subcollections for instant status updates.
  ///
  /// Flow:
  /// 1. Get all messages not sent by current user
  /// 2. Write "delivered" to Firestore: conversations/{convId}/messages/{msgId}/status/{userId}
  /// 3. Sender's listener picks it up instantly

  MarkMessagesDeliveredProvider call(String conversationId, String userId) =>
      MarkMessagesDeliveredProvider._(
        argument: (conversationId, userId),
        from: this,
      );

  @override
  String toString() => r'markMessagesDeliveredProvider';
}

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
/// Returns a stream with presence data:
/// - isOnline: boolean indicating if user is currently online
/// - lastSeen: DateTime of last activity (if offline)

@ProviderFor(userPresence)
const userPresenceProvider = UserPresenceFamily._();

/// Watches presence status for a specific user.
///
/// Returns a stream with presence data:
/// - isOnline: boolean indicating if user is currently online
/// - lastSeen: DateTime of last activity (if offline)

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
  /// Returns a stream with presence data:
  /// - isOnline: boolean indicating if user is currently online
  /// - lastSeen: DateTime of last activity (if offline)
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

String _$userPresenceHash() => r'7ab8273aef47b89740398805c661a92caa579baf';

/// Watches presence status for a specific user.
///
/// Returns a stream with presence data:
/// - isOnline: boolean indicating if user is currently online
/// - lastSeen: DateTime of last activity (if offline)

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
  /// Returns a stream with presence data:
  /// - isOnline: boolean indicating if user is currently online
  /// - lastSeen: DateTime of last activity (if offline)

  UserPresenceProvider call(String userId) =>
      UserPresenceProvider._(argument: userId, from: this);

  @override
  String toString() => r'userPresenceProvider';
}

/// Provides the [CreateGroup] use case.

@ProviderFor(createGroupUseCase)
const createGroupUseCaseProvider = CreateGroupUseCaseProvider._();

/// Provides the [CreateGroup] use case.

final class CreateGroupUseCaseProvider
    extends $FunctionalProvider<CreateGroup, CreateGroup, CreateGroup>
    with $Provider<CreateGroup> {
  /// Provides the [CreateGroup] use case.
  const CreateGroupUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'createGroupUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$createGroupUseCaseHash();

  @$internal
  @override
  $ProviderElement<CreateGroup> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CreateGroup create(Ref ref) {
    return createGroupUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CreateGroup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CreateGroup>(value),
    );
  }
}

String _$createGroupUseCaseHash() =>
    r'fbb3f65b0ab80ab751c4de1cff8128b238c0a07c';

/// Provides the [AddGroupMember] use case.

@ProviderFor(addGroupMemberUseCase)
const addGroupMemberUseCaseProvider = AddGroupMemberUseCaseProvider._();

/// Provides the [AddGroupMember] use case.

final class AddGroupMemberUseCaseProvider
    extends $FunctionalProvider<AddGroupMember, AddGroupMember, AddGroupMember>
    with $Provider<AddGroupMember> {
  /// Provides the [AddGroupMember] use case.
  const AddGroupMemberUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'addGroupMemberUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$addGroupMemberUseCaseHash();

  @$internal
  @override
  $ProviderElement<AddGroupMember> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AddGroupMember create(Ref ref) {
    return addGroupMemberUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AddGroupMember value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AddGroupMember>(value),
    );
  }
}

String _$addGroupMemberUseCaseHash() =>
    r'95c3df0c66d5add7f2df913b94f2e562927138b3';

/// Provides the [RemoveGroupMember] use case.

@ProviderFor(removeGroupMemberUseCase)
const removeGroupMemberUseCaseProvider = RemoveGroupMemberUseCaseProvider._();

/// Provides the [RemoveGroupMember] use case.

final class RemoveGroupMemberUseCaseProvider
    extends
        $FunctionalProvider<
          RemoveGroupMember,
          RemoveGroupMember,
          RemoveGroupMember
        >
    with $Provider<RemoveGroupMember> {
  /// Provides the [RemoveGroupMember] use case.
  const RemoveGroupMemberUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'removeGroupMemberUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$removeGroupMemberUseCaseHash();

  @$internal
  @override
  $ProviderElement<RemoveGroupMember> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoveGroupMember create(Ref ref) {
    return removeGroupMemberUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoveGroupMember value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoveGroupMember>(value),
    );
  }
}

String _$removeGroupMemberUseCaseHash() =>
    r'4bed0d1ec1e4a2959a24f72bfb38339def17b165';

/// Provides the [LeaveGroup] use case.

@ProviderFor(leaveGroupUseCase)
const leaveGroupUseCaseProvider = LeaveGroupUseCaseProvider._();

/// Provides the [LeaveGroup] use case.

final class LeaveGroupUseCaseProvider
    extends $FunctionalProvider<LeaveGroup, LeaveGroup, LeaveGroup>
    with $Provider<LeaveGroup> {
  /// Provides the [LeaveGroup] use case.
  const LeaveGroupUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaveGroupUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaveGroupUseCaseHash();

  @$internal
  @override
  $ProviderElement<LeaveGroup> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LeaveGroup create(Ref ref) {
    return leaveGroupUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaveGroup value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaveGroup>(value),
    );
  }
}

String _$leaveGroupUseCaseHash() => r'6121427889aa3b401c2dd0af7e5b76de5801763b';

/// Provides the [UpdateGroupInfo] use case.

@ProviderFor(updateGroupInfoUseCase)
const updateGroupInfoUseCaseProvider = UpdateGroupInfoUseCaseProvider._();

/// Provides the [UpdateGroupInfo] use case.

final class UpdateGroupInfoUseCaseProvider
    extends
        $FunctionalProvider<UpdateGroupInfo, UpdateGroupInfo, UpdateGroupInfo>
    with $Provider<UpdateGroupInfo> {
  /// Provides the [UpdateGroupInfo] use case.
  const UpdateGroupInfoUseCaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateGroupInfoUseCaseProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateGroupInfoUseCaseHash();

  @$internal
  @override
  $ProviderElement<UpdateGroupInfo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UpdateGroupInfo create(Ref ref) {
    return updateGroupInfoUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateGroupInfo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateGroupInfo>(value),
    );
  }
}

String _$updateGroupInfoUseCaseHash() =>
    r'6fc6f842c6c666144852593d2edde40673e2031e';

/// Stream provider for watching all conversations (both direct and groups) in real-time.
///
/// Returns all conversations from the unified ConversationRepository,
/// sorted by last update time.

@ProviderFor(allConversationsStream)
const allConversationsStreamProvider = AllConversationsStreamFamily._();

/// Stream provider for watching all conversations (both direct and groups) in real-time.
///
/// Returns all conversations from the unified ConversationRepository,
/// sorted by last update time.

final class AllConversationsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  /// Stream provider for watching all conversations (both direct and groups) in real-time.
  ///
  /// Returns all conversations from the unified ConversationRepository,
  /// sorted by last update time.
  const AllConversationsStreamProvider._({
    required AllConversationsStreamFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'allConversationsStreamProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$allConversationsStreamHash();

  @override
  String toString() {
    return r'allConversationsStreamProvider'
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
    return allConversationsStream(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AllConversationsStreamProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$allConversationsStreamHash() =>
    r'f25735dc7297e4e22c850a8c3cacaaae727d1ead';

/// Stream provider for watching all conversations (both direct and groups) in real-time.
///
/// Returns all conversations from the unified ConversationRepository,
/// sorted by last update time.

final class AllConversationsStreamFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Map<String, dynamic>>>, String> {
  const AllConversationsStreamFamily._()
    : super(
        retry: null,
        name: r'allConversationsStreamProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream provider for watching all conversations (both direct and groups) in real-time.
  ///
  /// Returns all conversations from the unified ConversationRepository,
  /// sorted by last update time.

  AllConversationsStreamProvider call(String userId) =>
      AllConversationsStreamProvider._(argument: userId, from: this);

  @override
  String toString() => r'allConversationsStreamProvider';
}

/// Provider for streaming all users from Firestore.
///
/// In a production app, this would be a proper user search/directory feature.

@ProviderFor(conversationUsersStream)
const conversationUsersStreamProvider = ConversationUsersStreamProvider._();

/// Provider for streaming all users from Firestore.
///
/// In a production app, this would be a proper user search/directory feature.

final class ConversationUsersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          Stream<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $StreamProvider<List<Map<String, dynamic>>> {
  /// Provider for streaming all users from Firestore.
  ///
  /// In a production app, this would be a proper user search/directory feature.
  const ConversationUsersStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationUsersStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationUsersStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Map<String, dynamic>>> create(Ref ref) {
    return conversationUsersStream(ref);
  }
}

String _$conversationUsersStreamHash() =>
    r'13eee3b4a8ebc508b3cb643220cb5a2af6deab1a';

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
    r'1f33954126138ca2306835b06b14506a5568c54e';

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
