/// Idiom explanation service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation.dart';

/// Service for explaining idioms and slang using Cloud Functions
class IdiomExplanationService {
  IdiomExplanationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Explain idioms, slang, and colloquialisms in a message
  ///
  /// Returns the explanation result or a Failure
  Future<Either<Failure, IdiomExplanationResult>> explainIdioms({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        return const Left(
          ValidationFailure(message: 'Text cannot be empty'),
        );
      }

      final result = await _functions
          .httpsCallable('explain_idioms')
          .call<Object?>({
        'text': text,
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      });

      // Cast the data to Map<String, dynamic>
      if (result.data == null) {
        return const Left(
          AIServiceFailure(message: 'No data returned from function'),
        );
      }

      final data = result.data! as Map<Object?, Object?>;
      final jsonData = Map<String, dynamic>.from(data);

      // Parse the response
      try {
        final explanationResult = IdiomExplanationResult.fromJson(jsonData);
        return Right(explanationResult);
      } catch (e) {
        return Left(
          AIServiceFailure(
            message: 'Failed to parse idiom explanations: $e',
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      return Left(
        AIServiceFailure(
          message: 'Idiom explanation failed: ${e.message ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      return Left(
        AIServiceFailure(
          message: 'Idiom explanation failed: $e',
        ),
      );
    }
  }
}
