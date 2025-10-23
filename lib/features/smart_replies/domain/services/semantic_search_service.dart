import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';

/// Service for performing semantic search on messages using cosine similarity.
///
/// This service enables RAG-based smart replies by finding the most semantically
/// relevant messages in a conversation history to provide context for reply generation.
///
/// Architecture:
/// - Domain layer service (pure business logic)
/// - Uses MessageRepository for data access
/// - Optimized for performance (<100ms for 50-100 messages)
/// - Offline-first (works with local Drift data)
///
/// Algorithm:
/// - Calculates cosine similarity between message embeddings
/// - Applies recency bias to prefer recent context
/// - Returns top N most relevant messages
class SemanticSearchService {
  SemanticSearchService({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  final MessageRepository _messageRepository;

  // Configuration
  static const int _defaultLimit = 10;
  static const int _searchPoolSize = 100; // Last N messages to search
  static const double _recencyBoost5min = 0.1;
  static const double _recencyBoost1hour = 0.05;

  /// Searches for the most relevant messages in a conversation for RAG context.
  ///
  /// This method finds messages semantically similar to the incoming message
  /// using cosine similarity on their vector embeddings. It applies a recency
  /// bias to prefer recent messages when similarity scores are close.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation to search within
  /// - [incomingMessage]: The message to find relevant context for
  /// - [limit]: Maximum number of results to return (default: 10)
  ///
  /// Returns: List of most relevant messages, sorted by relevance (descending)
  ///
  /// Edge cases:
  /// - If incoming message has no embedding: Returns most recent messages
  /// - If no messages with embeddings: Returns most recent messages
  /// - If empty conversation: Returns empty list
  /// - If fewer than limit messages: Returns all available
  Future<List<Message>> searchRelevantContext(
    String conversationId,
    Message incomingMessage, {
    int limit = _defaultLimit,
  }) async {
    try {
      debugPrint(
        'SemanticSearchService: Searching for relevant context in conversation $conversationId',
      );

      // Fetch recent messages from repository
      final messagesResult = await _messageRepository.getMessages(
        conversationId: conversationId,
        limit: _searchPoolSize,
      );

      // Handle repository errors
      final messages = messagesResult.fold<List<Message>>((failure) {
        debugPrint('SemanticSearchService: Failed to fetch messages: $failure');
        return <Message>[];
      }, (msgs) => msgs);

      // Edge case: Empty conversation
      if (messages.isEmpty) {
        debugPrint('SemanticSearchService: No messages in conversation');
        return [];
      }

      // Edge case: Incoming message has no embedding
      // Return most recent messages as fallback
      if (incomingMessage.embedding == null ||
          incomingMessage.embedding!.isEmpty) {
        debugPrint(
          'SemanticSearchService: Incoming message has no embedding, returning recent messages',
        );
        return _getMostRecentMessages(messages, limit);
      }

      // Filter to messages with embeddings (exclude incoming message itself)
      final messagesWithEmbeddings = messages
          .where(
            (msg) =>
                msg.id != incomingMessage.id &&
                msg.embedding != null &&
                msg.embedding!.isNotEmpty,
          )
          .toList();

      // Edge case: No messages with embeddings
      // Return most recent messages as fallback
      if (messagesWithEmbeddings.isEmpty) {
        debugPrint(
          'SemanticSearchService: No messages with embeddings, returning recent messages',
        );
        return _getMostRecentMessages(messages, limit);
      }

      // Calculate relevance scores for each message
      final scoredMessages = messagesWithEmbeddings.map((msg) {
        final similarity = _cosineSimilarity(
          incomingMessage.embedding!,
          msg.embedding!,
        );
        final recencyBoost = _calculateRecencyBoost(msg.timestamp);
        final finalScore = similarity + recencyBoost;

        return _ScoredMessage(
          message: msg,
          similarityScore: similarity,
          recencyBoost: recencyBoost,
          finalScore: finalScore,
        );
      }).toList();

      // Sort by final score (descending) and take top N results
      final topResults =
          (scoredMessages..sort((a, b) => b.finalScore.compareTo(a.finalScore)))
              .take(limit)
              .toList();

      debugPrint(
        'SemanticSearchService: Found ${topResults.length} relevant messages (from ${messagesWithEmbeddings.length} candidates)',
      );

      if (kDebugMode && topResults.isNotEmpty) {
        debugPrint(
          'SemanticSearchService: Top result - similarity: ${topResults.first.similarityScore.toStringAsFixed(3)}, '
          'recency boost: ${topResults.first.recencyBoost.toStringAsFixed(3)}, '
          'final: ${topResults.first.finalScore.toStringAsFixed(3)}',
        );
      }

      // Return just the messages (without scores)
      return topResults.map((scored) => scored.message).toList();
    } catch (e) {
      debugPrint('SemanticSearchService: Unexpected error during search: $e');
      return [];
    }
  }

  /// Calculates cosine similarity between two vectors.
  ///
  /// Cosine similarity measures the cosine of the angle between two vectors,
  /// providing a measure of semantic similarity between 0.0 and 1.0.
  ///
  /// Formula: dot_product(a, b) / (norm(a) * norm(b))
  ///
  /// Optimizations:
  /// - Single-pass calculation (computes dot product and norms simultaneously)
  /// - Minimal allocations
  /// - Early exit for edge cases
  ///
  /// Parameters:
  /// - [a]: First embedding vector
  /// - [b]: Second embedding vector
  ///
  /// Returns: Similarity score from 0.0 (completely different) to 1.0 (identical)
  ///
  /// Edge cases:
  /// - Different lengths: Returns 0.0
  /// - Zero vectors: Returns 0.0
  double _cosineSimilarity(List<double> a, List<double> b) {
    // Edge case: Different vector lengths
    if (a.length != b.length) {
      debugPrint(
        'SemanticSearchService: Vector length mismatch (${a.length} vs ${b.length})',
      );
      return 0;
    }

    // Single-pass calculation for efficiency
    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    // Edge case: Zero vectors
    if (normA == 0 || normB == 0) {
      debugPrint('SemanticSearchService: Zero vector detected');
      return 0;
    }

    // Calculate final similarity
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Calculates recency boost for a message based on its age.
  ///
  /// Recency bias strategy:
  /// - Last 5 minutes: +0.1 boost
  /// - Last hour: +0.05 boost
  /// - Older: no boost
  ///
  /// This ensures recent context is preferred when similarity scores are close,
  /// which is crucial for maintaining conversation coherence.
  ///
  /// Parameters:
  /// - [messageTime]: Timestamp of the message
  ///
  /// Returns: Boost value to add to similarity score
  double _calculateRecencyBoost(DateTime messageTime) {
    final age = DateTime.now().difference(messageTime);

    if (age.inMinutes < 5) {
      return _recencyBoost5min;
    }

    if (age.inHours < 1) {
      return _recencyBoost1hour;
    }

    return 0;
  }

  /// Returns the most recent messages from a list.
  ///
  /// This is used as a fallback when semantic search cannot be performed
  /// (e.g., no embeddings available).
  ///
  /// Parameters:
  /// - [messages]: List of messages to filter
  /// - [limit]: Maximum number of messages to return
  ///
  /// Returns: Up to [limit] most recent messages, sorted newest first
  List<Message> _getMostRecentMessages(List<Message> messages, int limit) {
    // Sort by timestamp (descending)
    final sorted = messages.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Take up to limit
    return sorted.take(limit).toList();
  }
}

/// Internal class for storing message with relevance scores.
///
/// Used during the search process to track both similarity and recency
/// components before final ranking.
class _ScoredMessage {
  _ScoredMessage({
    required this.message,
    required this.similarityScore,
    required this.recencyBoost,
    required this.finalScore,
  });

  final Message message;
  final double similarityScore;
  final double recencyBoost;
  final double finalScore;
}
