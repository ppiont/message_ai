/// Background service for analyzing cultural context of messages
library;

import 'package:flutter/foundation.dart';
import 'package:message_ai/features/authentication/domain/entities/user.dart';
import 'package:message_ai/features/cultural_context/domain/services/cultural_context_queue.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';

/// Service that analyzes cultural context of received messages in the background
///
/// This service now uses a queue-based system for robust background analysis:
/// 1. Only analyzes received messages (not sent messages)
/// 2. Only analyzes messages in foreign languages (detectedLanguage != userPreferredLanguage)
/// 3. Uses background queue with rate limiting (max 10 analyses per minute)
/// 4. Retries failed requests (max 3 attempts with exponential backoff)
/// 5. Persists queue state across app restarts
/// 6. PII detection and sanitization before analysis
///
/// Migration from Task 129:
/// - Replaced fire-and-forget approach with queue system
/// - Maintains backward compatibility with existing code
/// - Improved reliability and error handling
class CulturalContextAnalyzer {
  CulturalContextAnalyzer({
    required CulturalContextQueue queue,
  }) : _queue = queue;

  final CulturalContextQueue _queue;
  final Set<String> _analyzed = {}; // Track analyzed messages to avoid duplicates

  /// Analyze a message for cultural context in the background
  ///
  /// This now enqueues the message for background processing
  /// instead of analyzing immediately
  Future<void> analyzeMessageInBackground({
    required String conversationId,
    required Message message,
    required User currentUser,
  }) async {
    // Skip if already analyzed (in-memory cache)
    if (_analyzed.contains(message.id)) {
      debugPrint('CulturalContextAnalyzer: Message ${message.id} already analyzed (cache hit)');
      return;
    }

    // Skip if already has cultural hint
    if (message.culturalHint != null) {
      _analyzed.add(message.id);
      debugPrint('CulturalContextAnalyzer: Message ${message.id} already has cultural hint');
      return;
    }

    // Skip if message was sent by current user
    if (message.senderId == currentUser.uid) {
      debugPrint('CulturalContextAnalyzer: Skipping own message ${message.id}');
      return;
    }

    // Skip if no detected language
    if (message.detectedLanguage == null) {
      debugPrint('CulturalContextAnalyzer: Message ${message.id} has no detected language');
      return;
    }

    // Skip if message is already in user's preferred language
    if (message.detectedLanguage == currentUser.preferredLanguage) {
      debugPrint('CulturalContextAnalyzer: Message ${message.id} already in user language');
      return;
    }

    // Mark as being analyzed
    _analyzed.add(message.id);

    // Enqueue message for background analysis
    final enqueued = await _queue.enqueueMessage(
      conversationId: conversationId,
      message: message,
    );

    if (enqueued) {
      debugPrint('CulturalContextAnalyzer: Enqueued message ${message.id} for analysis');
    } else {
      debugPrint('CulturalContextAnalyzer: Message ${message.id} already queued or skipped');
    }
  }

  /// Clear the analyzed messages cache
  void clearCache() {
    _analyzed.clear();
    debugPrint('CulturalContextAnalyzer: Cleared in-memory cache');
  }

  /// Get queue statistics (for debugging)
  Future<Map<String, int>> getQueueStats() => _queue.getStats();
}
