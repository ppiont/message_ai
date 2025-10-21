// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the application database instance
///
/// This is a singleton provider that creates and manages the app's drift database.
/// The database is automatically disposed when no longer needed.
///
/// Usage:
/// ```dart
/// final database = ref.watch(databaseProvider);
/// ```

@ProviderFor(database)
const databaseProvider = DatabaseProvider._();

/// Provides the application database instance
///
/// This is a singleton provider that creates and manages the app's drift database.
/// The database is automatically disposed when no longer needed.
///
/// Usage:
/// ```dart
/// final database = ref.watch(databaseProvider);
/// ```

final class DatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Provides the application database instance
  ///
  /// This is a singleton provider that creates and manages the app's drift database.
  /// The database is automatically disposed when no longer needed.
  ///
  /// Usage:
  /// ```dart
  /// final database = ref.watch(databaseProvider);
  /// ```
  const DatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'databaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$databaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return database(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$databaseHash() => r'c246ee79f92b36699e5f12fedc074f40524f2015';

/// Provides access to the MessageDao
///
/// This provider gives access to all message-related database operations.
///
/// Usage:
/// ```dart
/// final messageDao = ref.watch(messageDaoProvider);
/// final messages = await messageDao.getMessagesForConversation('conv-1');
/// ```

@ProviderFor(messageDao)
const messageDaoProvider = MessageDaoProvider._();

/// Provides access to the MessageDao
///
/// This provider gives access to all message-related database operations.
///
/// Usage:
/// ```dart
/// final messageDao = ref.watch(messageDaoProvider);
/// final messages = await messageDao.getMessagesForConversation('conv-1');
/// ```

final class MessageDaoProvider
    extends $FunctionalProvider<MessageDao, MessageDao, MessageDao>
    with $Provider<MessageDao> {
  /// Provides access to the MessageDao
  ///
  /// This provider gives access to all message-related database operations.
  ///
  /// Usage:
  /// ```dart
  /// final messageDao = ref.watch(messageDaoProvider);
  /// final messages = await messageDao.getMessagesForConversation('conv-1');
  /// ```
  const MessageDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'messageDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$messageDaoHash();

  @$internal
  @override
  $ProviderElement<MessageDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MessageDao create(Ref ref) {
    return messageDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MessageDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MessageDao>(value),
    );
  }
}

String _$messageDaoHash() => r'08898cb424ee723668cf2356098fd99f6a9c7f3f';

/// Provides access to the ConversationDao
///
/// This provider gives access to all conversation-related database operations.
///
/// Usage:
/// ```dart
/// final conversationDao = ref.watch(conversationDaoProvider);
/// final conversations = await conversationDao.getAllConversations();
/// ```

@ProviderFor(conversationDao)
const conversationDaoProvider = ConversationDaoProvider._();

/// Provides access to the ConversationDao
///
/// This provider gives access to all conversation-related database operations.
///
/// Usage:
/// ```dart
/// final conversationDao = ref.watch(conversationDaoProvider);
/// final conversations = await conversationDao.getAllConversations();
/// ```

final class ConversationDaoProvider
    extends
        $FunctionalProvider<ConversationDao, ConversationDao, ConversationDao>
    with $Provider<ConversationDao> {
  /// Provides access to the ConversationDao
  ///
  /// This provider gives access to all conversation-related database operations.
  ///
  /// Usage:
  /// ```dart
  /// final conversationDao = ref.watch(conversationDaoProvider);
  /// final conversations = await conversationDao.getAllConversations();
  /// ```
  const ConversationDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationDaoHash();

  @$internal
  @override
  $ProviderElement<ConversationDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConversationDao create(Ref ref) {
    return conversationDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConversationDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConversationDao>(value),
    );
  }
}

String _$conversationDaoHash() => r'9533bb0c147b85bbd8b064734aed948c243d106f';

/// Provides access to the UserDao
///
/// This provider gives access to all user-related database operations.
///
/// Usage:
/// ```dart
/// final userDao = ref.watch(userDaoProvider);
/// final user = await userDao.getUserByUid('user-123');
/// ```

@ProviderFor(userDao)
const userDaoProvider = UserDaoProvider._();

/// Provides access to the UserDao
///
/// This provider gives access to all user-related database operations.
///
/// Usage:
/// ```dart
/// final userDao = ref.watch(userDaoProvider);
/// final user = await userDao.getUserByUid('user-123');
/// ```

final class UserDaoProvider
    extends $FunctionalProvider<UserDao, UserDao, UserDao>
    with $Provider<UserDao> {
  /// Provides access to the UserDao
  ///
  /// This provider gives access to all user-related database operations.
  ///
  /// Usage:
  /// ```dart
  /// final userDao = ref.watch(userDaoProvider);
  /// final user = await userDao.getUserByUid('user-123');
  /// ```
  const UserDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userDaoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userDaoHash();

  @$internal
  @override
  $ProviderElement<UserDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  UserDao create(Ref ref) {
    return userDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserDao>(value),
    );
  }
}

String _$userDaoHash() => r'1f5bcc38defbf22a77df27fccff0ae4d120b87e9';
