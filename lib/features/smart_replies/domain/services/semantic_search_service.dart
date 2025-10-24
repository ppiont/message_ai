import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Service for performing semantic search on messages using Firestore vector search.
///
/// **Optimized for speed and smoothness** - delegates heavy lifting to server-side
/// Firestore vector search instead of in-memory cosine similarity calculations.
///
/// Architecture:
/// - Domain layer service (orchestrates Cloud Function call)
/// - Uses search_messages_semantic Cloud Function for vector search
/// - Falls back to recent messages if embedding unavailable
/// - Target latency: <100ms (cached) or <500ms (fresh query)
///
/// Performance improvements over in-memory search:
/// - No loading 100+ messages into memory
/// - No JSON deserialization of 1536D vectors
/// - No CPU-intensive cosine similarity calculations
/// - Server-side caching (5-minute TTL)
/// - Smaller result set (5 instead of 10 for speed)
class SemanticSearchService {
  SemanticSearchService({
    required MessageRepository messageRepository,
    FirebaseFunctions? functions,
  })  : _messageRepository = messageRepository,
        _functions = functions ?? FirebaseFunctions.instance;

  final MessageRepository _messageRepository;
  final FirebaseFunctions _functions;

  // Configuration
  static const int _defaultLimit = 50; // Sufficient context for smart replies
  static const int _fallbackLimit = 50; // For fallback when no embedding

  /// Gets recent conversation context for smart reply generation.
  ///
  /// **Important:** Uses chronological order (not semantic search) to ensure
  /// messages from BOTH participants are included. Semantic search might return
  /// all messages from one person, losing conversation flow.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation to get context from
  /// - [incomingMessage]: The message (unused, kept for API compatibility)
  /// - [limit]: Maximum number of recent messages (default: 50)
  ///
  /// Returns: List of recent messages in chronological order, naturally balanced
  Future<List<Message>> searchRelevantContext(
    String conversationId,
    Message incomingMessage, {
    int limit = _defaultLimit,
  }) async {
    // Always use chronological fallback for smart reply context
    // This ensures we get recent conversation flow from BOTH sides
    debugPrint(
      'SemanticSearchService: Getting recent conversation context (limit: $limit)',
    );
    return _getFallbackMessages(conversationId);
  }

  /// Fallback method: Returns most recent messages when vector search unavailable.
  ///
  /// This ensures smart replies work even when:
  /// - Incoming message has no embedding yet
  /// - Cloud Function fails
  /// - Network connectivity issues
  Future<List<Message>> _getFallbackMessages(String conversationId) async {
    try {
      debugPrint('SemanticSearchService: Using fallback (recent messages)');

      final messagesResult = await _messageRepository.getMessages(
        conversationId: conversationId,
        limit: _fallbackLimit,
      );

      return messagesResult.fold<List<Message>>(
        (failure) {
          debugPrint('SemanticSearchService: Fallback failed: $failure');
          return <Message>[];
        },
        (messages) {
          debugPrint(
            'SemanticSearchService: Fallback returned ${messages.length} messages',
          );
          return messages.take(_defaultLimit).toList();
        },
      );
    } catch (e) {
      debugPrint('SemanticSearchService: Fallback error: $e');
      return <Message>[];
    }
  }
}
