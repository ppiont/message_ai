import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// A write queue that ensures sequential execution of database operations.
class DriftWriteQueue {
  /// Queue of pending write operations.
  final Queue<_QueuedOperation<dynamic>> _queue =
      Queue<_QueuedOperation<dynamic>>();

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
      debugPrint(
        '⚠️ DriftWriteQueue: Queue depth is ${_queue.length} (may indicate performance issue)',
      );
    }

    // Start processing if not already running
    await _processQueue();

    return completer.future;
  }

  /// Processes all operations in the queue sequentially.
  Future<void> _processQueue() async {
    // If already processing or queue is empty, return
    if (_isProcessing || _queue.isEmpty) {
      return;
    }

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
          debugPrint(
            '⚠️ DriftWriteQueue: Slow operation (${duration.inMilliseconds}ms)'
            '${queuedOp.debugLabel != null ? ': ${queuedOp.debugLabel}' : ''}',
          );
        }
      } catch (e, stackTrace) {
        // Complete with error
        queuedOp.completer.completeError(e, stackTrace);

        debugPrint(
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
    debugPrint(
      '🧹 DriftWriteQueue: Cleared ${_queue.length} pending operations',
    );
  }

  /// Disposes of the queue.
  void dispose() {
    clear();
  }
}

/// Internal representation of a queued operation.
class _QueuedOperation<T> {
  _QueuedOperation({
    required this.operation,
    required this.completer,
    this.debugLabel,
  });
  final Future<T> Function() operation;
  final Completer<T> completer;
  final String? debugLabel;
}
