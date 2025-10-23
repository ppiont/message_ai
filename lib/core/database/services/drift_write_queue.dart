/// Centralized write queue for all Drift database operations.
///
/// This service ensures that all database writes are serialized, preventing
/// SQLite's "database is locked" errors that occur with concurrent writes.
///
/// **Why This Exists:**
/// SQLite only supports a single writer at a time. When multiple services
/// (UserSyncService, MessageRepository, ConversationRepository, etc.) try to
/// write simultaneously, they compete for the lock and fail.
///
/// **How It Works:**
/// - All write operations are enqueued
/// - Operations are processed sequentially (FIFO)
/// - No concurrent writes = no database locks
/// - Deterministic behavior under load
///
/// **Usage:**
/// ```dart
/// final queue = ref.read(driftWriteQueueProvider);
/// await queue.enqueue(() => db.userDao.updateUser(uid, companion));
/// ```
library;

import 'dart:async';
import 'dart:collection';

/// A write queue that ensures sequential execution of database operations.
class DriftWriteQueue {
  /// Queue of pending write operations.
  final Queue<_QueuedOperation> _queue = Queue();

  /// Whether the queue is currently processing operations.
  bool _isProcessing = false;

  /// Number of operations currently in the queue.
  int get queueDepth => _queue.length;

  /// Whether the queue is currently processing.
  bool get isProcessing => _isProcessing;

  /// Total operations processed (for monitoring).
  int _totalProcessed = 0;

  /// Total operations processed since queue creation.
  int get totalProcessed => _totalProcessed;

  /// Enqueues a write operation and returns its result.
  ///
  /// The operation will be executed sequentially with other queued operations,
  /// preventing database lock conflicts.
  ///
  /// Example:
  /// ```dart
  /// final user = await queue.enqueue(() => db.userDao.getUserByUid(uid));
  /// ```
  Future<T> enqueue<T>(
    Future<T> Function() operation, {
    String? debugLabel,
  }) async {
    final completer = Completer<T>();
    final queuedOp = _QueuedOperation<T>(
      operation: operation,
      completer: completer,
      debugLabel: debugLabel,
    );

    _queue.add(queuedOp);

    // Log queue depth if it's getting long (potential performance issue)
    if (_queue.length > 10) {
      print(
        '⚠️ DriftWriteQueue: Queue depth is ${_queue.length} (may indicate performance issue)',
      );
    }

    // Start processing if not already running
    _processQueue();

    return completer.future;
  }

  /// Processes all operations in the queue sequentially.
  Future<void> _processQueue() async {
    // If already processing or queue is empty, return
    if (_isProcessing || _queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final queuedOp = _queue.removeFirst();
      final startTime = DateTime.now();

      try {
        // Execute the operation
        final result = await queuedOp.operation();
        queuedOp.completer.complete(result);

        _totalProcessed++;

        // Log slow operations (>500ms)
        final duration = DateTime.now().difference(startTime);
        if (duration.inMilliseconds > 500) {
          print(
            '⚠️ DriftWriteQueue: Slow operation (${duration.inMilliseconds}ms)'
            '${queuedOp.debugLabel != null ? ': ${queuedOp.debugLabel}' : ''}',
          );
        }
      } catch (e, stackTrace) {
        // Complete with error
        queuedOp.completer.completeError(e, stackTrace);

        print(
          '❌ DriftWriteQueue: Operation failed'
          '${queuedOp.debugLabel != null ? ' (${queuedOp.debugLabel})' : ''}: $e',
        );
      }
    }

    _isProcessing = false;
  }

  /// Clears all pending operations (use with caution).
  ///
  /// This will complete all pending operations with an error.
  /// Only use this during app shutdown or critical error recovery.
  void clear() {
    while (_queue.isNotEmpty) {
      final op = _queue.removeFirst();
      op.completer.completeError(
        StateError('Queue was cleared before operation could execute'),
      );
    }
    print('🧹 DriftWriteQueue: Cleared ${_queue.length} pending operations');
  }

  /// Disposes of the queue.
  void dispose() {
    clear();
  }
}

/// Internal representation of a queued operation.
class _QueuedOperation<T> {
  final Future<T> Function() operation;
  final Completer<T> completer;
  final String? debugLabel;

  _QueuedOperation({
    required this.operation,
    required this.completer,
    this.debugLabel,
  });
}
