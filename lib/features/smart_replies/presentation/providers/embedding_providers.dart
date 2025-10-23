import 'package:cloud_functions/cloud_functions.dart';
import 'package:message_ai/features/messaging/presentation/providers/messaging_providers.dart';
import 'package:message_ai/features/smart_replies/data/services/embedding_service.dart';
import 'package:message_ai/features/smart_replies/domain/services/embedding_generator.dart';
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
