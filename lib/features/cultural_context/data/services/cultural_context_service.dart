/// Cultural context analysis service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';

/// Service for analyzing cultural context using Cloud Functions
class CulturalContextService {
  CulturalContextService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Analyze cultural context of a message
  ///
  /// Returns the cultural hint or null if no cultural context needed
  /// Runs in fire-and-forget mode for background analysis
  Future<Either<Failure, String?>> analyzeCulturalContext({
    required String text,
    required String language,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        return const Left(
          ValidationFailure(message: 'Text cannot be empty'),
        );
      }

      final result = await _functions
          .httpsCallable('analyze_cultural_context')
          .call<Map<String, dynamic>>({
            'text': text,
            'language': language,
          });

      final data = result.data;

      // Extract cultural hint (may be null)
      final culturalHint = data['culturalHint'] as String?;

      return Right(culturalHint);
    } on FirebaseFunctionsException catch (e) {
      return Left(
        AIServiceFailure(
          message: 'Cultural context analysis failed: ${e.message ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      return Left(
        AIServiceFailure(
          message: 'Cultural context analysis failed: $e',
        ),
      );
    }
  }
}
