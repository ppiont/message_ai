/// Event-driven queue system for cultural context analysis
library;

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/database/app_database.dart';
import 'package:message_ai/core/database/daos/cultural_context_queue_dao.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/core/utils/pii_detector.dart';
import 'package:message_ai/features/cultural_context/data/services/cultural_context_service.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:uuid/uuid.dart';

/// Event-driven queue system for cultural context analysis
///
/// This service implements a robust queue system for analyzing cultural context:
/// - Rate limiting: Max 10 analyses per minute
/// - Retry failed requests (max 3 attempts with exponential backoff)
/// - Persist queue state across app restarts (uses Drift)
/// - **Event-driven processing** - no polling, processes immediately on enqueue
/// - PII detection and sanitization before analysis
///
/// Design:
/// - When message is enqueued → immediately process (if under rate limit)
/// - If rate limited → delay processing until rate limit clears
/// - Failed items use exponential backoff (1s, 2s, 4s)
/// - On app restart → call resumePendingItems() once (via WorkManager)
class CulturalContextQueue {
  CulturalContextQueue({
    required CulturalContextQueueDao queueDao,
    required CulturalContextService culturalContextService,
    required MessageRepository messageRepository,
  })  : _queueDao = queueDao,
        _culturalContextService = culturalContextService,
        _messageRepository = messageRepository;

  final CulturalContextQueueDao _queueDao;
  final CulturalContextService _culturalContextService;
  final MessageRepository _messageRepository;
  final Uuid _uuid = const Uuid();

  bool _isProcessing = false;

  // Rate limiting: Track timestamps of recent analyses
  final List<DateTime> _recentAnalyses = [];
  static const int _maxAnalysesPerMinute = 10;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Add a message to the analysis queue and immediately trigger processing
  ///
  /// Returns true if added to queue, false if already queued or doesn't need analysis
  Future<bool> enqueueMessage({
    required String conversationId,
    required Message message,
    int priority = 0,
  }) async {
    // Check if already queued
    final isQueued = await _queueDao.isMessageQueued(message.id);
    if (isQueued) {
      debugPrint('CulturalContextQueue: Message ${message.id} already queued');
      return false;
    }

    // Skip if already has cultural hint
    if (message.culturalHint != null) {
      debugPrint('CulturalContextQueue: Message ${message.id} already has cultural hint');
      return false;
    }

    // Skip if no detected language
    if (message.detectedLanguage == null) {
      debugPrint('CulturalContextQueue: Message ${message.id} has no detected language');
      return false;
    }

    // Add to queue
    final queueEntry = CulturalContextQueueCompanion(
      id: Value(_uuid.v4()),
      messageId: Value(message.id),
      conversationId: Value(conversationId),
      messageText: Value(message.text),
      language: Value(message.detectedLanguage!),
      status: const Value('pending'),
      retryCount: const Value(0),
      maxRetries: const Value(3),
      createdAt: Value(DateTime.now()),
      priority: Value(priority),
    );

    await _queueDao.addToQueue(queueEntry);
    debugPrint('CulturalContextQueue: Enqueued message ${message.id}');

    // Immediately trigger processing (event-driven, no polling)
    unawaited(_processNextBatch());

    return true;
  }

  /// Process the next batch of pending items (event-driven)
  ///
  /// Called immediately when items are enqueued or when rate limit clears
  Future<void> _processNextBatch() async {
    if (_isProcessing) {
      return; // Already processing, will pick up new items
    }

    _isProcessing = true;

    try {
      // Clean up old rate limit entries
      _cleanupRateLimitHistory();

      // Get pending requests (batch of 10)
      final pendingRequests = await _queueDao.getPendingRequests();

      if (pendingRequests.isEmpty) {
        return;
      }

      debugPrint('CulturalContextQueue: Processing ${pendingRequests.length} pending requests');

      // Process each request (respecting rate limit)
      for (final request in pendingRequests) {
        // Check rate limit before each request
        if (!_canProcessMore()) {
          debugPrint('CulturalContextQueue: Rate limit reached (${_recentAnalyses.length}/$_maxAnalysesPerMinute), scheduling retry');

          // Schedule retry when rate limit clears (delayed processing)
          final oldestAnalysis = _recentAnalyses.isEmpty ? DateTime.now() : _recentAnalyses.first;
          final timeUntilClear = _rateLimitWindow - DateTime.now().difference(oldestAnalysis);

          if (timeUntilClear.isNegative) {
            // Should not happen, but retry immediately if calculation is wrong
            Future<void>.delayed(const Duration(seconds: 1), _processNextBatch);
          } else {
            // Retry when rate limit clears
            Future<void>.delayed(timeUntilClear + const Duration(milliseconds: 100), _processNextBatch);
          }
          break;
        }

        await _processRequest(request);
      }

      // Clean up old completed entries (older than 24 hours)
      await _queueDao.deleteOldCompleted(const Duration(hours: 24));
    } catch (e) {
      debugPrint('CulturalContextQueue: Error processing batch: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Resume processing pending items (call on app restart via WorkManager)
  ///
  /// This should be called once when the app starts to process any
  /// items that were queued before the app was closed.
  Future<void> resumePendingItems() async {
    debugPrint('CulturalContextQueue: Resuming pending items from previous session');
    await _processNextBatch();
  }

  /// Check if we can process more requests within rate limit
  bool _canProcessMore() {
    _cleanupRateLimitHistory();
    return _recentAnalyses.length < _maxAnalysesPerMinute;
  }

  /// Clean up old entries from rate limit history
  void _cleanupRateLimitHistory() {
    final cutoff = DateTime.now().subtract(_rateLimitWindow);
    _recentAnalyses.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  /// Process a single queue request
  Future<void> _processRequest(CulturalContextQueueEntity request) async {
    try {
      debugPrint('CulturalContextQueue: Processing request ${request.id} for message ${request.messageId}');

      // Mark as processing
      await _queueDao.markAsProcessing(request.id);

      // Detect and sanitize PII
      final piiResult = PIIDetector.detectAndSanitize(request.messageText);

      if (piiResult.containsPII) {
        debugPrint('CulturalContextQueue: Detected PII in message ${request.messageId}: ${piiResult.detectedTypes}');
        debugPrint('CulturalContextQueue: Sanitized text: ${piiResult.sanitizedText}');
      }

      // Call cultural context service with sanitized text
      final result = await _culturalContextService.analyzeCulturalContext(
        text: piiResult.sanitizedText,
        language: request.language,
      );

      // Track analysis for rate limiting
      _recentAnalyses.add(DateTime.now());

      await result.fold(
        (failure) async {
          // Analysis failed - mark as failed with retry
          debugPrint('CulturalContextQueue: Analysis failed for message ${request.messageId}: ${failure.message}');
          await _queueDao.markAsFailed(request.id, failure.message);
        },
        (culturalHint) async {
          // Analysis succeeded
          debugPrint('CulturalContextQueue: Analysis succeeded for message ${request.messageId}: ${culturalHint != null ? 'hint found' : 'no hint needed'}');

          // Update message if we got a cultural hint
          if (culturalHint != null) {
            // Fetch the current message
            final messageResult = await _messageRepository.getMessageById(
              request.conversationId,
              request.messageId,
            );

            await messageResult.fold(
              (Failure failure) async {
                debugPrint('CulturalContextQueue: Failed to fetch message ${request.messageId}: ${failure.message}');
                // Mark as failed - message might have been deleted
                await _queueDao.markAsFailed(request.id, 'Message not found');
              },
              (Message message) async {
                // Update message with cultural hint
                final updatedMessage = message.copyWith(culturalHint: culturalHint);
                await _messageRepository.updateMessage(
                  request.conversationId,
                  updatedMessage,
                );
                debugPrint('CulturalContextQueue: Updated message ${request.messageId} with cultural hint');
              },
            );
          }

          // Mark as completed
          await _queueDao.markAsCompleted(request.id);
        },
      );
    } catch (e) {
      debugPrint('CulturalContextQueue: Error processing request ${request.id}: $e');
      await _queueDao.markAsFailed(request.id, e.toString());
    }
  }

  /// Get queue statistics
  Future<Map<String, int>> getStats() => _queueDao.getQueueStats();

  /// Clear the entire queue (for testing/debugging)
  Future<void> clearQueue() => _queueDao.clearQueue();

  /// Dispose resources (currently a no-op since we don't use timers)
  void dispose() {
    // No cleanup needed - event-driven processing doesn't use timers
  }
}
