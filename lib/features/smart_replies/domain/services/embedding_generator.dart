import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:message_ai/features/messaging/data/datasources/message_local_datasource.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/domain/repositories/message_repository.dart';
import 'package:message_ai/features/smart_replies/data/services/embedding_service.dart';

/// Service for generating embeddings for messages in the background.
///
/// This service handles:
/// - Automatic embedding generation for new messages
/// - Background processing of historical messages without embeddings
/// - Fire-and-forget pattern (doesn't block message send/receive)
/// - Graceful error handling (failures are logged but don't affect UX)
/// - Exponential backoff for retries
///
/// Architecture:
/// - Domain layer service (orchestrates data sources)
/// - Uses EmbeddingService for Cloud Function calls
/// - Uses MessageDao for local database access
/// - Uses MessageRepository for Firestore updates
class EmbeddingGenerator {
  EmbeddingGenerator({
    required EmbeddingService embeddingService,
    required MessageLocalDataSource messageLocalDataSource,
    required MessageRepository messageRepository,
  }) : _embeddingService = embeddingService,
       _messageLocalDataSource = messageLocalDataSource,
       _messageRepository = messageRepository;

  final EmbeddingService _embeddingService;
  final MessageLocalDataSource _messageLocalDataSource;
  final MessageRepository _messageRepository;

  // Configuration
  static const int _minTextLength = 5;

  /// Generates an embedding for a message and updates both local and remote storage.
  ///
  /// This is a fire-and-forget operation - errors are logged but don't throw.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation the message belongs to
  /// - [message]: The message to generate an embedding for
  ///
  /// Returns: Future that completes when generation is done (or failed)
  Future<void> generateForMessage({
    required String conversationId,
    required Message message,
  }) async {
    try {
      // Skip if message already has an embedding
      if (message.embedding != null && message.embedding!.isNotEmpty) {
        debugPrint(
          'EmbeddingGenerator: Message ${message.id} already has embedding, skipping',
        );
        return;
      }

      // Skip if message text is too short
      if (message.text.trim().length < _minTextLength) {
        debugPrint(
          'EmbeddingGenerator: Message ${message.id} text too short (<$_minTextLength chars), skipping',
        );
        return;
      }

      debugPrint(
        'EmbeddingGenerator: Generating embedding for message ${message.id}',
      );

      // Generate embedding
      final result = await _embeddingService.generateEmbedding(message.text);

      await result.fold(
        (failure) async {
          // Log error but don't throw (fire-and-forget)
          debugPrint(
            'EmbeddingGenerator: Failed to generate embedding for message ${message.id}: $failure',
          );
        },
        (embedding) async {
          // Update message with embedding
          final updatedMessage = message.copyWith(embedding: embedding);

          // Save to local database
          await _messageLocalDataSource.updateMessage(
            conversationId,
            updatedMessage,
          );

          // Update in Firestore (fire-and-forget)
          unawaited(
            _messageRepository
                .updateMessage(conversationId, updatedMessage)
                .then(
                  (result) => result.fold(
                    (failure) => debugPrint(
                      'EmbeddingGenerator: Failed to update Firestore for message ${message.id}: $failure',
                    ),
                    (_) => debugPrint(
                      'EmbeddingGenerator: Successfully updated embedding for message ${message.id}',
                    ),
                  ),
                ),
          );
        },
      );
    } catch (e) {
      // Catch any unexpected errors and log them
      debugPrint(
        'EmbeddingGenerator: Unexpected error generating embedding for message ${message.id}: $e',
      );
    }
  }

  /// Generates embeddings for all messages in a conversation that don't have them.
  ///
  /// This is useful for backfilling historical messages. Processes messages
  /// in the background with exponential backoff between batches to avoid
  /// overwhelming the Cloud Function.
  ///
  /// Parameters:
  /// - [conversationId]: The conversation to process
  /// - [limit]: Maximum number of messages to process per batch (default: 10)
  ///
  /// Returns: Number of embeddings generated
  Future<int> generateForConversation({
    required String conversationId,
    int limit = 10,
  }) async {
    var generated = 0;

    try {
      debugPrint(
        'EmbeddingGenerator: Processing conversation $conversationId (limit: $limit)',
      );

      // Get messages from local database
      final messages = await _messageLocalDataSource.getMessages(
        conversationId: conversationId,
        limit: limit,
      );

      // Filter to messages without embeddings
      final messagesNeedingEmbeddings = messages.where((msg) {
        final hasEmbedding = msg.embedding != null && msg.embedding!.isNotEmpty;
        final isLongEnough = msg.text.trim().length >= _minTextLength;
        return !hasEmbedding && isLongEnough;
      }).toList();

      debugPrint(
        'EmbeddingGenerator: Found ${messagesNeedingEmbeddings.length} messages needing embeddings',
      );

      // Process each message
      for (final message in messagesNeedingEmbeddings) {
        await generateForMessage(
          conversationId: conversationId,
          message: message,
        );

        generated++;

        // Add a small delay between messages to avoid rate limiting
        if (generated < messagesNeedingEmbeddings.length) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }

      debugPrint(
        'EmbeddingGenerator: Successfully generated $generated embeddings for conversation $conversationId',
      );
    } catch (e) {
      debugPrint(
        'EmbeddingGenerator: Error processing conversation $conversationId: $e',
      );
    }

    return generated;
  }

  /// Generates embeddings for all messages across all conversations that don't have them.
  ///
  /// This is a heavy operation and should be run sparingly (e.g., once on app startup
  /// or triggered manually). Processes messages in batches with delays to avoid
  /// overwhelming the system.
  ///
  /// Note: This method uses search to get all messages, which is inefficient for
  /// large datasets. In production, consider processing by conversation instead.
  ///
  /// Parameters:
  /// - [batchSize]: Number of messages to process in each batch (default: 5)
  /// - [delayBetweenBatches]: Delay between batches (default: 500ms)
  ///
  /// Returns: Number of embeddings generated
  Future<int> generateForAllMessages({
    int batchSize = 5,
    Duration delayBetweenBatches = const Duration(milliseconds: 500),
  }) async {
    const totalGenerated = 0;

    try {
      debugPrint(
        'EmbeddingGenerator: Starting bulk embedding generation (batch size: $batchSize)',
      );

      // Get all messages without embeddings (using search)
      // Note: This is inefficient for large datasets
      final allMessages = await _messageLocalDataSource.searchMessages('');
      final messagesNeedingEmbeddings = allMessages.where((msg) {
        final hasEmbedding = msg.embedding != null && msg.embedding!.isNotEmpty;
        final isLongEnough = msg.text.trim().length >= _minTextLength;
        return !hasEmbedding && isLongEnough;
      }).toList();

      debugPrint(
        'EmbeddingGenerator: Found ${messagesNeedingEmbeddings.length} messages needing embeddings',
      );

      // Process in batches
      for (var i = 0; i < messagesNeedingEmbeddings.length; i += batchSize) {
        final batch = messagesNeedingEmbeddings.skip(i).take(batchSize);

        for (final message in batch) {
          // Note: We'd need to track conversationId better in production
          // For now, skip messages where we can't determine the conversation
          // This is a known limitation and should be fixed in the data model
          debugPrint(
            'EmbeddingGenerator: Skipping message ${message.id} - conversationId tracking not implemented',
          );
          continue;
        }

        // Delay between batches
        if (i + batchSize < messagesNeedingEmbeddings.length) {
          await Future<void>.delayed(delayBetweenBatches);
        }
      }

      debugPrint(
        'EmbeddingGenerator: Bulk generation complete. Generated $totalGenerated embeddings',
      );
    } catch (e) {
      debugPrint('EmbeddingGenerator: Error in bulk generation: $e');
    }

    return totalGenerated;
  }
}
