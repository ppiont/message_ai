import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_remote_datasource.dart';
import 'package:message_ai/features/messaging/data/repositories/message_repository_impl.dart';

/// Worker to sync pending messages to Firestore
///
/// Replaces MessageSyncService and MessageQueue.
/// Runs in background via WorkManager periodic tasks.
///
/// Architecture:
/// - Queries pending messages from Drift
/// - Batch syncs to Firestore
/// - Updates local DB sync status
/// - WorkManager handles retry logic and scheduling
class MessageSyncWorker {
  MessageSyncWorker({
    required AppDatabase database,
    FirebaseFirestore? firestore,
  }) : _database = database,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _database;
  final FirebaseFirestore _firestore;

  /// Sync all pending messages to Firestore
  ///
  /// This is the main entry point called by WorkManager.
  /// Finds all messages with syncStatus = 'pending' or 'failed' and syncs them.
  Future<MessageSyncResult> syncAll() async {
    debugPrint('[MessageSyncWorker] Starting sync...');

    try {
      // Initialize data sources
      final messageLocalDataSource = MessageLocalDataSourceImpl(
        messageDao: _database.messageDao,
      );
      final messageRemoteDataSource = MessageRemoteDataSourceImpl(
        firestore: _firestore,
      );

      // Initialize repositories
      final messageRepository = MessageRepositoryImpl(
        remoteDataSource: messageRemoteDataSource,
        localDataSource: messageLocalDataSource,
      );

      // Get unsynced messages
      final unsyncedMessages = await _database.messageDao.getUnsyncedMessages();

      if (unsyncedMessages.isEmpty) {
        debugPrint('[MessageSyncWorker] No messages to sync');
        return const MessageSyncResult(synced: 0, failed: 0);
      }

      debugPrint(
        '[MessageSyncWorker] Found ${unsyncedMessages.length} messages to sync',
      );

      var synced = 0;
      var failed = 0;

      // Sync each message
      for (final messageEntity in unsyncedMessages) {
        try {
          // Get message as domain object via local datasource
          final message = await messageLocalDataSource.getMessage(
            messageEntity.id,
          );

          if (message == null) {
            debugPrint(
              '[MessageSyncWorker] Message ${messageEntity.id} not found',
            );
            failed++;
            continue;
          }

          // Create message in Firestore
          // Use conversationId from MessageEntity (Drift table)
          final result = await messageRepository.createMessage(
            messageEntity.conversationId,
            message,
          );

          await result.fold(
            (failure) async {
              // Failed - increment retry count
              final newRetryCount = messageEntity.retryCount + 1;

              await messageLocalDataSource.updateSyncStatus(
                messageId: message.id,
                syncStatus: 'failed',
                lastSyncAttempt: DateTime.now(),
                retryCount: newRetryCount,
              );

              failed++;
              debugPrint(
                '[MessageSyncWorker] Failed to sync message ${message.id}: $failure',
              );
            },
            (_) async {
              // Success - mark as synced
              await messageLocalDataSource.updateSyncStatus(
                messageId: message.id,
                syncStatus: 'synced',
                lastSyncAttempt: DateTime.now(),
                retryCount: 0,
              );

              synced++;
              debugPrint('[MessageSyncWorker] Synced message ${message.id}');
            },
          );
        } catch (e) {
          failed++;
          debugPrint('[MessageSyncWorker] Error syncing message: $e');
        }
      }

      debugPrint(
        '[MessageSyncWorker] Sync complete: $synced synced, $failed failed',
      );

      return MessageSyncResult(synced: synced, failed: failed);
    } catch (e) {
      debugPrint('[MessageSyncWorker] Sync failed: $e');
      rethrow;
    }
  }
}

/// Result of message sync operation
class MessageSyncResult {
  const MessageSyncResult({required this.synced, required this.failed});

  final int synced;
  final int failed;
}
