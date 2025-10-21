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

/// Provides the [MessageRepository] implementation.

@ProviderFor(messageRepository)
const messageRepositoryProvider = MessageRepositoryProvider._();

/// Provides the [MessageRepository] implementation.

final class MessageRepositoryProvider
    extends
        $FunctionalProvider<
          MessageRepository,
          MessageRepository,
          MessageRepository
        >
    with $Provider<MessageRepository> {
  /// Provides the [MessageRepository] implementation.
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

String _$messageRepositoryHash() => r'64198466d7b1525d08d4fe8cf0fdbcb8bcf71efb';

/// Provides the [ConversationRepository] implementation.

@ProviderFor(conversationRepository)
const conversationRepositoryProvider = ConversationRepositoryProvider._();

/// Provides the [ConversationRepository] implementation.

final class ConversationRepositoryProvider
    extends
        $FunctionalProvider<
          ConversationRepository,
          ConversationRepository,
          ConversationRepository
        >
    with $Provider<ConversationRepository> {
  /// Provides the [ConversationRepository] implementation.
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
    r'e4c92eac36c3008160bbbca958e50f5fb245a371';

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
    r'5ffe44e5f7e3dc42e9462ebf9c8e5977a105a8fe';

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
    r'2d7ccec530050d7159ed36bb19be47c7e72f82ac';

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
