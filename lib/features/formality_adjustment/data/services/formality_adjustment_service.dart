/// Formality adjustment service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/features/formality_adjustment/domain/entities/formality_level.dart';

/// Service for adjusting message formality using Cloud Functions
class FormalityAdjustmentService {
  FormalityAdjustmentService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Adjust the formality level of a message
  ///
  /// Returns the adjusted text or a Failure
  Future<Either<Failure, String>> adjustFormality({
    required String text,
    required FormalityLevel targetFormality,
    FormalityLevel? currentFormality,
    String? language,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        return const Left(
          ValidationFailure(message: 'Text cannot be empty'),
        );
      }

      final result = await _functions
          .httpsCallable('adjust_formality')
          .call<Map<String, dynamic>>({
            'text': text,
            'target_formality': targetFormality.value,
            'current_formality': currentFormality?.value ?? 'neutral',
            'language': language ?? 'en',
          });

      final data = result.data;

      // Check for rate limit
      final rateLimit = data['rateLimit'] as Map<String, dynamic>?;
      if (rateLimit != null) {
        final remaining = rateLimit['remaining'] as int?;
        if (remaining != null && remaining <= 0) {
          final resetSeconds = rateLimit['resetInSeconds'] as int? ?? 3600;
          return Left(
            RateLimitExceededFailure(
              retryAfter: DateTime.now().add(Duration(seconds: resetSeconds)),
            ),
          );
        }
      }

      // Extract adjusted text
      final adjustedText = data['adjustedText'] as String?;
      if (adjustedText == null || adjustedText.isEmpty) {
        return const Left(
          AIServiceFailure(message: 'Formality adjustment failed: empty response'),
        );
      }

      return Right(adjustedText);
    } on FirebaseFunctionsException catch (e) {
      // Handle specific error codes
      if (e.code == 'resource-exhausted') {
        return Left(
          RateLimitExceededFailure(
            retryAfter: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
      }

      return Left(
        AIServiceFailure(
          message: 'Formality adjustment failed: ${e.message ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      return Left(
        AIServiceFailure(
          message: 'Formality adjustment failed: $e',
        ),
      );
    }
  }
}
