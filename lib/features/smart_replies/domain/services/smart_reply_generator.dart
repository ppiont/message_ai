import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/smart_replies/data/services/embedding_service.dart';
import 'package:message_ai/features/smart_replies/data/services/smart_reply_service.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';
import 'package:message_ai/features/smart_replies/domain/services/semantic_search_service.dart';
import 'package:message_ai/features/smart_replies/domain/services/user_style_analyzer.dart';

/// Domain service that orchestrates the complete RAG pipeline for smart replies.
///
/// This service coordinates all the components needed to generate contextually
/// relevant, style-matched reply suggestions:
///
/// 1. Generate embedding for incoming message (if not already present)
/// 2. Perform semantic search for relevant context
/// 3. Analyze user's communication style
/// 4. Generate smart replies using GPT-4o-mini
///
/// Architecture:
/// - Domain layer service (orchestration logic)
/// - Uses multiple services via dependency injection
/// - Returns `Either<Failure, List<SmartReply>>` for error handling
/// - Fire-and-forget embedding generation (doesn't block on errors)
///
/// Performance: Target <3 seconds total (embedding + search + generation)
class SmartReplyGenerator {
  SmartReplyGenerator({
    required EmbeddingService embeddingService,
    required SemanticSearchService semanticSearchService,
    required UserStyleAnalyzer userStyleAnalyzer,
    required SmartReplyService smartReplyService,
  }) : _embeddingService = embeddingService,
       _semanticSearchService = semanticSearchService,
       _userStyleAnalyzer = userStyleAnalyzer,
       _smartReplyService = smartReplyService;

  final EmbeddingService _embeddingService;
  final SemanticSearchService _semanticSearchService;
  final UserStyleAnalyzer _userStyleAnalyzer;
  final SmartReplyService _smartReplyService;

  /// Generates smart reply suggestions for an incoming message.
  ///
  /// This method orchestrates the complete RAG pipeline:
  /// 1. Ensures incoming message has an embedding
  /// 2. Finds semantically relevant context messages
  /// 3. Analyzes the user's communication style
  /// 4. Generates reply suggestions via Cloud Function
  ///
  /// Parameters:
  /// - [conversationId]: The conversation context
  /// - [incomingMessage]: The message to generate replies for
  /// - [currentUserId]: The user who will be replying (for style analysis)
  ///
  /// Returns:
  /// - `Right(List<SmartReply>)`: 3 reply suggestions on success
  /// - `Left(Failure)`: Error details on failure
  ///
  /// Edge cases:
  /// - If embedding generation fails: Returns failure (required for semantic search)
  /// - If semantic search fails: Uses empty context (degraded mode)
  /// - If style analysis fails: Uses default style (degraded mode)
  /// - If smart reply generation fails: Returns failure
  Future<Either<Failure, List<SmartReply>>> generateReplies({
    required String conversationId,
    required Message incomingMessage,
    required String currentUserId,
  }) async {
    try {
      debugPrint(
        'SmartReplyGenerator: Starting RAG pipeline for message in conversation $conversationId',
      );

      final startTime = DateTime.now();

      // Step 1: Ensure incoming message has an embedding
      var messageWithEmbedding = incomingMessage;

      if (incomingMessage.embedding == null ||
          incomingMessage.embedding!.isEmpty) {
        debugPrint(
          'SmartReplyGenerator: Generating embedding for incoming message',
        );

        final embeddingResult = await _embeddingService.generateEmbedding(
          incomingMessage.text,
        );

        // If embedding fails, we can't proceed (needed for semantic search)
        final embedding = embeddingResult.fold<List<double>?>((failure) {
          debugPrint(
            'SmartReplyGenerator: Failed to generate embedding: $failure',
          );
          return null;
        }, (emb) => emb);

        if (embedding == null) {
          return Left(
            embeddingResult.fold(
              (failure) => failure,
              (_) => const ServerFailure(
                message: 'Failed to generate embedding for incoming message',
              ),
            ),
          );
        }

        messageWithEmbedding = incomingMessage.copyWith(embedding: embedding);
      }

      // Step 2: Perform semantic search for relevant context
      debugPrint('SmartReplyGenerator: Performing semantic search');
      final relevantContext = await _semanticSearchService
          .searchRelevantContext(conversationId, messageWithEmbedding);

      debugPrint(
        'SmartReplyGenerator: Found ${relevantContext.length} relevant context messages',
      );

      // Step 3: Analyze user's communication style
      debugPrint('SmartReplyGenerator: Analyzing user communication style');
      final userStyle = await _userStyleAnalyzer.analyzeUserStyle(
        currentUserId,
        conversationId,
      );

      debugPrint(
        'SmartReplyGenerator: User style: ${userStyle.styleDescription}',
      );

      // Step 4: Generate smart replies via Cloud Function
      debugPrint('SmartReplyGenerator: Calling smart reply generation');
      final repliesResult = await _smartReplyService.generateSmartReplies(
        conversationId: conversationId,
        incomingMessage: messageWithEmbedding,
        userStyle: userStyle,
        relevantContext: relevantContext,
      );

      final elapsedMs = DateTime.now().difference(startTime).inMilliseconds;

      return repliesResult.fold<Either<Failure, List<SmartReply>>>(
        (failure) {
          debugPrint(
            'SmartReplyGenerator: Failed to generate replies: $failure (${elapsedMs}ms)',
          );
          return Left(failure);
        },
        (replies) {
          debugPrint(
            'SmartReplyGenerator: Successfully generated ${replies.length} smart replies (${elapsedMs}ms)',
          );
          return Right(replies);
        },
      );
    } catch (e) {
      debugPrint('SmartReplyGenerator: Unexpected error: $e');
      return Left(
        ServerFailure(message: 'Failed to generate smart replies: $e'),
      );
    }
  }
}
