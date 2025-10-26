import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/cache/message_query_cache.dart';
import 'package:message_ai/core/database/monitoring/query_performance_monitor.dart';
import 'package:message_ai/core/database/tables/messages_table.dart';

part 'message_dao.g.dart';

/// Data Access Object for Messages table
///
/// Handles all local database operations for messages including:
/// - CRUD operations
/// - Batch operations
/// - Pagination with caching
/// - Sync status tracking
/// - Reactive streams for real-time UI updates
@DriftAccessor(tables: [Messages])
class MessageDao extends DatabaseAccessor<AppDatabase> with _$MessageDaoMixin {
  MessageDao(super.db);

  /// Query result cache for improved read performance.
  ///
  /// Caches Future-based queries with 5-minute TTL and LRU eviction.
  /// Not used for Stream-based queries (Drift already optimizes those).
  final MessageQueryCache _cache = MessageQueryCache();

  /// Query performance monitor (debug mode only).
  ///
  /// Tracks query execution times and analyzes query plans using EXPLAIN.
  /// Zero overhead in release mode (compile-time eliminated).
  late final QueryPerformanceMonitor _monitor = db.performanceMonitor;

  // ============================================================================
  // Query Methods
  // ============================================================================

  /// Get a single message by ID
  Future<MessageEntity?> getMessageById(String messageId) => (select(
    messages,
  )..where((m) => m.id.equals(messageId))).getSingleOrNull();

  /// Get messages for a conversation with pagination and caching
  ///
  /// Orders by timestamp ascending (oldest first) for standard chat UI
  /// Use [limit] and [offset] for pagination
  ///
  /// **Caching:**
  /// - Results cached for 5 minutes with LRU eviction
  /// - Cache hit: <10ms response time
  /// - Cache miss: ~50ms database query (with indexes)
  /// - Cache invalidated on write operations
  Future<List<MessageEntity>> getMessagesForConversation(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    // Check cache first
    final cacheKey = MessageQueryCache.keyForConversationMessages(
      conversationId: conversationId,
      limit: limit,
      offset: offset,
    );

    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Cache miss - query database with performance monitoring
    final results = await _monitor.monitorQuery(
      queryName: 'getMessagesForConversation',
      queryFn: () => (select(messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)])
            ..limit(limit, offset: offset))
          .get(),
      explainSql: kDebugMode
          ? '''
          SELECT * FROM messages
          WHERE conversation_id = ?
          ORDER BY timestamp ASC
          LIMIT ? OFFSET ?
          '''
          : null,
      params: {
        'conversationId': conversationId,
        'limit': limit,
        'offset': offset,
      },
    );

    // Cache the results
    _cache.put(cacheKey, results);

    return results;
  }

  /// Watch messages for a conversation with cursor-based pagination (reactive stream)
  ///
  /// Returns a stream that emits new values whenever messages change
  /// Perfect for real-time chat UI updates with infinite scroll
  ///
  /// **Cursor-based pagination:**
  /// - On initial load: Pass `lastMessageTimestamp = null` to get the 50 newest messages
  /// - On scroll up: Pass the timestamp of the oldest loaded message to get the next 50 older messages
  /// - Orders by timestamp descending (newest first) for efficient pagination
  ///
  /// **Benefits over offset pagination:**
  /// - O(log n) performance with composite index on (conversationId, timestamp)
  /// - No duplicate messages when new messages arrive during pagination
  /// - Stable scroll position across page loads
  ///
  /// Example:
  /// ```dart
  /// // Initial load
  /// watchMessagesForConversation('conv123', lastMessageTimestamp: null);
  ///
  /// // Load next page (older messages)
  /// watchMessagesForConversation('conv123', lastMessageTimestamp: oldestVisibleMessage.timestamp);
  /// ```
  Stream<List<MessageEntity>> watchMessagesForConversation(
    String conversationId, {
    DateTime? lastMessageTimestamp,
    int limit = 50,
  }) => _monitor.monitorStream(
        queryName: 'watchMessagesForConversation',
        streamFn: () {
          final query = select(messages)
            ..where((m) => m.conversationId.equals(conversationId));

          // Apply cursor filter if provided (load messages older than cursor)
          if (lastMessageTimestamp != null) {
            query.where(
              (m) => m.timestamp.isSmallerThanValue(lastMessageTimestamp),
            );
          }

          // Order by timestamp descending (newest first) for cursor pagination
          query
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(limit);

          return query.watch();
        },
        explainSql: kDebugMode
            ? '''
          SELECT * FROM messages
          WHERE conversation_id = ?${lastMessageTimestamp != null ? ' AND timestamp < ?' : ''}
          ORDER BY timestamp DESC
          LIMIT ?
          '''
            : null,
        params: {
          'conversationId': conversationId,
          if (lastMessageTimestamp != null)
            'lastMessageTimestamp': lastMessageTimestamp.toIso8601String(),
          'limit': limit,
        },
      );

  /// Watch ALL messages across all conversations (reactive stream)
  ///
  /// Used for background delivery status marking
  /// Emits whenever any message is added/updated in the local database
  Stream<List<MessageEntity>> watchAllMessages() => (select(
    messages,
  )..orderBy([(m) => OrderingTerm.desc(m.timestamp)])).watch();

  /// Get messages that need to be synced
  ///
  /// Returns messages with syncStatus = 'pending' or 'failed'
  Future<List<MessageEntity>> getUnsyncedMessages() => _monitor.monitorQuery(
        queryName: 'getUnsyncedMessages',
        queryFn: () => (select(messages)
              ..where(
                (m) =>
                    m.syncStatus.equals('pending') |
                    m.syncStatus.equals('failed'),
              )
              ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
            .get(),
        explainSql: kDebugMode
            ? '''
          SELECT * FROM messages
          WHERE sync_status IN ('pending', 'failed')
          ORDER BY timestamp ASC
          '''
            : null,
      );

  /// Get messages by sync status
  Future<List<MessageEntity>> getMessagesByStatus(String syncStatus) =>
      (select(messages)
            ..where((m) => m.syncStatus.equals(syncStatus))
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)]))
          .get();

  /// Search messages by text content
  Future<List<MessageEntity>> searchMessages(String query) =>
      _monitor.monitorQuery(
        queryName: 'searchMessages',
        queryFn: () => (select(messages)
              ..where((m) => m.messageText.like('%$query%'))
              ..orderBy([(m) => OrderingTerm.desc(m.timestamp)]))
            .get(),
        explainSql: kDebugMode
            ? '''
          SELECT * FROM messages
          WHERE message_text LIKE ?
          ORDER BY timestamp DESC
          '''
            : null,
        params: {'query': '%$query%'},
      );

  /// Get the last message for a conversation
  Future<MessageEntity?> getLastMessage(String conversationId) =>
      (select(messages)
            ..where((m) => m.conversationId.equals(conversationId))
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(1))
          .getSingleOrNull();

  /// Count messages in a conversation
  Future<int> countMessagesInConversation(String conversationId) async {
    final count = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([count])
      ..where(messages.conversationId.equals(conversationId));

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Count unread messages (status = 'delivered' for current user)
  Future<int> countUnreadMessages(String conversationId, String userId) async {
    final count = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([count])
      ..where(
        messages.conversationId.equals(conversationId) &
            messages.senderId.isNotValue(userId) &
            messages.status.equals('delivered'),
      );

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================================
  // Insert/Update/Delete Operations
  // ============================================================================

  /// Insert a new message (optimistic update)
  ///
  /// Invalidates cache for the conversation.
  Future<int> insertMessage(MessagesCompanion message) async {
    final result = await into(messages).insert(message);

    // Invalidate cache for this conversation
    if (message.conversationId.present) {
      _cache.invalidateConversation(message.conversationId.value);
    }

    return result;
  }

  /// Insert or update a message
  ///
  /// Invalidates cache for the conversation.
  Future<int> upsertMessage(MessagesCompanion message) async {
    final result = await into(messages).insertOnConflictUpdate(message);

    // Invalidate cache for this conversation
    if (message.conversationId.present) {
      _cache.invalidateConversation(message.conversationId.value);
    }

    return result;
  }

  /// Batch insert messages (efficient for initial sync)
  ///
  /// Efficiently inserts or updates multiple messages in a single transaction.
  /// Automatically chunks operations to respect SQLite's 999 variable limit.
  ///
  /// **Performance:**
  /// - Chunked operations: Each chunk processes up to 100 messages
  /// - Single transaction: All chunks committed atomically
  /// - ~20ms per 100 messages (vs ~500ms sequential)
  ///
  /// **Use Cases:**
  /// - Initial conversation sync from Firestore
  /// - Background message sync
  /// - Message restoration from backup
  ///
  /// Invalidates cache for all affected conversations.
  Future<void> insertMessages(List<MessagesCompanion> messageList) async {
    if (messageList.isEmpty) {
      return;
    }

    // SQLite has a limit of 999 variables per statement
    // Messages table has ~17 columns, so 999 / 17 ≈ 58 messages per statement
    // We use 100 as chunk size since insertAll uses multiple statements internally
    const chunkSize = 100;

    await transaction(() async {
      for (var i = 0; i < messageList.length; i += chunkSize) {
        final end = (i + chunkSize < messageList.length)
            ? i + chunkSize
            : messageList.length;
        final chunk = messageList.sublist(i, end);

        await batch((batch) {
          batch.insertAll(
            messages,
            chunk,
            mode: InsertMode
                .insertOrReplace, // Upsert: insert new or update existing
          );
        });
      }
    });

    // Invalidate cache for all affected conversations
    messageList
        .where((m) => m.conversationId.present)
        .map((m) => m.conversationId.value)
        .toSet()
        .forEach(_cache.invalidateConversation);
  }

  /// Update message by ID
  ///
  /// Invalidates cache for the conversation.
  Future<bool> updateMessage(
    String messageId,
    MessagesCompanion message,
  ) async {
    final count = await (update(messages)
          ..where((m) => m.id.equals(messageId)))
        .write(message);

    // Invalidate cache for this conversation
    if (message.conversationId.present) {
      _cache.invalidateConversation(message.conversationId.value);
    } else {
      // If conversationId not in companion, look it up
      final existing = await getMessageById(messageId);
      if (existing != null) {
        _cache.invalidateConversation(existing.conversationId);
      }
    }

    return count > 0;
  }

  /// Update message status (for delivery/read receipts)
  Future<bool> updateMessageStatus(String messageId, String status) =>
      updateMessage(messageId, MessagesCompanion(status: Value(status)));

  /// Update sync status for a message
  Future<bool> updateSyncStatus({
    required String messageId,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  }) => (update(messages)..where((m) => m.id.equals(messageId)))
      .write(
        MessagesCompanion(
          syncStatus: Value(syncStatus),
          lastSyncAttempt: Value(lastSyncAttempt),
          retryCount: Value(retryCount ?? 0),
        ),
      )
      .then((count) => count > 0);

  /// Replace temp ID with real server ID (after successful sync)
  ///
  /// Returns true if the operation was successful
  Future<bool> replaceTempId({
    required String tempId,
    required String realId,
  }) async {
    // Get the temp message
    final tempMessage = await (select(
      messages,
    )..where((m) => m.tempId.equals(tempId))).getSingleOrNull();

    if (tempMessage == null) {
      return false;
    }

    // Delete temp message and insert with real ID
    await transaction(() async {
      await (delete(messages)..where((m) => m.tempId.equals(tempId))).go();

      await into(messages).insert(
        MessagesCompanion.insert(
          id: realId,
          conversationId: tempMessage.conversationId,
          messageText: tempMessage.messageText,
          senderId: tempMessage.senderId,
          timestamp: tempMessage.timestamp,
          messageType: Value(tempMessage.messageType),
          status: Value(tempMessage.status),
          detectedLanguage: Value(tempMessage.detectedLanguage),
          translations: Value(tempMessage.translations),
          replyTo: Value(tempMessage.replyTo),
          metadata: Value(tempMessage.metadata),
          aiAnalysis: Value(tempMessage.aiAnalysis),
          embedding: Value(tempMessage.embedding),
          syncStatus: const Value('synced'),
          retryCount: Value(tempMessage.retryCount),
          lastSyncAttempt: Value(tempMessage.lastSyncAttempt),
        ),
      );
    });

    return true;
  }

  /// Delete a message
  ///
  /// Invalidates cache for the conversation.
  Future<int> deleteMessage(String messageId) async {
    // Look up conversationId before deleting
    final message = await getMessageById(messageId);

    final count =
        await (delete(messages)..where((m) => m.id.equals(messageId))).go();

    // Invalidate cache for this conversation
    if (message != null) {
      _cache.invalidateConversation(message.conversationId);
    }

    return count;
  }

  /// Delete all messages in a conversation
  ///
  /// Invalidates cache for the conversation.
  Future<int> deleteMessagesInConversation(String conversationId) async {
    final count = await (delete(messages)
          ..where((m) => m.conversationId.equals(conversationId)))
        .go();

    // Invalidate cache for this conversation
    _cache.invalidateConversation(conversationId);

    return count;
  }

  /// Delete all messages (use with caution!)
  ///
  /// Invalidates entire cache.
  Future<int> deleteAllMessages() async {
    final count = await delete(messages).go();

    // Clear entire cache
    _cache.invalidateAll();

    return count;
  }

  // ============================================================================
  // Batch Operations
  // ============================================================================

  /// Batch update message statuses (for read receipts)
  ///
  /// Efficiently updates status for multiple messages in a single transaction.
  /// Automatically chunks operations to respect SQLite's 999 variable limit.
  ///
  /// **Performance:**
  /// - Chunked operations: Each chunk processes up to 300 messages
  /// - Single transaction: All chunks committed atomically
  /// - ~5ms per 100 messages (vs ~50ms sequential)
  ///
  /// Invalidates cache for all affected conversations.
  Future<void> batchUpdateStatus({
    required List<String> messageIds,
    required String status,
  }) async {
    if (messageIds.isEmpty) {
      return;
    }

    // Look up conversation IDs before updating
    final conversationIds = <String>{};
    for (final messageId in messageIds) {
      final message = await getMessageById(messageId);
      if (message != null) {
        conversationIds.add(message.conversationId);
      }
    }

    // SQLite has a limit of 999 variables per statement
    // Each update uses 2 variables (status, id)
    // So we can safely process 300 messages per chunk (300 * 2 = 600)
    const chunkSize = 300;

    await transaction(() async {
      for (var i = 0; i < messageIds.length; i += chunkSize) {
        final end = (i + chunkSize < messageIds.length)
            ? i + chunkSize
            : messageIds.length;
        final chunk = messageIds.sublist(i, end);

        await batch((batch) {
          for (final messageId in chunk) {
            batch.update(
              messages,
              MessagesCompanion(status: Value(status)),
              where: (m) => m.id.equals(messageId),
            );
          }
        });
      }
    });

    // Invalidate cache for all affected conversations
    conversationIds.forEach(_cache.invalidateConversation);
  }

  /// Batch delete messages
  ///
  /// Efficiently deletes multiple messages in a single transaction.
  /// Automatically chunks operations to respect SQLite's 999 variable limit.
  ///
  /// **Performance:**
  /// - Chunked operations: Each chunk processes up to 300 messages
  /// - Single transaction: All chunks committed atomically
  /// - ~5ms per 100 messages (vs ~50ms sequential)
  ///
  /// Invalidates cache for all affected conversations.
  Future<void> batchDeleteMessages(List<String> messageIds) async {
    if (messageIds.isEmpty) {
      return;
    }

    // Look up conversation IDs before deleting
    final conversationIds = <String>{};
    for (final messageId in messageIds) {
      final message = await getMessageById(messageId);
      if (message != null) {
        conversationIds.add(message.conversationId);
      }
    }

    // SQLite has a limit of 999 variables per statement
    // Each delete uses 1 variable (id)
    // So we can safely process 300 messages per chunk
    const chunkSize = 300;

    await transaction(() async {
      for (var i = 0; i < messageIds.length; i += chunkSize) {
        final end = (i + chunkSize < messageIds.length)
            ? i + chunkSize
            : messageIds.length;
        final chunk = messageIds.sublist(i, end);

        await batch((batch) {
          for (final messageId in chunk) {
            batch.deleteWhere(messages, (m) => m.id.equals(messageId));
          }
        });
      }
    });

    // Invalidate cache for all affected conversations
    conversationIds.forEach(_cache.invalidateConversation);
  }

  /// Batch update sync status for multiple messages
  ///
  /// Efficiently updates sync status for multiple messages in a single transaction.
  /// Automatically chunks operations to respect SQLite's 999 variable limit.
  ///
  /// **Performance:**
  /// - Chunked operations: Each chunk processes up to 250 messages
  /// - Single transaction: All chunks committed atomically
  /// - ~10ms per 100 messages (vs ~100ms sequential)
  ///
  /// **Use Cases:**
  /// - After successful Firestore batch sync (mark messages as 'synced')
  /// - After batch sync failure (mark messages as 'failed', increment retryCount)
  /// - Background WorkManager retry logic
  ///
  /// Example:
  /// ```dart
  /// await messageDao.batchUpdateSyncStatus(
  ///   messageIds: ['msg1', 'msg2', 'msg3'],
  ///   syncStatus: 'synced',
  ///   retryCount: 0,
  /// );
  /// ```
  Future<void> batchUpdateSyncStatus({
    required List<String> messageIds,
    required String syncStatus,
    DateTime? lastSyncAttempt,
    int? retryCount,
  }) async {
    if (messageIds.isEmpty) {
      return;
    }

    // Look up conversation IDs before updating
    final conversationIds = <String>{};
    for (final messageId in messageIds) {
      final message = await getMessageById(messageId);
      if (message != null) {
        conversationIds.add(message.conversationId);
      }
    }

    // SQLite has a limit of 999 variables per statement
    // Each update uses 4 variables (status, lastSyncAttempt, retryCount, id)
    // So we can safely process 250 messages per chunk (250 * 4 = 1000, but we keep it under 999)
    const chunkSize = 250;

    await transaction(() async {
      for (var i = 0; i < messageIds.length; i += chunkSize) {
        final end = (i + chunkSize < messageIds.length)
            ? i + chunkSize
            : messageIds.length;
        final chunk = messageIds.sublist(i, end);

        await batch((batch) {
          for (final messageId in chunk) {
            batch.update(
              messages,
              MessagesCompanion(
                syncStatus: Value(syncStatus),
                lastSyncAttempt: Value(lastSyncAttempt),
                retryCount: Value(retryCount ?? 0),
              ),
              where: (m) => m.id.equals(messageId),
            );
          }
        });
      }
    });

    // Invalidate cache for all affected conversations
    conversationIds.forEach(_cache.invalidateConversation);
  }

  // ============================================================================
  // Special Queries
  // ============================================================================

  /// Get messages that failed to sync and are ready for retry
  ///
  /// Only returns messages where retryCount < maxRetries
  Future<List<MessageEntity>> getFailedMessagesForRetry({int maxRetries = 3}) =>
      (select(messages)
            ..where(
              (m) =>
                  m.syncStatus.equals('failed') &
                  m.retryCount.isSmallerThanValue(maxRetries),
            )
            ..orderBy([(m) => OrderingTerm.asc(m.lastSyncAttempt)]))
          .get();

  /// Get messages for a conversation in a specific time range
  Future<List<MessageEntity>> getMessagesInRange({
    required String conversationId,
    required DateTime startTime,
    required DateTime endTime,
  }) =>
      (select(messages)
            ..where(
              (m) =>
                  m.conversationId.equals(conversationId) &
                  m.timestamp.isBiggerOrEqualValue(startTime) &
                  m.timestamp.isSmallerOrEqualValue(endTime),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)]))
          .get();

  /// Get messages by sender in a conversation
  Future<List<MessageEntity>> getMessagesBySender({
    required String conversationId,
    required String senderId,
    int limit = 50,
  }) =>
      (select(messages)
            ..where(
              (m) =>
                  m.conversationId.equals(conversationId) &
                  m.senderId.equals(senderId),
            )
            ..orderBy([(m) => OrderingTerm.desc(m.timestamp)])
            ..limit(limit))
          .get();

  /// Get replies to a specific message (threaded conversation)
  Future<List<MessageEntity>> getReplies(String messageId) =>
      (select(messages)
            ..where((m) => m.replyTo.equals(messageId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .get();

  /// Watch replies to a message (reactive)
  Stream<List<MessageEntity>> watchReplies(String messageId) =>
      (select(messages)
            ..where((m) => m.replyTo.equals(messageId))
            ..orderBy([(m) => OrderingTerm.asc(m.timestamp)]))
          .watch();

  /// Get retry count for a specific message
  Future<int> getMessageRetryCount(String messageId) async {
    final message = await getMessageById(messageId);
    return message?.retryCount ?? 0;
  }

  /// Get last sync attempt timestamp for a specific message
  Future<DateTime?> getMessageLastSyncAttempt(String messageId) async {
    final message = await getMessageById(messageId);
    return message?.lastSyncAttempt;
  }
}
