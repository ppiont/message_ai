/// Background queue system for cultural context analysis
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

/// Background queue system for cultural context analysis
///
/// This service implements a robust queue system for analyzing cultural context:
/// - Rate limiting: Max 10 analyses per minute
/// - Retry failed requests (max 3 attempts with exponential backoff)
/// - Persist queue state across app restarts (uses Drift)
/// - Process queue in background
/// - PII detection and sanitization before analysis
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

  Timer? _processingTimer;
  bool _isProcessing = false;

  // Rate limiting: Track timestamps of recent analyses
  final List<DateTime> _recentAnalyses = [];
  static const int _maxAnalysesPerMinute = 10;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Start the background queue processor
  ///
  /// Processes queue every 10 seconds
  void startProcessing() {
    if (_processingTimer != null) {
      debugPrint('CulturalContextQueue: Already processing');
      return;
    }

    debugPrint('CulturalContextQueue: Starting background processing');

    // Process immediately on start
    _processQueue();

    // Then process every 10 seconds
    _processingTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _processQueue(),
    );
  }

  /// Stop the background queue processor
  void stopProcessing() {
    debugPrint('CulturalContextQueue: Stopping background processing');
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  /// Add a message to the analysis queue
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
    return true;
  }

  /// Process the queue in background
  Future<void> _processQueue() async {
    if (_isProcessing) {
      debugPrint('CulturalContextQueue: Already processing, skipping cycle');
      return;
    }

    _isProcessing = true;

    try {
      // Clean up old rate limit entries
      _cleanupRateLimitHistory();

      // Check rate limit
      if (!_canProcessMore()) {
        debugPrint('CulturalContextQueue: Rate limit reached (${_recentAnalyses.length}/$_maxAnalysesPerMinute)');
        return;
      }

      // Get pending requests (batch of 10)
      final pendingRequests = await _queueDao.getPendingRequests();

      if (pendingRequests.isEmpty) {
        return;
      }

      debugPrint('CulturalContextQueue: Processing ${pendingRequests.length} pending requests');

      // Process each request (respecting rate limit)
      for (final request in pendingRequests) {
        if (!_canProcessMore()) {
          debugPrint('CulturalContextQueue: Rate limit reached, stopping batch');
          break;
        }

        await _processRequest(request);
      }

      // Clean up old completed entries (older than 24 hours)
      await _queueDao.deleteOldCompleted(const Duration(hours: 24));
    } catch (e) {
      debugPrint('CulturalContextQueue: Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
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

  /// Dispose resources
  void dispose() {
    stopProcessing();
  }
}
