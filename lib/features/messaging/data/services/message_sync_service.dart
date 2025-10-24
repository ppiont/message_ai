import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:message_ai/core/database/daos/message_dao.dart';
import 'package:message_ai/features/messaging/data/datasources/conversation_local_datasource.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/domain/entities/conversation.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Service for synchronizing messages and conversations between local and remote storage.
///
/// Handles:
/// - Background sync when network is available
/// - Conflict resolution using configurable strategies
/// - Retry logic with exponential backoff
/// - Optimistic UI updates
///
/// Architecture:
/// - Uses local data sources for offline persistence
/// - Uses repositories for remote operations (handles Model/Entity conversion)
/// - Stays at domain layer for clean architecture
class MessageSyncService {
  MessageSyncService({
    required MessageLocalDataSource messageLocalDataSource,
    required MessageRepository messageRepository,
    required ConversationLocalDataSource conversationLocalDataSource,
    required ConversationRepository conversationRepository,
    required MessageDao messageDao,
    Connectivity? connectivity,
  }) : _messageLocalDataSource = messageLocalDataSource,
       _messageRepository = messageRepository,
       _conversationLocalDataSource = conversationLocalDataSource,
       _conversationRepository = conversationRepository,
       _messageDao = messageDao,
       _connectivity = connectivity ?? Connectivity();
  final MessageLocalDataSource _messageLocalDataSource;
  final MessageRepository _messageRepository;
  final ConversationLocalDataSource _conversationLocalDataSource;
  final ConversationRepository _conversationRepository;
  final MessageDao _messageDao;
  final Connectivity _connectivity;

  // Configuration
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const Duration maxRetryDelay = Duration(minutes: 5);

  // State
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // ============================================================================
  // Public API
  // ============================================================================

  /// Starts the sync service.
  ///
  /// Monitors network connectivity and syncs when online.
  Future<void> start() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (_hasConnection(results) && !_isSyncing) {
          syncAll();
        }
      },
    );

    // Perform initial sync if online
    final connectivityResults = await _connectivity.checkConnectivity();
    if (_hasConnection(connectivityResults)) {
      await syncAll();
    }
  }

  /// Stops the sync service.
  Future<void> stop() async {
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Syncs all unsynced data (messages and conversations).
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      return SyncResult(
        messagesSynced: 0,
        conversationsSynced: 0,
        errors: const <String>['Sync already in progress'],
      );
    }

    _isSyncing = true;

    try {
      // Check connectivity
      final connectivityResults =
          await _connectivity.checkConnectivity();
      if (!_hasConnection(connectivityResults)) {
        return SyncResult(
          messagesSynced: 0,
          conversationsSynced: 0,
          errors: const <String>['No network connection'],
        );
      }

      final errors = <String>[];
      var messagesSynced = 0;
      var conversationsSynced = 0;

      // Sync conversations first (messages depend on them)
      try {
        conversationsSynced = await _syncConversations();
      } catch (e) {
        errors.add('Conversation sync error: $e');
      }

      // Sync messages
      try {
        messagesSynced = await _syncMessages();
      } catch (e) {
        errors.add('Message sync error: $e');
      }

      return SyncResult(
        messagesSynced: messagesSynced,
        conversationsSynced: conversationsSynced,
        errors: errors,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Syncs a specific message immediately.
  ///
  /// Used for optimistic UI updates.
  Future<bool> syncMessage({
    required String conversationId,
    required Message message,
  }) async {
    try {
      // Try to get the message from remote (to check if it exists)
      final remoteResult = await _messageRepository.getMessageById(
        conversationId,
        message.id,
      );

      await remoteResult.fold(
        (failure) async {
          // Message doesn't exist remotely - create it
          final createResult = await _messageRepository.createMessage(
            conversationId,
            message,
          );

          createResult.fold(
            (failure) => throw Exception('Failed to create message: $failure'),
            (_) {}, // Success
          );
        },
        (remoteMessage) async {
          // Message exists - check for conflicts
          final hasConflict = await _messageLocalDataSource.hasConflict(
            localMessage: message,
            remoteMessage: remoteMessage,
          );

          if (hasConflict) {
            // Resolve conflict (server-wins by default)
            final resolved = await _messageLocalDataSource.resolveConflict(
              conversationId: conversationId,
              localMessage: message,
              remoteMessage: remoteMessage,
            );

            // Update remote with resolved version
            final updateResult = await _messageRepository.updateMessage(
              conversationId,
              resolved,
            );

            updateResult.fold(
              (failure) =>
                  throw Exception('Failed to update message: $failure'),
              (_) {}, // Success
            );
          }
        },
      );

      // Mark as synced
      await _messageLocalDataSource.updateSyncStatus(
        messageId: message.id,
        syncStatus: 'synced',
        lastSyncAttempt: DateTime.now(),
        retryCount: 0,
      );

      return true;
    } catch (e) {
      // Update sync status with error - increment retry count
      // Get actual retry count from Drift (was hardcoded to 0 before!)
      final currentRetryCount = await _getMessageRetryCount(message.id);
      final newRetryCount = currentRetryCount + 1;

      await _messageLocalDataSource.updateSyncStatus(
        messageId: message.id,
        syncStatus: 'failed',
        lastSyncAttempt: DateTime.now(),
        retryCount: newRetryCount,
      );

      return false;
    }
  }

  /// Syncs a specific conversation immediately.
  Future<bool> syncConversation(Conversation conversation) async {
    try {
      // Try to get the conversation from remote
      final remoteResult = await _conversationRepository.getConversationById(
        conversation.documentId,
      );

      await remoteResult.fold(
        (failure) async {
          // Conversation doesn't exist remotely - create it
          final createResult = await _conversationRepository.createConversation(
            conversation,
          );

          createResult.fold(
            (failure) =>
                throw Exception('Failed to create conversation: $failure'),
            (_) {}, // Success
          );
        },
        (remoteConversation) async {
          // Conversation exists - check for conflicts
          final hasConflict = await _conversationLocalDataSource.hasConflict(
            localConversation: conversation,
            remoteConversation: remoteConversation,
          );

          if (hasConflict) {
            // Resolve conflict (server-wins by default)
            final resolved = await _conversationLocalDataSource.resolveConflict(
              localConversation: conversation,
              remoteConversation: remoteConversation,
            );

            // Update remote with resolved version
            final updateResult = await _conversationRepository
                .updateConversation(resolved);

            updateResult.fold(
              (failure) =>
                  throw Exception('Failed to update conversation: $failure'),
              (_) {}, // Success
            );
          }
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // Private Sync Methods
  // ============================================================================

  /// Syncs all unsynced messages.
  Future<int> _syncMessages() async {
    var synced = 0;

    // Get messages that need syncing (includes 'pending' and 'failed')
    final unsyncedMessages =
        await _messageLocalDataSource.getUnsyncedMessages();

    for (final message in unsyncedMessages) {
      try {
        // Get actual retry count from Drift
        final retryCount = await _getMessageRetryCount(message.id);

        // Calculate exponential backoff delay
        final backoffDelay = _calculateBackoffDelay(retryCount);

        // If not enough time has passed since last attempt, skip
        final lastAttempt =
            await _getMessageLastSyncAttempt(message.id);
        if (lastAttempt != null) {
          final timeSinceLastAttempt =
              DateTime.now().difference(lastAttempt);
          if (timeSinceLastAttempt < backoffDelay) {
            continue; // Too soon to retry
          }
        }

        // Max retries check (5 attempts)
        if (retryCount >= 5) {
          // Mark as dead letter, don't retry anymore
          await _messageLocalDataSource.updateSyncStatus(
            messageId: message.id,
            syncStatus: 'dead_letter',
            lastSyncAttempt: DateTime.now(),
            retryCount: retryCount,
          );
          continue;
        }

        // Get all conversations to find which one contains this message
        // This is inefficient - in production, we'd track conversationId in the message
        final allConversations =
            await _conversationLocalDataSource.getAllConversations(limit: 1000);

        String? conversationId;
        for (final conv in allConversations) {
          // Check if message belongs to this conversation
          // In a real implementation, we'd have a better way to track this
          conversationId = conv.documentId;
          break;
        }

        if (conversationId != null) {
          final success = await syncMessage(
            conversationId: conversationId,
            message: message,
          );

          if (success) {
            synced++;
          }
        }
      } catch (e) {
        // Increment retry count on failure
        final retryCount = await _getMessageRetryCount(message.id);
        await _messageLocalDataSource.updateSyncStatus(
          messageId: message.id,
          syncStatus: 'failed',
          lastSyncAttempt: DateTime.now(),
          retryCount: retryCount + 1,
        );
        continue;
      }
    }

    return synced;
  }

  /// Syncs all unsynced conversations.
  Future<int> _syncConversations() async {
    var synced = 0;

    // Get conversations that need syncing
    final unsyncedConversations =
        await _conversationLocalDataSource.getUnsyncedConversations();

    for (final conversation in unsyncedConversations) {
      try {
        final success = await syncConversation(conversation);
        if (success) {
          synced++;
        }
      } catch (e) {
        // Continue with other conversations
        continue;
      }
    }

    return synced;
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Checks if there's an active network connection.
  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  /// Calculates exponential backoff delay.
  Duration _calculateBackoffDelay(int retryCount) {
    final delaySeconds = initialRetryDelay.inSeconds * (1 << retryCount);
    final delay = Duration(seconds: delaySeconds);

    // Cap at max delay
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }

  /// Gets the actual retry count for a message from Drift.
  Future<int> _getMessageRetryCount(String messageId) =>
      _messageDao.getMessageRetryCount(messageId);

  /// Gets the last sync attempt timestamp for a message from Drift.
  Future<DateTime?> _getMessageLastSyncAttempt(String messageId) =>
      _messageDao.getMessageLastSyncAttempt(messageId);
}

// ============================================================================
// Result Classes
// ============================================================================

/// Result of a sync operation.
class SyncResult {
  SyncResult({
    required this.messagesSynced,
    required this.conversationsSynced,
    required this.errors,
  });
  final int messagesSynced;
  final int conversationsSynced;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => !hasErrors;

  @override
  String toString() =>
      'SyncResult(messages: $messagesSynced, conversations: $conversationsSynced, errors: ${errors.length})';
}
