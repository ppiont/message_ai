/// Smart reply providers
///
/// Simplified to use unified server-side RAG pipeline.
/// All embedding generation, vector search, and style analysis now happen
/// in the Cloud Function, reducing client complexity.
library;

import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/smart_replies/data/services/smart_reply_service.dart';
import 'package:message_ai/features/smart_replies/domain/entities/smart_reply.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_reply_providers.g.dart';

/// Provider for SmartReplyService
@riverpod
SmartReplyService smartReplyService(Ref ref) => SmartReplyService();

/// Provider for generating smart replies for a specific message
///
/// This simplified provider calls the unified Cloud Function that handles
/// the complete RAG pipeline server-side:
/// - Embedding generation with Vertex AI
/// - Vector search using Firestore find_nearest()
/// - User style fetching from Firestore
/// - Reply generation with GPT-4o-mini
///
/// Parameters:
/// - conversationId: The conversation context
/// - incomingMessageText: The message text to generate replies for
/// - userId: The current user's ID
@riverpod
Future<List<SmartReply>> generateSmartReplies(
  Ref ref, {
  required String conversationId,
  required String incomingMessageText,
  required String userId,
}) async {
  final service = ref.watch(smartReplyServiceProvider);

  final result = await service.generateSmartReplies(
    conversationId: conversationId,
    incomingMessageText: incomingMessageText,
    userId: userId,
  );

  // Convert Either to throw on failure (FutureProvider will catch it)
  return result.fold<List<SmartReply>>(
    (Failure failure) => throw Exception(failure.message),
    (List<SmartReply> replies) => replies,
  );
}
