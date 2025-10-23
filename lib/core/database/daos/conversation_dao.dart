import 'package:drift/drift.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/tables/conversations_table.dart';

part 'conversation_dao.g.dart';

/// Data Access Object for Conversations table
///
/// Handles all local database operations for conversations including:
/// - CRUD operations
/// - Participant-based queries
/// - Last message updates
/// - Unread count management
/// - Reactive streams for real-time UI updates
@DriftAccessor(tables: [Conversations])
class ConversationDao extends DatabaseAccessor<AppDatabase>
    with _$ConversationDaoMixin {
  ConversationDao(super.db);

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get a single conversation by document ID
  Future<ConversationEntity?> getConversationById(String documentId) => (select(
      conversations,
    )..where((c) => c.documentId.equals(documentId))).getSingleOrNull();

  /// Get all conversations ordered by last update (newest first)
  Future<List<ConversationEntity>> getAllConversations({
    int limit = 50,
    int offset = 0,
  }) => (select(conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)])
          ..limit(limit, offset: offset))
        .get();

  /// Watch all conversations (reactive stream)
  ///
  /// Returns a stream that emits new values whenever conversations change
  /// Perfect for the conversation list UI
  Stream<List<ConversationEntity>> watchAllConversations({int limit = 50}) => (select(conversations)
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)])
          ..limit(limit))
        .watch();

  /// Get conversations where a specific user is a participant
  ///
  /// Uses JSON contains check on participantIds field
  Future<List<ConversationEntity>> getConversationsByParticipant(
    String userId, {
    int limit = 50,
  }) => (select(conversations)
          ..where((c) => c.participantIds.like('%"$userId"%'))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)])
          ..limit(limit))
        .get();

  /// Watch conversations for a specific participant (reactive)
  Stream<List<ConversationEntity>> watchConversationsByParticipant(
    String userId, {
    int limit = 50,
  }) => (select(conversations)
          ..where((c) => c.participantIds.like('%"$userId"%'))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)])
          ..limit(limit))
        .watch();

  /// Get conversations by type (direct or group)
  Future<List<ConversationEntity>> getConversationsByType(
    String type, {
    int limit = 50,
  }) => (select(conversations)
          ..where((c) => c.conversationType.equals(type))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)])
          ..limit(limit))
        .get();

  /// Get direct conversation between two users
  ///
  /// Returns the 1-to-1 conversation if it exists
  Future<ConversationEntity?> getDirectConversation(
    String userId1,
    String userId2,
  ) async {
    final conversations =
        await (select(this.conversations)..where(
              (c) =>
                  c.conversationType.equals('direct') &
                  c.participantIds.like('%"$userId1"%') &
                  c.participantIds.like('%"$userId2"%'),
            ))
            .get();

    return conversations.isEmpty ? null : conversations.first;
  }

  /// Count total conversations
  Future<int> countConversations() async {
    final count = conversations.documentId.count();
    final query = selectOnly(conversations)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Count unread conversations for a user
  ///
  /// Counts conversations where the user has unread messages
  Future<int> countUnreadConversations(String userId) async {
    final allConversations = await getAllConversations();
    var unreadCount = 0;

    for (final conv in allConversations) {
      // Parse unreadCount JSON to check if user has unread messages
      if (conv.unreadCount.contains('"$userId"')) {
        // Simple check - in production you'd parse JSON properly
        final regex = RegExp('"$userId"\\s*:\\s*(\\d+)');
        final match = regex.firstMatch(conv.unreadCount);
        if (match != null) {
          final count = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (count > 0) {
            unreadCount++;
          }
        }
      }
    }

    return unreadCount;
  }

  // ============================================================================
  // Insert/Update/Delete Operations
  // ============================================================================

  /// Insert a new conversation
  Future<int> insertConversation(ConversationsCompanion conversation) => into(conversations).insert(conversation);

  /// Insert or update a conversation
  Future<int> upsertConversation(ConversationsCompanion conversation) => into(conversations).insertOnConflictUpdate(conversation);

  /// Batch insert conversations (efficient for initial sync)
  Future<void> insertConversations(
    List<ConversationsCompanion> conversationList,
  ) async {
    await batch((batch) {
      batch.insertAll(
        conversations,
        conversationList,
        mode: InsertMode.insertOrReplace, // Upsert: insert new or update existing
      );
    });
  }

  /// Update conversation by document ID
  Future<bool> updateConversation(
    String documentId,
    ConversationsCompanion conversation,
  ) => (update(conversations)
          ..where((c) => c.documentId.equals(documentId)))
        .write(conversation)
        .then((count) => count > 0);

  /// Update last message information
  Future<bool> updateLastMessage({
    required String documentId,
    required String messageText,
    required String senderId,
    required String senderName,
    required DateTime timestamp,
    required String messageType,
    Map<String, String>? translations,
  }) => updateConversation(
      documentId,
      ConversationsCompanion(
        lastMessageText: Value(messageText),
        lastMessageSenderId: Value(senderId),
        lastMessageSenderName: Value(senderName),
        lastMessageTimestamp: Value(timestamp),
        lastMessageType: Value(messageType),
        lastMessageTranslations: Value(
          translations?.entries.map((e) => '"${e.key}":"${e.value}"').join(','),
        ),
        lastUpdatedAt: Value(timestamp),
      ),
    );

  /// Update unread count for specific users
  ///
  /// Increments unread count for all participants except the sender
  Future<bool> incrementUnreadCount({
    required String documentId,
    required String senderId,
    required List<String> participantIds,
  }) async {
    final conversation = await getConversationById(documentId);
    if (conversation == null) return false;

    // Parse existing unread counts
    final unreadMap = <String, int>{};
    // Simple JSON parsing - in production use dart:convert
    for (final participantId in participantIds) {
      if (participantId != senderId) {
        final regex = RegExp('"$participantId"\\s*:\\s*(\\d+)');
        final match = regex.firstMatch(conversation.unreadCount);
        final currentCount = match != null
            ? int.tryParse(match.group(1) ?? '0') ?? 0
            : 0;
        unreadMap[participantId] = currentCount + 1;
      } else {
        unreadMap[participantId] = 0; // Sender has 0 unread
      }
    }

    // Convert back to JSON string
    final newUnreadCount =
        '{${unreadMap.entries.map((e) => '"${e.key}":${e.value}').join(',')}}';

    return updateConversation(
      documentId,
      ConversationsCompanion(unreadCount: Value(newUnreadCount)),
    );
  }

  /// Reset unread count for a specific user
  Future<bool> resetUnreadCount({
    required String documentId,
    required String userId,
  }) async {
    final conversation = await getConversationById(documentId);
    if (conversation == null) return false;

    // Parse and update unread counts
    final unreadMap = <String, int>{};
    final participantIds = conversation.participantIds
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .split(',');

    for (final participantId in participantIds) {
      if (participantId.trim() == userId) {
        unreadMap[participantId.trim()] = 0;
      } else {
        final regex = RegExp('"${participantId.trim()}"\\s*:\\s*(\\d+)');
        final match = regex.firstMatch(conversation.unreadCount);
        unreadMap[participantId.trim()] = match != null
            ? int.tryParse(match.group(1) ?? '0') ?? 0
            : 0;
      }
    }

    final newUnreadCount =
        '{${unreadMap.entries.map((e) => '"${e.key}":${e.value}').join(',')}}';

    return updateConversation(
      documentId,
      ConversationsCompanion(unreadCount: Value(newUnreadCount)),
    );
  }

  /// Delete a conversation
  Future<int> deleteConversation(String documentId) => (delete(
      conversations,
    )..where((c) => c.documentId.equals(documentId))).go();

  /// Delete all conversations (use with caution!)
  Future<int> deleteAllConversations() => delete(conversations).go();

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Batch update multiple conversations
  Future<void> batchUpdateConversations(
    Map<String, ConversationsCompanion> updates,
  ) async {
    await batch((batch) {
      for (final entry in updates.entries) {
        batch.update(
          conversations,
          entry.value,
          where: (c) => c.documentId.equals(entry.key),
        );
      }
    });
  }

  /// Batch delete conversations
  Future<void> batchDeleteConversations(List<String> documentIds) async {
    await batch((batch) {
      for (final documentId in documentIds) {
        batch.deleteWhere(
          conversations,
          (c) => c.documentId.equals(documentId),
        );
      }
    });
  }

  // ============================================================================
  // Special Queries
  // ============================================================================

  /// Search conversations by group name
  Future<List<ConversationEntity>> searchConversationsByName(String query) => (select(conversations)
          ..where((c) => c.groupName.like('%$query%'))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)]))
        .get();

  /// Get conversations updated after a specific time
  ///
  /// Useful for sync operations
  Future<List<ConversationEntity>> getConversationsUpdatedAfter(
    DateTime timestamp,
  ) => (select(conversations)
          ..where((c) => c.lastUpdatedAt.isBiggerThanValue(timestamp))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)]))
        .get();

  /// Get group conversations where user is admin
  Future<List<ConversationEntity>> getGroupsWhereUserIsAdmin(String userId) => (select(conversations)
          ..where(
            (c) =>
                c.conversationType.equals('group') &
                c.adminIds.like('%"$userId"%'),
          )
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)]))
        .get();

  /// Get active conversations (with recent activity)
  ///
  /// Returns conversations updated within the last N days
  Future<List<ConversationEntity>> getActiveConversations({
    int daysBack = 7,
    int limit = 50,
  }) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));
    return (select(conversations)
          ..where((c) => c.lastUpdatedAt.isBiggerThanValue(cutoffDate))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)])
          ..limit(limit))
        .get();
  }

  /// Get conversations with translation enabled
  Future<List<ConversationEntity>> getConversationsWithTranslation() => (select(conversations)
          ..where((c) => c.translationEnabled.equals(true))
          ..orderBy([(c) => OrderingTerm.desc(c.lastUpdatedAt)]))
        .get();

  /// Update last message sender name for all conversations where this user was the last sender
  ///
  /// Used when a user changes their display name to propagate
  /// the change to conversation preview text for real-time UI updates
  Future<void> updateLastMessageSenderNameForUser({
    required String userId,
    required String newSenderName,
  }) => (update(conversations)..where((c) => c.lastMessageSenderId.equals(userId)))
      .write(ConversationsCompanion(lastMessageSenderName: Value(newSenderName)));
}
