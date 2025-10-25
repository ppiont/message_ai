import 'package:cloud_functions/cloud_functions.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/smart_replies/data/services/embedding_service.dart';
import 'package:message_ai/features/smart_replies/domain/services/embedding_generator.dart';
import 'package:message_ai/features/smart_replies/domain/services/semantic_search_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'embedding_providers.g.dart';

/// Provider for EmbeddingService (data layer).
///
/// This service handles communication with the Cloud Function to generate embeddings.
@riverpod
EmbeddingService embeddingService(Ref ref) =>
    EmbeddingService(functions: FirebaseFunctions.instance);

/// Provider for EmbeddingGenerator (domain layer).
///
/// This service orchestrates embedding generation for messages, handling both
/// real-time generation for new messages and background processing for historical messages.
@riverpod
EmbeddingGenerator embeddingGenerator(Ref ref) => EmbeddingGenerator(
  embeddingService: ref.watch(embeddingServiceProvider),
  messageLocalDataSource: ref.watch(messageLocalDataSourceProvider),
  messageRepository: ref.watch(messageRepositoryProvider),
);

/// Provider for SemanticSearchService (domain layer).
///
/// This service performs semantic search using cosine similarity on message embeddings
/// to find the most relevant context for RAG-based smart replies.
@riverpod
SemanticSearchService semanticSearchService(Ref ref) => SemanticSearchService(
  messageRepository: ref.watch(messageRepositoryProvider),
);

/// FutureProvider for searching relevant context messages.
///
/// Performs semantic search to find the most relevant messages in a conversation
/// for providing context to smart reply generation.
///
/// Parameters:
/// - conversationId: The conversation to search within
/// - message: The incoming message to find context for
/// - limit: Maximum number of results (default: 10)
///
/// Returns: List of most relevant messages, sorted by relevance
@riverpod
Future<List<Message>> searchRelevantContext(
  Ref ref,
  String conversationId,
  Message message, {
  int limit = 10,
}) async {
  final searchService = ref.watch(semanticSearchServiceProvider);
  return searchService.searchRelevantContext(
    conversationId,
    message,
    limit: limit,
  );
}
