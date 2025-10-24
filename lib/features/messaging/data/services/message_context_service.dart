/// Message context analysis service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/core/utils/pii_detector.dart';
import 'package:message_ai/features/messaging/domain/entities/idiom_explanation.dart';
import 'package:message_ai/features/messaging/domain/entities/message_context_details.dart';

/// Service for analyzing message cultural context, formality, and idioms using Cloud Functions
///
/// This unified service replaces both CulturalContextService and IdiomExplanationService,
/// providing comprehensive message analysis in a single API call.
///
/// Enhanced with:
/// - PII detection and sanitization before analysis
/// - Retry logic (3 attempts with exponential backoff)
/// - Improved error handling with specific failure types
/// - Comprehensive debug logging
/// - JSON response parsing and validation
class MessageContextService {
  MessageContextService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Maximum retry attempts
  static const int _maxRetries = 3;

  /// Analyze message context (cultural nuances, formality, idioms)
  ///
  /// Returns MessageContextDetails with comprehensive analysis or a Failure
  ///
  /// Features:
  /// - PII detection and sanitization
  /// - Retry logic with exponential backoff
  /// - Cloud Function caching (30-day TTL)
  /// - Detailed logging of PII detection and API calls
  /// - JSON response validation
  Future<Either<Failure, MessageContextDetails?>> analyzeMessageContext({
    required String text,
    required String language,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        debugPrint('MessageContextService: Empty text provided');
        return const Left(
          ValidationFailure(message: 'Text cannot be empty'),
        );
      }

      // Detect and sanitize PII before sending to cloud function
      final piiResult = PIIDetector.detectAndSanitize(text);

      if (piiResult.containsPII) {
        debugPrint('MessageContextService: Detected PII - types: ${piiResult.detectedTypes}');
        debugPrint('MessageContextService: Original text length: ${text.length}, Sanitized: ${piiResult.sanitizedText.length}');
      }

      // Use sanitized text for analysis
      final textToAnalyze = piiResult.sanitizedText;

      // Retry logic with exponential backoff
      var attempt = 0;
      Exception? lastException;

      while (attempt < _maxRetries) {
        try {
          debugPrint('MessageContextService: Attempt ${attempt + 1}/$_maxRetries - Analyzing text (lang: $language)');

          final result = await _functions
              .httpsCallable('analyze_message_context')
              .call<Map<String, dynamic>>({
                'text': textToAnalyze,
                'language': language,
              });

          final data = result.data;

          // Extract fields
          final culturalHint = data['culturalHint'] as String?;
          final formality = data['formality'] as String?;
          final culturalNote = data['culturalNote'] as String?;
          final idiomsJson = data['idioms'] as List<dynamic>? ?? <dynamic>[];

          // Parse idioms
          final idiomsList = idiomsJson
              .map<IdiomExplanation?>((final Object? idiom) {
                if (idiom is Map<Object?, Object?>) {
                  final idiomMap = Map<String, dynamic>.from(idiom);
                  return IdiomExplanation.fromJson(idiomMap);
                }
                return null;
              })
              .whereType<IdiomExplanation>()
              .toList();

          // Create MessageContextDetails if any content found
          MessageContextDetails? contextDetails;
          if (culturalHint != null || formality != null || culturalNote != null || idiomsList.isNotEmpty) {
            contextDetails = MessageContextDetails(
              formality: formality,
              culturalNote: culturalNote,
              idioms: idiomsList,
            );

            debugPrint('MessageContextService: Analysis successful - '
                'formality=${formality ?? "null"}, '
                'idioms=${idiomsList.length}, '
                'culturalNote=${culturalNote != null ? "present" : "null"}');
          } else {
            debugPrint('MessageContextService: Analysis successful - no context needed');
          }

          return Right(contextDetails);
        } on FirebaseFunctionsException catch (e) {
          lastException = e;
          debugPrint('MessageContextService: Firebase Functions error (attempt ${attempt + 1}): ${e.code} - ${e.message}');

          // Handle specific error codes
          if (e.code == 'resource-exhausted') {
            debugPrint('MessageContextService: Rate limit exceeded (non-retryable)');
            return Left(
              RateLimitExceededFailure(
                retryAfter: DateTime.now().add(const Duration(hours: 1)),
              ),
            );
          }

          // Don't retry on specific error codes
          if (e.code == 'unauthenticated' ||
              e.code == 'permission-denied' ||
              e.code == 'invalid-argument') {
            debugPrint('MessageContextService: Non-retryable error, failing immediately');
            return Left(
              AIServiceFailure(
                message: 'Message context analysis failed: ${e.message ?? "Unknown error"}',
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
            debugPrint('MessageContextService: Retrying after ${backoffDuration.inSeconds}s backoff...');
            await Future<void>.delayed(backoffDuration);
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint('MessageContextService: Unexpected error (attempt ${attempt + 1}): $e');

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
      debugPrint('MessageContextService: All $attempt retry attempts exhausted');
      return Left(
        AIServiceFailure(
          message: 'Message context analysis failed after $_maxRetries attempts: ${lastException?.toString() ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      debugPrint('MessageContextService: Fatal error: $e');
      return Left(
        AIServiceFailure(
          message: 'Message context analysis failed: $e',
        ),
      );
    }
  }
}
