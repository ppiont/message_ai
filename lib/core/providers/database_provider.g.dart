// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$databaseHash() => r'ca312e004122d72908cbe3ea01f6b32ea7385150';

/// Provides the application database instance
///
/// This is a singleton provider that creates and manages the app's drift database.
/// The database is automatically disposed when no longer needed.
///
/// Usage:
/// ```dart
/// final database = ref.watch(databaseProvider);
/// ```
///
/// Copied from [database].
@ProviderFor(database)
final databaseProvider = Provider<AppDatabase>.internal(
  database,
  name: r'databaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$databaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DatabaseRef = ProviderRef<AppDatabase>;
String _$messageDaoHash() => r'2ca3b0ca914830edaa8bdeb3363967f0089f1416';

/// Provides access to the MessageDao
///
/// This provider gives access to all message-related database operations.
///
/// Usage:
/// ```dart
/// final messageDao = ref.watch(messageDaoProvider);
/// final messages = await messageDao.getMessagesForConversation('conv-1');
/// ```
///
/// Copied from [messageDao].
@ProviderFor(messageDao)
final messageDaoProvider = AutoDisposeProvider<MessageDao>.internal(
  messageDao,
  name: r'messageDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$messageDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MessageDaoRef = AutoDisposeProviderRef<MessageDao>;
String _$conversationDaoHash() => r'38595f8d3d0bb360e7e762f0d4b3ccdf2c4c55b9';

/// Provides access to the ConversationDao
///
/// This provider gives access to all conversation-related database operations.
///
/// Usage:
/// ```dart
/// final conversationDao = ref.watch(conversationDaoProvider);
/// final conversations = await conversationDao.getAllConversations();
/// ```
///
/// Copied from [conversationDao].
@ProviderFor(conversationDao)
final conversationDaoProvider = AutoDisposeProvider<ConversationDao>.internal(
  conversationDao,
  name: r'conversationDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$conversationDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationDaoRef = AutoDisposeProviderRef<ConversationDao>;
String _$userDaoHash() => r'09296b0f23da62b8ca871122b328dbf5e42685d2';

/// Provides access to the UserDao
///
/// This provider gives access to all user-related database operations.
///
/// Usage:
/// ```dart
/// final userDao = ref.watch(userDaoProvider);
/// final user = await userDao.getUserByUid('user-123');
/// ```
///
/// Copied from [userDao].
@ProviderFor(userDao)
final userDaoProvider = AutoDisposeProvider<UserDao>.internal(
  userDao,
  name: r'userDaoProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userDaoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UserDaoRef = AutoDisposeProviderRef<UserDao>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
