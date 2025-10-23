/// Cultural context analysis service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/core/utils/pii_detector.dart';

/// Service for analyzing cultural context using Cloud Functions
///
/// Enhanced with:
/// - PII detection and sanitization before analysis
/// - Retry logic (3 attempts with exponential backoff)
/// - Improved error handling with specific failure types
/// - Comprehensive debug logging
class CulturalContextService {
  CulturalContextService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Maximum retry attempts
  static const int _maxRetries = 3;

  /// Analyze cultural context of a message
  ///
  /// Returns the cultural hint or null if no cultural context needed
  ///
  /// Features:
  /// - PII detection and sanitization
  /// - Retry logic with exponential backoff
  /// - Detailed logging of PII detection and API calls
  Future<Either<Failure, String?>> analyzeCulturalContext({
    required String text,
    required String language,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        debugPrint('CulturalContextService: Empty text provided');
        return const Left(
          ValidationFailure(message: 'Text cannot be empty'),
        );
      }

      // Detect and sanitize PII before sending to cloud function
      final piiResult = PIIDetector.detectAndSanitize(text);

      if (piiResult.containsPII) {
        debugPrint('CulturalContextService: Detected PII - types: ${piiResult.detectedTypes}');
        debugPrint('CulturalContextService: Original text length: ${text.length}, Sanitized: ${piiResult.sanitizedText.length}');
      }

      // Use sanitized text for analysis
      final textToAnalyze = piiResult.sanitizedText;

      // Retry logic with exponential backoff
      var attempt = 0;
      Exception? lastException;

      while (attempt < _maxRetries) {
        try {
          debugPrint('CulturalContextService: Attempt ${attempt + 1}/$_maxRetries - Analyzing text (lang: $language)');

          final result = await _functions
              .httpsCallable('analyze_cultural_context')
              .call<Map<String, dynamic>>({
                'text': textToAnalyze,
                'language': language,
              });

          final data = result.data;

          // Extract cultural hint (may be null)
          final culturalHint = data['culturalHint'] as String?;

          debugPrint('CulturalContextService: Analysis successful - ${culturalHint != null ? 'hint found' : 'no hint needed'}');

          return Right(culturalHint);
        } on FirebaseFunctionsException catch (e) {
          lastException = e;
          debugPrint('CulturalContextService: Firebase Functions error (attempt ${attempt + 1}): ${e.code} - ${e.message}');

          // Don't retry on specific error codes
          if (e.code == 'unauthenticated' ||
              e.code == 'permission-denied' ||
              e.code == 'invalid-argument') {
            debugPrint('CulturalContextService: Non-retryable error, failing immediately');
            return Left(
              AIServiceFailure(
                message: 'Cultural context analysis failed: ${e.message ?? "Unknown error"}',
                code: e.code,
              ),
            );
          }

          // Retry with exponential backoff
          attempt++;
          if (attempt < _maxRetries) {
            final backoffDuration = Duration(
              milliseconds: 1000 * (1 << (attempt - 1)), // 1s, 2s, 4s
            );
            debugPrint('CulturalContextService: Retrying after ${backoffDuration.inSeconds}s backoff...');
            await Future<void>.delayed(backoffDuration);
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint('CulturalContextService: Unexpected error (attempt ${attempt + 1}): $e');

          attempt++;
          if (attempt < _maxRetries) {
            final backoffDuration = Duration(
              milliseconds: 1000 * (1 << (attempt - 1)),
            );
            await Future<void>.delayed(backoffDuration);
          }
        }
      }

      // All retries exhausted
      debugPrint('CulturalContextService: All $attempt retry attempts exhausted');
      return Left(
        AIServiceFailure(
          message: 'Cultural context analysis failed after $_maxRetries attempts: ${lastException?.toString() ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      debugPrint('CulturalContextService: Fatal error: $e');
      return Left(
        AIServiceFailure(
          message: 'Cultural context analysis failed: $e',
        ),
      );
    }
  }
}
