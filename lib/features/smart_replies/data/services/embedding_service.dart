import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';

/// Service for generating text embeddings using OpenAI's text-embedding-3-small model.
///
/// This service calls the Firebase Cloud Function to generate 1536-dimensional
/// embedding vectors for text. Embeddings are used for semantic search in the
/// Smart Replies RAG pipeline.
///
/// Architecture:
/// - Data layer service (handles Cloud Function communication)
/// - Returns `Either<Failure, List<double>>` for error handling
/// - Caching handled by Cloud Function (not local)
///
/// Cost: ~$0.02 per 1M tokens (very cheap)
class EmbeddingService {
  EmbeddingService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Generates an embedding vector for the given text.
  ///
  /// Returns a 1536-dimensional vector or a Failure if generation fails.
  ///
  /// Parameters:
  /// - [text]: The text to embed (must be at least 5 characters)
  ///
  /// Returns:
  /// - `Right(List<double>)`: The embedding vector on success
  /// - `Left(Failure)`: Error details on failure
  Future<Either<Failure, List<double>>> generateEmbedding(String text) async {
    try {
      // Validate input
      if (text.trim().length < 5) {
        return const Left(
          ValidationFailure(
            message:
                'Text must be at least 5 characters long for meaningful embeddings',
          ),
        );
      }

      debugPrint(
        'EmbeddingService: Generating embedding for text: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."',
      );

      // Call Cloud Function
      final result = await _functions
          .httpsCallable('generate_embedding')
          .call<Map<String, dynamic>>({'text': text});

      // Extract embedding from response
      final data = result.data;
      final embeddingList = data['embedding'] as List<dynamic>;
      final embedding = embeddingList
          .map((dynamic e) => (e as num).toDouble())
          .toList();

      final cached = data['cached'] as bool? ?? false;
      final tokenCount = data['tokenCount'] as int? ?? 0;

      debugPrint(
        'EmbeddingService: Generated ${embedding.length}D embedding '
        '(${cached ? "cached" : "new"}, $tokenCount tokens)',
      );

      return Right(embedding);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        'EmbeddingService: Cloud Function error: ${e.code} - ${e.message}',
      );

      // Map Firebase Functions errors to appropriate Failures
      switch (e.code) {
        case 'invalid-argument':
          return Left(
            ValidationFailure(message: e.message ?? 'Invalid argument'),
          );
        case 'unauthenticated':
          return Left(
            ServerFailure(message: 'User not authenticated: ${e.message}'),
          );
        case 'resource-exhausted':
          return Left(
            ServerFailure(message: e.message ?? 'Rate limit exceeded'),
          );
        default:
          return Left(
            ServerFailure(
              message: e.message ?? 'Failed to generate embedding: ${e.code}',
            ),
          );
      }
    } catch (e) {
      debugPrint('EmbeddingService: Unexpected error: $e');
      return Left(ServerFailure(message: 'Failed to generate embedding: $e'));
    }
  }

  /// Batch generates embeddings for multiple texts.
  ///
  /// This method calls the Cloud Function for each text individually.
  /// The Cloud Function handles caching, so duplicate texts won't incur
  /// additional API costs.
  ///
  /// Parameters:
  /// - [texts]: List of texts to embed
  ///
  /// Returns:
  /// - `Right(List<List<double>>)`: All embeddings on success
  /// - `Left(Failure)`: Error if any embedding fails
  Future<Either<Failure, List<List<double>>>> generateEmbeddingsBatch(
    List<String> texts,
  ) async {
    final embeddings = <List<double>>[];

    for (final text in texts) {
      final result = await generateEmbedding(text);

      // If any embedding fails, return the failure
      final failure = result.fold<Failure?>((failure) => failure, (_) => null);

      if (failure != null) {
        return Left(failure);
      }

      // Add successful embedding
      result.fold<void>(
        (_) {}, // Already handled above
        embeddings.add,
      );
    }

    return Right(embeddings);
  }
}
