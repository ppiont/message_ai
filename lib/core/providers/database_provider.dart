import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/daos/message_dao.dart';
import 'package:message_ai/core/database/daos/conversation_dao.dart';
import 'package:message_ai/core/database/daos/user_dao.dart';

part 'database_provider.g.dart';

/// Provides the application database instance
///
/// This is a singleton provider that creates and manages the app's drift database.
/// The database is automatically disposed when no longer needed.
///
/// Usage:
/// ```dart
/// final database = ref.watch(databaseProvider);
/// ```
@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) {
  final db = AppDatabase();

  // Clean up database when provider is disposed
  ref.onDispose(() {
    db.close();
  });

  return db;
}

/// Provides access to the MessageDao
///
/// This provider gives access to all message-related database operations.
///
/// Usage:
/// ```dart
/// final messageDao = ref.watch(messageDaoProvider);
/// final messages = await messageDao.getMessagesForConversation('conv-1');
/// ```
@riverpod
MessageDao messageDao(Ref ref) {
  final db = ref.watch(databaseProvider);
  return db.messageDao;
}

/// Provides access to the ConversationDao
///
/// This provider gives access to all conversation-related database operations.
///
/// Usage:
/// ```dart
/// final conversationDao = ref.watch(conversationDaoProvider);
/// final conversations = await conversationDao.getAllConversations();
/// ```
@riverpod
ConversationDao conversationDao(Ref ref) {
  final db = ref.watch(databaseProvider);
  return db.conversationDao;
}

/// Provides access to the UserDao
///
/// This provider gives access to all user-related database operations.
///
/// Usage:
/// ```dart
/// final userDao = ref.watch(userDaoProvider);
/// final user = await userDao.getUserByUid('user-123');
/// ```
@riverpod
UserDao userDao(Ref ref) {
  final db = ref.watch(databaseProvider);
  return db.userDao;
}
