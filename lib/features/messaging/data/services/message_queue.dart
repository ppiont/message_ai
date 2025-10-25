import 'dart:async';
import 'dart:collection';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/data/services/message_sync_service.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Service for queuing and processing messages with retry logic.
///
/// Provides:
/// - Optimistic UI support (messages appear instantly)
/// - Background processing with retry
/// - Exponential backoff for failures
/// - Dead letter queue for persistent failures
class MessageQueue {
  MessageQueue({
    required MessageLocalDataSource localDataSource,
    required MessageSyncService syncService,
  }) : _localDataSource = localDataSource,
       _syncService = syncService;
  final MessageLocalDataSource _localDataSource;
  final MessageSyncService _syncService;

  // Configuration
  static const int maxRetries = 5;
  static const Duration initialRetryDelay = Duration(seconds: 2);
  static const Duration maxRetryDelay = Duration(minutes: 5);
  static const Duration processingInterval = Duration(seconds: 5);

  // Queue state
  final Queue<QueuedMessage> _queue = Queue<QueuedMessage>();
  final List<QueuedMessage> _deadLetterQueue = [];
  Timer? _processingTimer;
  bool _isProcessing = false;

  // ============================================================================
  // Public API
  // ============================================================================

  /// Starts the queue processor.
  ///
  /// Periodically processes queued messages in the background.
  void start() {
    _processingTimer = Timer.periodic(processingInterval, (_) {
      processQueue();
    });
  }

  /// Stops the queue processor.
  void stop() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  /// Adds a message to the queue for processing.
  ///
  /// The message is immediately added to local storage with 'pending' sync status,
  /// enabling optimistic UI updates.
  Future<void> enqueue({
    required String conversationId,
    required Message message,
  }) async {
    // Save to local storage immediately (optimistic UI)
    await _localDataSource.createMessage(conversationId, message);

    // Add to processing queue
    _queue.add(
      QueuedMessage(
        conversationId: conversationId,
        message: message,
        retryCount: 0,
      ),
    );
  }

  /// Processes all queued messages.
  ///
  /// Attempts to sync each message, with retry logic for failures.
  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

    _isProcessing = true;

    try {
      final messagesToProcess = _queue.toList();
      _queue.clear();

      for (final queuedMessage in messagesToProcess) {
        // Check if enough time has passed since last attempt
        if (queuedMessage.lastAttempt != null) {
          final delay = _calculateBackoffDelay(queuedMessage.retryCount);
          final nextAttemptTime = queuedMessage.lastAttempt!.add(delay);

          if (DateTime.now().isBefore(nextAttemptTime)) {
            // Not ready to retry yet - re-queue
            _queue.add(queuedMessage);
            continue;
          }
        }

        // Attempt to sync the message
        final success = await _syncService.syncMessage(
          conversationId: queuedMessage.conversationId,
          message: queuedMessage.message,
        );

        if (success) {
          // Message sent successfully - remove from queue
          continue;
        }

        // Failed - increment retry count
        final newRetryCount = queuedMessage.retryCount + 1;

        if (newRetryCount >= maxRetries) {
          // Move to dead letter queue
          _deadLetterQueue.add(
            queuedMessage.copyWith(
              retryCount: newRetryCount,
              lastAttempt: DateTime.now(),
            ),
          );

          // Mark as failed in local storage
          await _localDataSource.updateSyncStatus(
            messageId: queuedMessage.message.id,
            syncStatus: 'dead_letter',
            lastSyncAttempt: DateTime.now(),
            retryCount: newRetryCount,
          );
        } else {
          // Re-queue for retry
          _queue.add(
            queuedMessage.copyWith(
              retryCount: newRetryCount,
              lastAttempt: DateTime.now(),
            ),
          );
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Gets the current queue size.
  int get queueSize => _queue.length;

  /// Gets the dead letter queue size.
  int get deadLetterQueueSize => _deadLetterQueue.length;

  /// Gets all messages in the dead letter queue.
  List<QueuedMessage> get deadLetterMessages =>
      List.unmodifiable(_deadLetterQueue);

  /// Retries a message from the dead letter queue.
  Future<void> retryDeadLetter(String messageId) async {
    final index = _deadLetterQueue.indexWhere(
      (qm) => qm.message.id == messageId,
    );

    if (index == -1) {
      throw ArgumentError('Message not found in dead letter queue: $messageId');
    }

    final queuedMessage = _deadLetterQueue.removeAt(index);

    // Reset retry count and re-queue
    _queue.add(queuedMessage.copyWith(retryCount: 0));

    // Update sync status
    await _localDataSource.updateSyncStatus(
      messageId: messageId,
      syncStatus: 'pending',
      lastSyncAttempt: DateTime.now(),
      retryCount: 0,
    );
  }

  /// Clears the dead letter queue.
  void clearDeadLetterQueue() {
    _deadLetterQueue.clear();
  }

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Calculates exponential backoff delay based on retry count.
  Duration _calculateBackoffDelay(int retryCount) {
    final delaySeconds = initialRetryDelay.inSeconds * (1 << retryCount);
    final delay = Duration(seconds: delaySeconds);

    // Cap at max delay
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }
}

// ============================================================================
// Data Classes
// ============================================================================

/// Represents a message in the queue.
class QueuedMessage {
  QueuedMessage({
    required this.conversationId,
    required this.message,
    required this.retryCount,
    this.lastAttempt,
  });
  final String conversationId;
  final Message message;
  final int retryCount;
  final DateTime? lastAttempt;

  QueuedMessage copyWith({
    String? conversationId,
    Message? message,
    int? retryCount,
    DateTime? lastAttempt,
  }) => QueuedMessage(
    conversationId: conversationId ?? this.conversationId,
    message: message ?? this.message,
    retryCount: retryCount ?? this.retryCount,
    lastAttempt: lastAttempt ?? this.lastAttempt,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is QueuedMessage &&
        other.conversationId == conversationId &&
        other.message.id == message.id &&
        other.retryCount == retryCount &&
        other.lastAttempt == lastAttempt;
  }

  @override
  int get hashCode =>
      conversationId.hashCode ^
      message.id.hashCode ^
      retryCount.hashCode ^
      lastAttempt.hashCode;

  @override
  String toString() =>
      'QueuedMessage(conversationId: $conversationId, messageId: ${message.id}, retryCount: $retryCount, lastAttempt: $lastAttempt)';
}
