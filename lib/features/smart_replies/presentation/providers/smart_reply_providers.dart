/// Smart reply providers
library;

import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/messaging/domain/entities/message.dart';
import 'package:message_ai/features/smart_replies/data/services/smart_reply_service.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';
import 'package:message_ai/features/smart_replies/domain/services/smart_reply_generator.dart';
import 'package:message_ai/features/smart_replies/presentation/providers/embedding_providers.dart';
import 'package:message_ai/features/smart_replies/presentation/providers/style_analyzer_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_reply_providers.g.dart';

/// Provider for SmartReplyService
@riverpod
SmartReplyService smartReplyService(Ref ref) => SmartReplyService();

/// Provider for SmartReplyGenerator
@riverpod
SmartReplyGenerator smartReplyGenerator(Ref ref) => SmartReplyGenerator(
  embeddingService: ref.watch(embeddingServiceProvider),
  semanticSearchService: ref.watch(semanticSearchServiceProvider),
  userStyleAnalyzer: ref.watch(userStyleAnalyzerProvider),
  smartReplyService: ref.watch(smartReplyServiceProvider),
);

/// Provider for generating smart replies for a specific message
///
/// This is a FutureProvider that orchestrates the complete RAG pipeline:
/// - Embedding generation
/// - Semantic search
/// - Style analysis
/// - Reply generation
///
/// Parameters (via family):
/// - conversationId: The conversation context
/// - incomingMessage: The message to generate replies for
/// - currentUserId: The user who will be replying
@riverpod
Future<List<SmartReply>> generateSmartReplies(
  Ref ref, {
  required String conversationId,
  required Message incomingMessage,
  required String currentUserId,
}) async {
  final generator = ref.watch(smartReplyGeneratorProvider);

  final result = await generator.generateReplies(
    conversationId: conversationId,
    incomingMessage: incomingMessage,
    currentUserId: currentUserId,
  );

  // Convert Either to throw on failure (FutureProvider will catch it)
  return result.fold<List<SmartReply>>(
    (Failure failure) => throw Exception(failure.message),
    (List<SmartReply> replies) => replies,
  );
}
