/// Idiom explanation service
library;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:message_ai/core/error/failures.dart';
import 'package:message_ai/core/utils/pii_detector.dart';
import 'package:message_ai/features/idiom_explanation/domain/entities/idiom_explanation.dart';

/// Response from idiom explanation cloud function
class _ExplanationResponse {
  const _ExplanationResponse({required this.idioms});

  /// Parse response from cloud function with type safety
  factory _ExplanationResponse.fromData(Map<String, dynamic> data) {
    final idiomsJson = data['idioms'] as List<dynamic>? ?? <dynamic>[];
    final idiomsList = idiomsJson
        .map<IdiomExplanation?>((final Object? idiom) {
          if (idiom is Map<Object?, Object?>) {
            final idiomMap = Map<String, dynamic>.from(idiom);
            return IdiomExplanation.fromJson(idiomMap);
          }
          // Skip invalid entries
          return null;
        })
        .whereType<IdiomExplanation>()
        .toList();

    return _ExplanationResponse(idioms: idiomsList);
  }

  final List<IdiomExplanation> idioms;
}

/// Cache entry for idiom explanations
class _CacheEntry {
  const _CacheEntry({required this.idioms, required this.timestamp});

  final List<IdiomExplanation> idioms;
  final DateTime timestamp;

  /// Check if cache entry is still valid (24-hour TTL)
  bool get isValid {
    final age = DateTime.now().difference(timestamp);
    return age.inHours < 24;
  }
}

/// Service for explaining idioms and slang using Cloud Functions
///
/// Enhanced with:
/// - PII detection and sanitization before analysis
/// - Retry logic (3 attempts with exponential backoff)
/// - In-memory caching with 24-hour TTL
/// - Improved error handling with specific failure types
/// - Comprehensive debug logging
/// - JSON response parsing and validation
class IdiomExplanationService {
  IdiomExplanationService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// In-memory cache for idiom explanations (Map with cacheKey and CacheEntry)
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  /// Maximum retry attempts
  static const int _maxRetries = 3;

  /// Explain idioms, slang, and colloquialisms in a message
  ///
  /// Returns the explanation result or a Failure
  ///
  /// Features:
  /// - PII detection and sanitization
  /// - Retry logic with exponential backoff
  /// - In-memory caching (24-hour TTL)
  /// - Detailed logging of PII detection and API calls
  /// - JSON response validation
  Future<Either<Failure, IdiomExplanationResult>> explainIdioms({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      // Validate input
      if (text.trim().isEmpty) {
        debugPrint('IdiomExplanationService: Empty text provided');
        return const Left(ValidationFailure(message: 'Text cannot be empty'));
      }

      // Detect and sanitize PII before sending to cloud function
      final piiResult = PIIDetector.detectAndSanitize(text);

      if (piiResult.containsPII) {
        final detectedTypesStr = piiResult.detectedTypes.join(', ');
        debugPrint(
          'IdiomExplanationService: Detected PII - types: $detectedTypesStr',
        );
        debugPrint(
          'IdiomExplanationService: Original text length: ${text.length}, Sanitized: ${piiResult.sanitizedText.length}',
        );
      }

      // Use sanitized text for explanation
      final textToAnalyze = piiResult.sanitizedText;

      // Check cache first
      final cacheKey = _buildCacheKey(
        text: textToAnalyze,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

      final cachedEntry = _cache[cacheKey];
      if (cachedEntry case _CacheEntry(:final idioms) when cachedEntry.isValid) {
        debugPrint('IdiomExplanationService: Cache HIT for explanation');
        return Right(IdiomExplanationResult(idioms: idioms));
      }

      // Cache miss - clean up expired entries
      _cleanExpiredCache();

      // Retry logic with exponential backoff
      var attempt = 0;
      Exception? lastException;

      while (attempt < _maxRetries) {
        try {
          debugPrint(
            'IdiomExplanationService: Attempt ${attempt + 1}/$_maxRetries - Explaining idioms (source: $sourceLanguage, target: $targetLanguage)',
          );

          final result = await _functions
              .httpsCallable('explain_idioms')
              .call<Map<Object?, Object?>>({
                'text': textToAnalyze,
                'source_language': sourceLanguage,
                'target_language': targetLanguage,
              });

          // Validate result data and cast the data to Map<String, dynamic>
          final jsonData = Map<String, dynamic>.from(result.data);

          // Parse and validate JSON response
          try {
            final response = _ExplanationResponse.fromData(jsonData);

            debugPrint(
              'IdiomExplanationService: Explanation successful - found ${response.idioms.length} idiom(s)',
            );

            // Cache the result
            _cache[cacheKey] = _CacheEntry(
              idioms: response.idioms,
              timestamp: DateTime.now(),
            );

            return Right(IdiomExplanationResult(idioms: response.idioms));
          } catch (e) {
            debugPrint('IdiomExplanationService: JSON parsing error: $e');
            return Left(
              AIServiceFailure(
                message: 'Failed to parse idiom explanations: $e',
              ),
            );
          }
        } on FirebaseFunctionsException catch (e) {
          lastException = e;
          debugPrint(
            'IdiomExplanationService: Firebase Functions error (attempt ${attempt + 1}): ${e.code} - ${e.message}',
          );

          // Handle specific error codes
          if (e.code == 'resource-exhausted') {
            debugPrint(
              'IdiomExplanationService: Rate limit exceeded (non-retryable)',
            );
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
            debugPrint(
              'IdiomExplanationService: Non-retryable error, failing immediately',
            );
            return Left(
              AIServiceFailure(
                message:
                    'Idiom explanation failed: ${e.message ?? "Unknown error"}',
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
            debugPrint(
              'IdiomExplanationService: Retrying after ${backoffDuration.inSeconds}s backoff...',
            );
            await Future<void>.delayed(backoffDuration);
          }
        } catch (e) {
          lastException = e is Exception ? e : Exception(e.toString());
          debugPrint(
            'IdiomExplanationService: Unexpected error (attempt ${attempt + 1}): $e',
          );

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
      debugPrint(
        'IdiomExplanationService: All $attempt retry attempts exhausted',
      );
      return Left(
        AIServiceFailure(
          message:
              'Idiom explanation failed after $_maxRetries attempts: ${lastException?.toString() ?? "Unknown error"}',
        ),
      );
    } catch (e) {
      debugPrint('IdiomExplanationService: Fatal error: $e');
      return Left(AIServiceFailure(message: 'Idiom explanation failed: $e'));
    }
  }

  /// Build cache key for idiom explanations
  String _buildCacheKey({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) =>
      // Use a simple concatenation with separators
      // Note: This is a basic cache key. For production, consider hashing
      '$text|$sourceLanguage|$targetLanguage';

  /// Clean up expired cache entries
  void _cleanExpiredCache() {
    final expiredKeys = <String>[
      for (final MapEntry<String, _CacheEntry>(:key, :value) in _cache.entries)
        if (!value.isValid) key,
    ];

    _cache.removeWhere((final String key, final _CacheEntry _) =>
        expiredKeys.contains(key));

    if (expiredKeys.isNotEmpty) {
      debugPrint(
        'IdiomExplanationService: Cleaned ${expiredKeys.length} expired cache entries',
      );
    }
  }

  /// Clear all cache entries (useful for testing or manual cache invalidation)
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    debugPrint('IdiomExplanationService: Cleared $count cache entries');
  }
}
