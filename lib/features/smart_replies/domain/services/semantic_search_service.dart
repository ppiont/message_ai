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

  // Configuration (optimized for demo speed)
  static const int _defaultLimit = 5; // Reduced from 10 for faster response
  static const int _fallbackLimit = 10; // For fallback when no embedding

  /// Searches for the most relevant messages in a conversation for RAG context.
  ///
  /// **Fast path:** Uses Firestore vector search via Cloud Function
  /// **Fallback:** Returns recent messages if embedding unavailable
  ///
  /// Parameters:
  /// - [conversationId]: The conversation to search within
  /// - [incomingMessage]: The message to find relevant context for
  /// - [limit]: Maximum number of results to return (default: 5, optimized)
  ///
  /// Returns: List of most relevant messages, sorted by relevance (descending)
  Future<List<Message>> searchRelevantContext(
    String conversationId,
    Message incomingMessage, {
    int limit = _defaultLimit,
  }) async {
    try {
      debugPrint(
        'SemanticSearchService: Searching for relevant context (limit: $limit)',
      );

      final startTime = DateTime.now();

      // Check if incoming message has embedding
      if (incomingMessage.embedding == null ||
          incomingMessage.embedding!.isEmpty) {
        debugPrint(
          'SemanticSearchService: No embedding, falling back to recent messages',
        );
        return _getFallbackMessages(conversationId);
      }

      // Call Firestore vector search Cloud Function
      try {
        final result = await _functions
            .httpsCallable('search_messages_semantic')
            .call<Map<String, dynamic>>({
          'conversationId': conversationId,
          'queryEmbedding': incomingMessage.embedding,
          'limit': limit,
        });

        final data = result.data;
        final messagesJson = data['messages'] as List<dynamic>?;
        final cached = data['cached'] as bool? ?? false;
        final latency = data['latency'] as num? ?? 0;

        if (messagesJson == null || messagesJson.isEmpty) {
          debugPrint(
            'SemanticSearchService: No results from vector search, using fallback',
          );
          return _getFallbackMessages(conversationId);
        }

        // Parse messages from JSON
        final messages = messagesJson.map((json) {
          final msgData = json as Map<String, dynamic>;
          return Message(
            id: msgData['id'] as String,
            text: msgData['text'] as String,
            senderId: msgData['senderId'] as String,
            timestamp: (msgData['timestamp'] as Timestamp).toDate(),
            type: 'text',
            status: 'sent',
            metadata: MessageMetadata.defaultMetadata(),
            detectedLanguage: msgData['detectedLanguage'] as String?,
            translations: msgData['translations'] != null
                ? Map<String, String>.from(
                    msgData['translations'] as Map<String, dynamic>,
                  )
                : null,
            // Embedding not included in response for performance
          );
        }).toList();

        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        debugPrint(
          'SemanticSearchService: Found ${messages.length} messages '
          '(${cached ? "cached" : "fresh"}, server: ${latency}ms, total: ${elapsed}ms)',
        );

        return messages;
      } on FirebaseFunctionsException catch (e) {
        debugPrint(
          'SemanticSearchService: Cloud Function error: ${e.code} - ${e.message}',
        );

        // Fallback to recent messages on error
        return _getFallbackMessages(conversationId);
      }
    } catch (e) {
      debugPrint('SemanticSearchService: Unexpected error: $e');
      return _getFallbackMessages(conversationId);
    }
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
